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
  alias HAP.Pairing.Crypto

  def pairing_m1(ip_address) do
    Logger.info "mi with ip: #{inspect(ip_address)}"
    GenServer.call(HAP.Pairing, {:pairing_m1, ip_address})
  end

  def verify_srp_proof(ip_address, client_public_key, srp_proof) do
    GenServer.call(HAP.Pairing, {:verify_srp_proof, {ip_address, client_public_key, srp_proof}})
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
    HAP.Pairing.Impl.setup()
    {:ok, %{}}
  end

  def handle_call({:pairing_m1, ip_address}, _from, state) do
    username = "Pair-Setup"
    {:ok, password} = HAP.Pairing.Impl.setup_code()
    Logger.info("Setup code: #{inspect(password)}")
    salt = Crypto.salt()
    derrived_key = Crypto.derrived_key(username, password, salt)
    verifier = Crypto.verifier(derrived_key)
    private_key = Crypto.private_key()
    public_key = Crypto.host_public_key(verifier, private_key)

    pairing_info = %{username: username, password: password, salt: salt, verifier: verifier, private_key: private_key, host_public_key: public_key}
    {:reply, {public_key, salt}, Map.put(state, ip_address, pairing_info)}
  end

  def handle_call({:verify_srp_proof, {ip_address, client_public_key, client_session_proof}}, _from, state) do
    pairing_info = state[ip_address]
    %{username: username, salt: salt, verifier: verifier, private_key: private_key, host_public_key: host_public_key} = pairing_info

    premaster_secret = Crypto.host_premaster_secret(verifier, host_public_key, private_key, client_public_key)
    session_hash = Crypto.session_key(premaster_secret)
    verified = (client_session_proof == Crypto.client_session_proof(username, salt, client_public_key, host_public_key, session_hash))

    pairing_info = Map.put(pairing_info, :session_hash, session_hash)
    {:reply, verified, Map.put(state, ip_address, pairing_info)}
  end

  def handle_call({:pairing_m3, {ip_address, client_public_key, client_session_proof}}, _from, state) do
    %{session_hash: session_hash} = state[ip_address]

    session_proof = Crypto.host_session_proof(client_public_key, client_session_proof, session_hash)

    {:reply, session_proof, Map.put(state, :session_proof, session_proof)}
  end

  def handle_call({:pairing_m5, {ip_address, encrypted_data}}, _from, state) do
    
  end

  def handle_cast({:create, name}, names) do
    {:noreply, names}
  end
end