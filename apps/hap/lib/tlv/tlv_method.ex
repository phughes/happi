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

defmodule TLVMethod do
  @moduledoc """
  TLV Methods are defined in table 4.4 of the HAP-Specification-Non-Commercial-Version.pdf
  They are used as the value of TLVs of type TLVType.method.
  """
  @type tlv_method :: atom

  @doc """
    integer_from_method(method)

    Returns the integer value associated with the TLVMethod atom.
  """
  @spec integer_from_method(tlv_method) :: integer  
  def integer_from_method(method) do
    case method do
      :reserved -> 0x00
      :pair_setup -> 0x01
      :pair_verify -> 0x02
      :add_pairing -> 0x03
      :remove_pairing -> 0x04
      :list_pairings -> 0x05
    end
  end

  @doc """
  method_from_integer(integer)

  Returns the TLVMethod atom associated with the given integer.
  """
  @spec method_from_integer(integer) :: tlv_method
  def method_from_integer(integer) do
    case integer do
      0x00 -> :reserved
      0x01 -> :pair_setup
      0x02 -> :pair_verify
      0x03 -> :add_pairing
      0x04 -> :remove_pairing
      0x05 -> :list_pairings
      true -> :reserved
    end
  end

  @spec reserved :: tlv_method
  def reserved, do: :reserved

  @spec pair_setup :: tlv_method  
  def pair_setup, do: :pair_setup
  
  @spec pair_verify :: tlv_method  
  def pair_verify, do: :pair_verify
  
  @spec add_pairing :: tlv_method
  def add_pairing, do: :add_pairing
  
  @spec remove_pairing :: tlv_method
  def remove_pairing, do: :remove_pairing
  
  @spec list_pairings :: tlv_method
	def list_pairings, do: :list_pairings
end
