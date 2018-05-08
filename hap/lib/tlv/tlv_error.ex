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

defmodule HAP.TLV.TLVError do
  @moduledoc """
  TLV Errors are defined in table 4.5 of the HAP-Specification-Non-Commercial-Version.pdf
  They are used as the value of TLVs of error TLVerror.error.
  """

  # TLVErrors are single bytes on the wire, we convert them to atoms for easier debugging.
  @type tlv_error ::
          :reserved
          | :unknown
          | :authentication
          | :backoff
          | :max_peers
          | :max_tries
          | :unavailable
          | :error

  @doc """
    integer_from_error(error)

    Returns the integer value associated with the TLVError atom.
  """
  @spec integer_from_error(tlv_error) :: integer
  def integer_from_error(error) do
    case error do
      :reserved -> 0x00
      :unknown -> 0x01
      :authentication -> 0x02
      :backoff -> 0x03
      :max_peers -> 0x04
      :max_tries -> 0x05
      :unavailable -> 0x06
      :error -> 0x07
    end
  end

  @doc """
  error_from_integer(integer)

  Returns the TLVError atom associated with the given integer.
  """
  @spec error_from_integer(integer) :: tlv_error
  def error_from_integer(integer) do
    case integer do
      0x00 -> :reserved
      0x01 -> :unknown
      0x02 -> :authentication
      0x03 -> :backoff
      0x04 -> :max_peers
      0x05 -> :max_tries
      0x06 -> :unavailable
      0x07 -> :error
      true -> :reserved
    end
  end

  @doc """
    - description: Reserved.
  """
  @spec reserved :: tlv_error
  def reserved, do: :reserved

  @doc """
    - description: Generic error to handle unexpected errors.
  """
  @spec unknown :: tlv_error
  def unknown, do: :error

  @doc """
    - description: Setup code of signature verification failed.
  """
  @spec authentication :: tlv_error
  def authentication, do: :authentication

  @doc """
    - description: Client mus look at the retyr delay TLV item and
        wait that many seconds before retrying.
  """
  @spec backoff :: tlv_error
  def backoff, do: :backoff

  @doc """
    - description: Server cannot accept any more pairings.
  """
  @spec max_peers :: tlv_error
  def max_peers, do: :max_peers

  @doc """
    - description: Server reached its maximum number of authentication requests.
  """
  @spec max_tries :: tlv_error
  def max_tries, do: :max_tries

  @doc """
    - description: Server pairing mehtod is unavailable.
  """
  @spec unavailable :: tlv_error
  def unavailable, do: :unavailable

  @doc """
    - description: Server is busy and cannot accept a pairing request at this time.
  """
  @spec error :: tlv_error
  def error, do: :error
end
