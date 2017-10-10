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

defmodule Pairing.Crypto do
  @moduledoc """
  Pairing.Crypto is an implementation of the Session Remote Protocol 
  cryptographic functions modified to match the ones used in 
  Apple's HomeKit Accessory Protocol Specification.
  
  The following formulas are taken rfc 5054 located at http://srp.stanford.edu/doc.html.
  
    The premaster secret is calculated by the client as follows:
    I, P = <read from user>
    N, g, s, B = <read from server>
    a = random()
    A = g^a % N
    u = SHA1(PAD(A) | PAD(B))
    k = SHA1(N | PAD(g))
    x = SHA1(s | SHA1(I | ":" | P))
    <premaster secret> = (B - (k * g^x)) ^ (a + (u * x)) % N

    The premaster secret is calculated by the server as follows:
    N, g, s, v = <read from password file>
    b = random()
    k = SHA1(N | PAD(g))
    B = k*v + g^b % N
    A = <read from client>
    u = SHA1(PAD(A) | PAD(B))
    <premaster secret> = (A * v^u) ^ b % N

    I've renamed the variables to match Apple's documentation &
    updated the hashing algorithm to SHA512 below.

    # client side calculations:
    username, password = <read from user>
    prime, generator, salt, host_public_key = <read from server>
    client_private_key = random()
    client_public_key = generator^client_private_key % prime
    random_scrambling_parameter = SHA512(PAD(client_public_key) | PAD(host_public_key))
    multiplier = SHA512(prime | PAD(generator))
    derrived_key = SHA512(salt | SHA512(username | ":" | password))
    <premaster secret> = (host_public_key - (multiplier * (generator^derrived_key % prime)) ^ (client_private_key + (random_scrambling_parameter * derrived_key)) % prime

    # server side calculations:
    prime, generator, salt, verifier = <read from password file>
    host_private_key = random()
    multiplier = SHA512(prime | PAD(generator))
    host_public_key = multiplier*verifier + generator^host_private_key % prime
    client_public_key = <read from client>
    random_scrambling_parameter = SHA512(PAD(client_public_key) | PAD(host_public_key))
    <premaster secret> = (client_public_key * (verifier^random_scrambling_parameter % prime))use  ^ host_private_key % prime

  """

  use Bitwise
  # modulus (prime) and generator are specified by the 3072 bit group of RFC-5054
  @generator <<5>>
  @modulus File.read!("lib/pairing/prime.bin")
  @version :"6a"

  @doc """
    Generates a new 16 byte random salt value.
  """
  def salt do
    :crypto.strong_rand_bytes(16)
  end

  @doc """
    Generates a new 32 byte private key.
  """
  def private_key do
    :crypto.strong_rand_bytes(32)
  end

  @doc """
    Calculate the derrived key from a given username, password & salt.
  """
  @spec derrived_key(String.t, String.t, binary) :: binary    
  def derrived_key(username, password, salt) do
    # derrived_key = SHA512(salt | SHA512(username | ":" | password))  
    :crypto.hash(:sha512, [salt, :crypto.hash(:sha512,  [username, ":", password])])
  end

  @spec verifier(binary) :: binary
  def verifier(derrived_key) do
    :crypto.mod_pow(@generator, derrived_key, @modulus)
  end

  @spec random_scrambling_parameter(binary, binary) :: binary  
  def random_scrambling_parameter(client_key, host_key) do
    # random_scrambling_parameter = SHA512(PAD(client_public_key) | PAD(host_public_key))  
    :crypto.hash(:sha512, pad(client_key) <> pad(host_key))
  end
  
  @doc """
    host_public_key = multiplier*verifier + generator^host_private_key % prime
    # B = (k * v + pow(g, b, N)) % N

    The host key is the server's public key.
  """
  @spec host_public_key(binary, binary) :: binary
  def host_public_key(verifier, private_key) do
    # This doesn't work. There's a hash generated in there somewhere (the multiplier), which needs to use SHA512.
    # {public, _} = :crypto.generate_key(:srp, {:host, [verifier, @generator, @modulus, @version]}, private_key)
    # public

    power = :crypto.mod_pow(@generator, private_key, @modulus) |> :binary.decode_unsigned()
    int_multiplier = multiplier() |> :binary.decode_unsigned()
    int_veryifier = verifier |> :binary.decode_unsigned()
    prime = @modulus |> :binary.decode_unsigned()

    rem(((int_multiplier * int_veryifier) + power), prime) |> :binary.encode_unsigned()
  end

  @doc """
    client_public_key = generator^client_private_key % prime
  """
  @spec client_public_key(binary) :: binary
  def client_public_key(client_private_key) do
    {public, _} = :crypto.generate_key(:srp, {:user, [@generator, @modulus, @version]}, client_private_key)    
    public
  end

  @doc """
    Compute the premaster secret on the client.
    S_c = pow(B - k * pow(g, x, N), a + u * x, N)
  """
  @spec client_premaster_secret(binary, binary, binary, binary) :: binary
  def client_premaster_secret(derrived_key, host_public_key, client_private_key, client_public_key) do
    # 'B'
    int_host_public_key = host_public_key |> :binary.decode_unsigned()
    # 'k'
    int_multiplier = multiplier() |> :binary.decode_unsigned()
    power = :crypto.mod_pow(@generator, derrived_key, @modulus) |> :binary.decode_unsigned() 

    base = abs(int_host_public_key - (int_multiplier * power)) |> :binary.encode_unsigned()

    # 'a'
    int_client_private_key = client_private_key |> :binary.decode_unsigned()
    # 'u'
    int_random_scrambling_parameter = random_scrambling_parameter(client_public_key, host_public_key) |> :binary.decode_unsigned()
    # 'x'
    int_derrived_key = derrived_key |> :binary.decode_unsigned()
    # 'a + u * x'
    exponent = (int_client_private_key + (int_random_scrambling_parameter * int_derrived_key)) |> :binary.encode_unsigned()

    :crypto.mod_pow(base, exponent, @modulus)
  end

  @doc """
    Compute the premaster secret on the host.

    pow(A * pow(v, u, N), b, N)
  """
  @spec host_premaster_secret(binary, binary, binary, binary) :: binary
  def host_premaster_secret(verifier, host_public_key, host_private_key, client_public_key) do
    # 'pow(v, u, N)' power
    power = :crypto.mod_pow(verifier,random_scrambling_parameter(client_public_key, host_public_key), @modulus) |> :binary.decode_unsigned()
    # 'A' client public_key
    int_client_public_key = client_public_key |> :binary.decode_unsigned()
    # 'A * pow(v, u, N)' base
    base = (int_client_public_key * power) |> :binary.encode_unsigned()

    :crypto.mod_pow(base, host_private_key, @modulus)
    # :crypto.compute_key(:srp, client_public_key, {host_public_key, host_private_key}, {:host, [verifier, @modulus, @version]})    
  end

  @doc """
    Compute the shared session key from the premaster secret.
  """
  @spec session_key(binary) :: binary
  def session_key(premaster_secret) do
    :crypto.hash(:sha512, premaster_secret)
  end

  @doc """
    multiplier = SHA512(prime | PAD(generator))
  """
  def multiplier do
    :crypto.hash(:sha512, @modulus <> pad(@generator))
  end

  defp pad_length(width, length) do
    rem(width - length, width)
    |> rem(width)
  end

  defp pad(binary) do
    case pad_length(byte_size(@modulus), byte_size(binary)) do
      0 -> binary
      n -> 
        length = n * 8
        <<0::size(length), binary::binary>>
    end
  end  
end