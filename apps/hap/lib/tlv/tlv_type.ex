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

defmodule TLVType do
  @moduledoc """
  TLV Types are defined in table 4.6 of the HAP-Specification-Non-Commercial-Version.pdf
  They are used to declare the type of the value they are paired with.
  """

  @typedoc """
  TLVTypes are just single bytes, but let's make sure that's what they are.
  """
  @type tlv_type :: atom

  @doc """
    integer_from_tlv(type)

    Returns the integer value associated with the TLVType.
  """
  @spec tlv_from_integer(tlv_type) :: integer  
  def integer_from_tlv(type) do
    case type do
      :method -> 0x00
      :identifier -> 0x01
      :salt -> 0x02
      :public_key -> 0x03
      :proof -> 0x04
      :encrypted_data -> 0x05
      :state -> 0x06
      :error -> 0x07
      :retry_delay -> 0x08
      :certificate -> 0x09
      :signature -> 0x0A
      :permissions -> 0x0B
      :fragment_data -> 0x0C
      :fragment_last -> 0x0D
      :separator -> 0xFF
    end
  end

  @doc """
  tlv_from_integer(integer)

  Returns the atom value associated with the TLVType.
  """
  @spec tlv_from_integer(integer) :: tlv_type  
  def tlv_from_integer(integer) do
    case integer do
      0x00 -> :method
      0x01 -> :identifier
      0x02 -> :salt
      0x03 -> :public_key
      0x04 -> :proof
      0x05 -> :encrypted_data
      0x06 -> :state
      0x07 -> :error
      0x08 -> :retry_delay
      0x09 -> :certificate
      0x0A -> :signature
      0x0B -> :permissions
      0x0C -> :fragment_data
      0x0D -> :fragment_last
      0xFF -> :separator
    end
  end

  @doc """
    - format: integer
    - description: Method used for pairing. See module TLVMethod.
  """
  @spec method :: tlv_type
  def method, do: :method	

  @doc """
    - format: UTF-8
    - description: Identifier for authentication.
  """
  @spec identifier() :: tlv_type
  def identifier, do: :identifier

  @doc """
    - format: bytes
    - description: 16+ bytes of random salt
  """
  @spec salt() :: tlv_type
  def salt, do: :salt

  @doc """
    - format: bytes
    - description: Curve25519, SRP public key, or signed Ed25519 key.
  """
  @spec public_key() :: tlv_type
  def public_key, do: :public_key

  @doc """
    - format: bytes
    - description: Ed25519 or SRP proof.
  """
  @spec proof() :: tlv_type
  def proof, do: :proof

  @doc """
    - format: bytes
    - description: Encrypted data wiht auth tag at end.
  """
  @spec encrypted_data() :: tlv_type
  def encrypted_data, do: :encrypted_data

  @doc """
    - format: integer
    - description: State of pairing process. 1 = M1, 2 = M2, etc.
  """
  @spec state() :: tlv_type
  def state, do: :state

  @doc """
    - format: integer
    - description: Error code. Must only be present if error code is not 0. See Table 4-5 or module TLVErrorCode.
  """
  @spec error() :: tlv_type
  def error, do: :error

  @doc """
    - format: integer
    - description: Seconds to delay until retrying a setup code.
  """
  @spec retry_delay() :: tlv_type
  def retry_delay, do: :retry_delay

  @doc """
    - format: bytes
    - description: X.509 Certificate.
  """
  @spec certificate() :: tlv_type
  def certificate, do: :certificate

  @doc """
    - format: bytes
    - description: Ed25519
  """
  @spec signature() :: tlv_type
  def signature, do: :signature

  @doc """
    - format: integer
    - description: Bit value describing permissions of the controller.
      None (0x00): regular user.
      Bit 1 (0x01): Admin that is able to add and remove pairings against the accessory.
  """
  @spec permissions() :: tlv_type
  def permissions, do: :permissions

  @doc """
    - format: bytes
    - description: Non-last fragment of data. If length is 0 it's an ACK.
  """
  @spec fragment_data() :: tlv_type
  def fragment_data, do: :fragment_data

  @doc """
    - format: bytes
    - description: Last fragment of data.
  """
  @spec fragment_last() :: tlv_type
  def fragment_last, do: :fragment_last

  @doc """
    - format: null
    - description: Zero-length TLV that separates diifferent TLVs in a list.
  """
  @spec separator() :: tlv_type
  def separator, do: :separator
end