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

defmodule TLVTest do
  use ExUnit.Case
  alias HAP.TLV
  alias HAP.TLV.TLVError
  alias HAP.TLV.TLVMethod
  alias HAP.TLV.TLVType

  doctest TLV

  test "single tlv to binary" do
    assert TLV.encode(%TLV{type: TLVType.state, value: 0}) == <<6, 1, 0>>
  end

  test "two tlv to binary" do
    assert TLV.encode([%TLV{type: TLVType.state, value: 0}, %TLV{type: TLVType.retry_delay, value: 1025}]) == <<6, 1, 0, 8, 2, 4, 1>>
  end

  # test integer encodings.
  test "method round-trip" do
    value = TLVMethod.add_pairing
    tlv = [%TLV{type: TLVType.method, value: value}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "state round-trip" do
    value = 0x01
    tlv = [%TLV{type: TLVType.state, value: value}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "error round-trip" do
    value = TLVError.backoff
    tlv = [%TLV{type: TLVType.error, value: value}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "retry delay round-trip" do
    value = 1025
    tlv = [%TLV{type: TLVType.retry_delay, value: value}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "permissions round-trip" do
    value = 0x01
    tlv = [%TLV{type: TLVType.permissions, value: value}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "separator round-trip" do
    value = nil
    tlv = [%TLV{type: TLVType.separator, value: value}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end
  # test binary encodings.
  test "identifier round-trip" do
    value = "THis is a ÜTF8 String with ümløts and çertain öthér stuff"
    tlv = [%TLV{type: TLVType.identifier, value: value}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "salt round-trip" do
    cert = File.read!("test/tlv/test_cert.bin")
    tlv = [%TLV{type: TLVType.certificate, value: cert}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "public key round-trip" do
    cert = File.read!("test/tlv/test_3k_bytes.bin")
    tlv = [%TLV{type: TLVType.certificate, value: cert}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "proof round-trip" do
    cert = File.read!("test/tlv/test_cert.bin")
    tlv = [%TLV{type: TLVType.certificate, value: cert}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "encrypted data round-trip" do
    cert = File.read!("test/tlv/test_3k_bytes.bin")
    tlv = [%TLV{type: TLVType.certificate, value: cert}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "certificate round-trip" do
    cert = File.read!("test/tlv/test_cert.bin")
    tlv = [%TLV{type: TLVType.certificate, value: cert}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "signature round-trip" do
    cert = File.read!("test/tlv/test_cert.bin")
    tlv = [%TLV{type: TLVType.certificate, value: cert}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "fragment first round-trip" do
    cert = File.read!("test/tlv/test_cert.bin")
    tlv = [%TLV{type: TLVType.certificate, value: cert}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

  test "fragment last round-trip" do
    cert = File.read!("test/tlv/test_cert.bin")
    tlv = [%TLV{type: TLVType.certificate, value: cert}]
    tlv_copy = TLV.encode(tlv)
    |> TLV.decode

    assert tlv == tlv_copy
  end

end
