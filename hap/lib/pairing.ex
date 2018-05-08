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

defmodule HAP.Pairing do
  use GenServer
  require Logger
  require HKDF
  alias HAP.Pairing.Crypto
  alias HAP.Pairing.Impl

  def pairing_m1(ip_address) do
    GenServer.call(HAP.Pairing, {:pairing_m1, ip_address})
  end

  def pairing_m3(ip_address, public_key, srp_proof) do
    GenServer.call(HAP.Pairing, {:pairing_m3, {ip_address, public_key, srp_proof}})
  end

  def pairing_m5(ip_address, encrypted_data) do
    GenServer.call(HAP.Pairing, {:pairing_m5, {ip_address, encrypted_data}})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:pairing_m1, ip_address}, _from, state) do
    username = "Pair-Setup"
    {:ok, password} = Impl.setup_code()
    Logger.info("Setup code: #{inspect(password)}")

    salt = Crypto.salt()
    derrived_key = Crypto.derrived_key(username, password, salt)
    verifier = Crypto.verifier(derrived_key)
    private_key = Crypto.private_key()
    public_key = Crypto.host_public_key(verifier, private_key)

    pairing_info = %{
      username: username,
      password: password,
      salt: salt,
      verifier: verifier,
      private_key: private_key,
      host_public_key: public_key
    }

    {:reply, {public_key, salt}, Map.put(state, ip_address, pairing_info)}
  end

  def handle_call(
        {:pairing_m3, {ip_address, client_public_key, client_session_proof}},
        _from,
        state
      ) do
    pairing_info = state[ip_address]

    %{
      username: username,
      salt: salt,
      verifier: verifier,
      private_key: private_key,
      host_public_key: host_public_key
    } = pairing_info

    session_key =
      Crypto.host_premaster_secret(verifier, host_public_key, private_key, client_public_key)
    proof =
      Crypto.client_session_proof(username, salt, client_public_key, host_public_key, session_key)

    if client_session_proof == proof do
      session_proof =
        Crypto.host_session_proof(client_public_key, client_session_proof, session_key)

      pairing_info = %{session_key: session_key}
      state = Map.put(state, ip_address, pairing_info)

      {:reply, {:ok, session_proof}, state}
    else
      {:reply, {:error, :authentication}, state}
    end
  end

  def handle_call({:pairing_m5, {ip_address, encrypted_data}}, _from, state) do
    %{session_key: session_key} = state[ip_address]    
    pairing_id = Impl.pairing_id()
    {ltpk, ltsk} = Impl.keypair()

    encrypted_response =
      Impl.m5_decrypt(encrypted_data, session_key)
      |> Impl.m5_decode()
      |> Impl.m5_verify(session_key)
      |> Impl.m5_store_pairing()
      |> Impl.m6_encrypted_response(session_key, pairing_id, ltpk, ltsk)

    new_state = Map.delete(state, ip_address)
    {:reply, encrypted_response, new_state}
  end
end
