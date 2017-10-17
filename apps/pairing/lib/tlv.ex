# Happi is an implementation of Apple's HomeKit Accessory Protocol designed to run on
# Raspberry Pi and similar form factor devices.
# Copyright (C) 2017 Patrick Hughes pat@phughes.us

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License,

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

defmodule TLV do
  use Bitwise
  @moduledoc """
  TLV is an implementation of the TLV8 (type-length-value) format
  used in Apple's HomeKit Accessory Protocol Specification.

  TLV aims to provide a rount-trip-able path from data to TLV. 
  """

  @enforce_keys [:type, :value]
  defstruct [:type, :value]

  @doc """
  to_binary.
  Returns an encoded binary for a list of tlv structs.

  ## Examples

      iex> TLV.to_binary [%TLV{type: TLVType.state, value: 0}, %TLV{type: TLVType.state, value: 1025}]
      <<6, 1, 0, 6, 2, 4, 1>>

  """
  @spec to_binary([%TLV{}]) :: bitstring
  def to_binary(list) when is_list(list) do
    Enum.reduce(list, <<>>, &(&2 <> to_binary(&1)))
  end

  @doc """
  to_binary
  Returns an encoded binary for the tlv struct.

  ## Examples

      iex> TLV.to_binary %TLV{type: TLVType.state, value: 0}
      <<6, 1, 0>>

  """
  @spec to_binary(%TLV{}) :: bitstring  
  def to_binary(%TLV{type: t, value: v}) do
    value_to_binary(t, v)
    |> split_binary
    |> convert_to_tlv(t)
  end

  # Converts TLVErrors to binaries.
  defp value_to_binary(:error, value) when is_atom(value) do
    int_value = TLVError.integer_from_error(value)
    value_to_binary(TLVType.error, int_value)
  end

  # Converts TLVMethods to binaries.
  defp value_to_binary(:method, value) when is_atom(value) do
    int_value = TLVMethod.integer_from_method(value)
    value_to_binary(TLVType.error, int_value)
  end

  # Required for separators
  defp value_to_binary(:separator, nil) do
    value_to_binary(:separator, <<>>)
  end

  # Converts integers to binaries.
  defp value_to_binary(type, integer) when is_integer(integer) do
    has_digits = (integer >>> 8) > 0
    if has_digits do
      value_to_binary(type, integer >>> 8) <> <<integer::8>>
    else
      <<integer::8>>
    end
  end

  # Passthrough for easy piping.
  defp value_to_binary(_, binary) when is_binary(binary), do: binary

  # Catch unexpected values.
  defp value_to_binary(_, value) do
    raise "Unsupported value type: #{inspect value}"
  end

  # Splits binaries that are more than 255 binary into 
  # a list of 255 byte binaries.
  defp split_binary(binary) do
    binary
    |> Stream.unfold(&String.split_at(&1, 0xFF))
    |> Enum.take_while(&(&1 != <<>>))
  end

  # Builds a separator TLV.
  defp convert_to_tlv(_, :separator) do
    int_type = TLVType.integer_from_tlv(TLVType.separator)
    <<int_type>> <> <<0>>
  end
  
  # Converts a list of binaries into a single binary 
  # containing type and length info for each binary in the list.
  defp convert_to_tlv(binaries, type) do
    int_type = TLVType.integer_from_tlv(type)
    Enum.reduce(binaries, <<>>, &(&2 <> <<int_type>> <> <<byte_size(&1)>> <> &1))
  end

  @doc """
  to_struct.
  Returns a list of TLV structs for the given binary.

  ## Examples

      iex> TLV.to_struct <<6, 1, 0, 6, 2, 4, 1>>
      [%TLV{type: TLVType.state, value: 0}, %TLV{type: TLVType.state, value: 1025}]
  """
  def to_struct(binary) do
    # The binary may contain more than one TLV item.
    extract_fragment(binary)
  end

  defp extract_fragment(<<>>), do: []
  defp extract_fragment(binary) do
    <<type::integer-size(8), length::integer-size(8), remaining::binary>> = binary
    {value, next_binary} = extract_fragment(type, length, remaining)
    type_atom = TLVType.tlv_from_integer(type)

    size = bit_size(value)
    <<integer_value::size(size)>> = value
    converted_value = case type_atom do
      :method ->
        TLVMethod.method_from_integer(integer_value)
      :state ->
        integer_value
      :error ->
        TLVError.error_from_integer(integer_value)
      :retry_delay ->
        integer_value
      :permissions ->
        integer_value
      :separator ->
        nil
      _ ->
        value
    end
    [%TLV{type: type_atom, value: converted_value} | extract_fragment(next_binary)]
  end

  defp extract_fragment(type, 255, binary) do
    case binary do
      <<value::binary-size(255), ^type::size(8), new_length::size(8), remaining::binary>> ->
        {more_value, next_binary} = extract_fragment(type, new_length, remaining)
        {value <> more_value, next_binary}
      <<value::binary-size(255), next_binary::binary>> ->
        {value, next_binary}
    end
  end

  defp extract_fragment(_type, length, binary) do
    <<value::binary-size(length), next_binary::binary>> = binary
    {value, next_binary}
  end
end
