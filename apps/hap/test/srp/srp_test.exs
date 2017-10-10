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

defmodule SRPTest do
  use ExUnit.Case
  # doctest SRP
  doctest SRP.Impl

  def a_private, do: File.read! "test/srp/values/a_private.bin"
  def a_public, do: File.read! "test/srp/values/a_public.bin"
  def b_private, do: File.read! "test/srp/values/b_private.bin"
  def b_public, do: File.read! "test/srp/values/b_public.bin"
  def premaster_secret, do: File.read! "test/srp/values/premaster_secret.bin"
  def random, do: File.read! "test/srp/values/random_scrambling_parameter.bin"
  def salt, do: File.read! "test/srp/values/salt.bin"
  def session_key, do: File.read! "test/srp/values/session_key.bin"
  def verifier, do: File.read! "test/srp/values/verifier.bin"
  def username, do: "alice"
  def password, do: "password123"

  
  test "verifier" do 
    c_verifier = SRP.Crypto.derrived_key(username(), password(), salt())
    |> SRP.Crypto.verifier()

    assert c_verifier == verifier()
  end

  test "host public key" do
    public = SRP.Crypto.host_public_key(verifier(), b_private())
    b_public = b_public()

    assert byte_size(public) == byte_size(b_public)
    assert public == b_public
  end

  test "client public key" do
    public = SRP.Crypto.client_public_key(a_private())
    assert public == a_public()
  end

  test "random scrambling parameter" do
    random = SRP.Crypto.random_scrambling_parameter(a_public(), b_public())
    assert random == random()
  end

  test "client premaster_secret" do
    derrived_key = SRP.Crypto.derrived_key(username(), password(), salt())
    secret = SRP.Crypto.client_premaster_secret(derrived_key, b_public(), a_private(), a_public())

    assert secret == premaster_secret()
  end

  test "host premaster secret" do
    secret = SRP.Crypto.host_premaster_secret(verifier(), b_public(), b_private(), a_public())

    assert secret == premaster_secret()
  end

  test "compare premaster secret" do
    derrived_key = SRP.Crypto.derrived_key(username(), password(), salt())
    client_secret = SRP.Crypto.client_premaster_secret(derrived_key, b_public(), a_private(), a_public())
    host_secret = SRP.Crypto.host_premaster_secret(verifier(), b_public(), b_private(), a_public())

    assert client_secret == host_secret
  end

  test "session key from client secret" do
    derrived_key = SRP.Crypto.derrived_key(username(), password(), salt())    
    client_secret = SRP.Crypto.client_premaster_secret(derrived_key, b_public(), a_private(), a_public())
    key = SRP.Crypto.session_key(client_secret)

    assert key == session_key()
  end

  test "session key from host secret" do
    host_secret = SRP.Crypto.host_premaster_secret(verifier(), b_public(), b_private(), a_public())
    key = SRP.Crypto.session_key(host_secret)

    assert key == session_key()
  end
end