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

defmodule PairingTest do
  use ExUnit.Case

  alias HAP.Pairing
  # doctest SRP
  doctest Pairing.Impl

  def a_private, do: File.read! "test/pairing/values/a_private.bin"
  def a_public, do: File.read! "test/pairing/values/a_public.bin"
  def b_private, do: File.read! "test/pairing/values/b_private.bin"
  def b_public, do: File.read! "test/pairing/values/b_public.bin"
  def premaster_secret, do: File.read! "test/pairing/values/premaster_secret.bin"
  def random, do: File.read! "test/pairing/values/random_scrambling_parameter.bin"
  def salt, do: File.read! "test/pairing/values/salt.bin"
  def session_key, do: File.read! "test/pairing/values/session_key.bin"
  def verifier, do: File.read! "test/pairing/values/verifier.bin"
  def client_session_proof, do: File.read! "test/pairing/values/client_session_proof.bin"
  def host_session_proof, do: File.read! "test/pairing/values/host_session_proof.bin"
  
  def username, do: "alice"
  def password, do: "password123"

  
  test "verifier" do 
    c_verifier = Pairing.Crypto.derrived_key(username(), password(), salt())
    |> Pairing.Crypto.verifier()

    assert c_verifier == verifier()
  end

  test "host public key" do
    public = Pairing.Crypto.host_public_key(verifier(), b_private())
    b_public = b_public()

    assert byte_size(public) == byte_size(b_public)
    assert public == b_public
  end

  test "client public key" do
    public = Pairing.Crypto.client_public_key(a_private())
    assert public == a_public()
  end

  test "random scrambling parameter" do
    random = Pairing.Crypto.random_scrambling_parameter(a_public(), b_public())
    assert random == random()
  end

  test "client premaster_secret" do
    derrived_key = Pairing.Crypto.derrived_key(username(), password(), salt())
    secret = Pairing.Crypto.client_premaster_secret(derrived_key, b_public(), a_private(), a_public())

    assert secret == premaster_secret()
  end

  test "host premaster secret" do
    secret = Pairing.Crypto.host_premaster_secret(verifier(), b_public(), b_private(), a_public())

    assert secret == premaster_secret()
  end

  test "compare premaster secret" do
    derrived_key = Pairing.Crypto.derrived_key(username(), password(), salt())
    client_secret = Pairing.Crypto.client_premaster_secret(derrived_key, b_public(), a_private(), a_public())
    host_secret = Pairing.Crypto.host_premaster_secret(verifier(), b_public(), b_private(), a_public())

    assert client_secret == host_secret
  end

  test "session key from client secret" do
    derrived_key = Pairing.Crypto.derrived_key(username(), password(), salt())    
    client_secret = Pairing.Crypto.client_premaster_secret(derrived_key, b_public(), a_private(), a_public())
    key = Pairing.Crypto.session_key(client_secret)

    assert key == session_key()
  end

  test "session key from host secret" do
    host_secret = Pairing.Crypto.host_premaster_secret(verifier(), b_public(), b_private(), a_public())
    key = Pairing.Crypto.session_key(host_secret)

    assert key == session_key()
  end

  test "host session proof" do
    h_session_proof = Pairing.Crypto.host_session_proof(a_public(), client_session_proof(), session_key())

    assert h_session_proof == host_session_proof()
  end

  test "client session proof" do
    c_session_proof = Pairing.Crypto.client_session_proof(username(), salt(), a_public(), b_public(), session_key())

    assert c_session_proof == client_session_proof()
  end
end