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

defmodule SRP.Impl do
  @path "/var/lib/happi/"
  @setup_code_filename "setup_code.txt"

  @generator <<5>>
  @version :"6a"
  @prime File.read!("lib/srp/prime.bin")

  @doc """
  reset()

    Empties the happi directory and creates a new setup code.
    
    This should have the effect of unpairing the device from all
    associations.

    The return value is the return of writing the new setup code.
  """
  @spec reset() :: atom
  def reset() do
    File.rm_rf!(@path)
    File.mkdir!(@path)
    File.write!(@path <> @setup_code_filename, generate_setup_code())
  end

  @doc """

  """
  def setup_code() do
    case File.read(@path <> @setup_code_filename) do
      {:ok, code} -> 
        if valid_setup_code?(code) do
          {:ok, code}
        else
          {:error, :invalid_code}
        end
      error -> error
    end
  end

  def generate_setup_code() do
    # :rand.uniform generates a number between 1 and n,
    # but valid setup codes can be as small as 0.
    minus = fn(a) -> a - 1 end

    first = :rand.uniform(1000)
    |> minus.()
    |> Integer.to_string
    |> String.pad_leading(3, ["0"])

    second = :rand.uniform(100)
    |> minus.()
    |> Integer.to_string
    |> String.pad_leading(2, ["0"])
    
    third = :rand.uniform(1000)
    |> minus.()
    |> Integer.to_string
    |> String.pad_leading(3, ["0"])

    code = first <> "-" <> second <> "-" <> third
    if valid_setup_code?(code) do
      code
    else
      generate_setup_code()
    end
  end

  # Apple has supplied a list of invalid setup codes. Don't use them.
  def valid_setup_code?(code) when is_binary(code) do
    invalid_codes = ["000-00-000", "111-11-111", "222-22-222", "333-33-333", "444-44-444", "555-55-555", "666-66-666", "777-77-777", "888-88-888", "999-99-999", "123-45-678", "876-54-321"]
    Enum.any?(invalid_codes, &(&1 == code)) == false && String.match?(code, ~r/\d{3}-\d{2}-\d{3}/)
  end
end