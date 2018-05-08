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

defmodule HAP.Pairing.Impl do
  require Logger
  alias Salty.Sign.Ed25519
  alias Salty.Aead.Chacha20poly1305

  alias HAP.TLV

  @path "#{Application.get_env(:hap, HAP.Pairing.Impl)[:user_partition]}/happi/"
  @setup_code_filename "setup_code.txt"
  @pairing_id_filename "pairing_id.txt"
  @pairings_directory_name "pairings/"
  @keypair_filename "keypair.bin"

  @debug_path "#{Application.get_env(:hap, HAP.Pairing.Impl)[:user_partition]}/debug/"

  @doc """
    setup()
    Initializes the happi directory if it hasn't been created yet.
  """
  def setup() do
    if File.dir?(@path) == false do
      File.mkdir(@path)
    end
    if File.exists?(@path <> @setup_code_filename) == false do
      Logger.info "Writing new setup code."
      File.write!(@path <> @setup_code_filename, generate_setup_code())
    end
    if File.exists?(@path <> @pairing_id_filename) == false do
      Logger.info "Writing new pairing ID."
      File.write!(@path <> @pairing_id_filename, generate_pairing_id())
    end
    if File.exists?(@path <> @keypair_filename) == false do
      Logger.info "Writing new keypair."
      {:ok, keypair} = Ed25519.keypair()
      File.write!(@path <> @keypair_filename, keypair)
    end
  end

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
    setup()
  end

  @doc """

  """
  def setup_code() do
    File.read(@path <> @setup_code_filename)
  end

  defp generate_setup_code() do
    # :rand.uniform generates a number between 1 and n,
    # but valid setup codes can be as small as 0.
    first = :rand.uniform(1000) - 1
    |> Integer.to_string
    |> String.pad_leading(3, ["0"])

    second = :rand.uniform(100) - 1
    |> Integer.to_string
    |> String.pad_leading(2, ["0"])

    third = :rand.uniform(1000) - 1
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
  defp valid_setup_code?(code) when is_binary(code) do
    invalid_codes = ["000-00-000", "111-11-111", "222-22-222", "333-33-333", "444-44-444", "555-55-555", "666-66-666", "777-77-777", "888-88-888", "999-99-999", "123-45-678", "876-54-321"]
    Enum.any?(invalid_codes, &(&1 == code)) == false && String.match?(code, ~r/\d{3}-\d{2}-\d{3}/)
  end

  @doc """
    Return the persistent pairing id to identify the device.
    It should be of the format: 66:72:0B:39:D7:8F
  """
  def pairing_id() do
    File.read!(@path <> @pairing_id_filename)
  end

  defp generate_pairing_id() do
    pair = fn() ->
      :rand.uniform(256) - 1
      |> Integer.to_string(16)
      |> String.pad_leading(2, ["0"])
    end

    Enum.reduce(1..5, pair.(), fn _, acc -> acc <> ":" <> pair.() end)
  end

  # M5 request helpers.
  @doc """

  """
  @spec keypair() :: {binary, binary}
  def keypair() do
    <<public::binary-size(32), secret::binary-size(32)>> = File.read!(@path <> @keypair_filename)
    {public, secret}
  end

  def save_device_key(device_id, key) do
    File.write!(@path <> @pairings_directory_name <> device_id <> ".bin", key)
  end

  @spec device_key(binary) :: {atom, binary}
  def device_key(device_id) do
    File.read(@path <> @pairings_directory_name <> device_id <> ".bin")
  end

  def m5_decrypt(encrypted_data, session_key) do
    if File.dir?(@debug_path) == false do
      File.mkdir(@debug_path)
    end
    File.write!(@debug_path <> "key.bin", session_key)
    File.write!(@debug_path <> "data.bin", encrypted_data)
    nonce = "PS-Msg05"
    aad = <<>>
    nsec = nil
    auth_tag_size = 16
    data_size = byte_size(encrypted_data) - auth_tag_size
    <<data::binary-size(data_size), auth_tag::binary-size(auth_tag_size)>> = encrypted_data

    salt = "Pair-Setup-Encrypt-Salt"
    info = "Pair-Setup-Encrypt-Info"
    new_key = HKDF.derive(:sha512, session_key, 32, salt, info)

    Chacha20poly1305.decrypt_detached(nsec, data, auth_tag, aad, nonce, new_key)
  end

  def m5_decode({:ok, bin_tlvs}) do
    Logger.info("decoding")
    {:ok, TLV.decode(bin_tlvs) |> TLV.to_map}
  end
  def m5_decode(error) do
    Logger.error "m5_decode error: #{inspect(error)}"
    error
  end

  def m5_verify({:ok, %{identifier: ios_device_pairing_id, public_key: ios_device_ltpk, signature: ios_device_signature}}, session_key) do
    Logger.info("verifying")
    salt = "Pair-Setup-Controller-Sign-Salt"
    info = "Pair-Setup-Controller-Sign-Info"
    ios_device_x = HKDF.derive(:sha512, session_key, 32, salt, info)

    ios_device_info = ios_device_x <> ios_device_pairing_id <> ios_device_ltpk
    verified = Ed25519.verify_detached(ios_device_signature, ios_device_info, ios_device_ltpk)
    Logger.info("verified: #{inspect(verified)}")

    if verified do
      {:ok, {ios_device_pairing_id, ios_device_ltpk}}
    else
      {:error, :authentication}
    end
  end
  def m5_verify(error, _) do
    Logger.error "m5_verify error: #{inspect(error)}"
    error
  end

  def m5_store_pairing({:ok, {ios_device_pairing_id, ios_device_ltpk}}) do
    save_device_key(ios_device_pairing_id, ios_device_ltpk)
    :ok
  end
  def m5_store_pairing(error) do
    Logger.error "m5_store_pairing error: #{inspect(error)}"
    error
  end

  def m6_encrypted_response(:ok, session_key, pairing_id, ltpk, ltsk) do
    salt = "Pair-Setup-Accessory-Sign-Salt"
    info = "Pair-Setup-Accessory-Sign-Info"
    accessory_x = HKDF.derive(:sha512, session_key, 32, salt, info)

    accessory_info = accessory_x <> pairing_id <> ltpk
    signature = Ed25519.sign_detached(accessory_info, ltsk)

    tlvs = [%TLV{type: TLV.TLVType.identifier, value: pairing_id},
            %TLV{type: TLV.TLVType.public_key, value: ltpk},
            %TLV{type: TLV.TLVType.signature, value: signature}]
    tlv_data = TLV.encode(tlvs)

    aad = <<>>
    nonce = "PS-Msg06"
    Chacha20poly1305.encrypt(tlv_data, aad, nil, nonce, session_key)
  end
  def m6_encrypted_response(error, _, _, _, _) do
    Logger.error "m6_encrypted_response error: #{inspect(error)}"
    error
  end
end
