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

defmodule Ui.PairSetupController do
  use Ui.Web, :controller

  require Logger
  alias HAP.TLV
  alias HAP.Pairing
  alias Plug.Conn


  @setup_method %TLV{type: TLV.TLVType.method, value: TLV.TLVMethod.pair_setup_non_mfi}
  @m1 %TLV{type: TLV.TLVType.state, value: 1}
  @m2 %TLV{type: TLV.TLVType.state, value: 2}
  @m3 %TLV{type: TLV.TLVType.state, value: 3}
  @m4 %TLV{type: TLV.TLVType.state, value: 4}
  @m5 %TLV{type: TLV.TLVType.state, value: 5}
  @m6 %TLV{type: TLV.TLVType.state, value: 6}

  
  def pair_setup(%Conn{assigns: %{tlvs: [@setup_method, @m1]}} = conn, _params) do
    Logger.info "m1 received #{inspect(conn.remote_ip)}"
    
    {public_key, salt} = Pairing.pairing_m1(conn.remote_ip)
    response_data = [@m2, 
                     %TLV{type: TLV.TLVType.public_key, value: public_key}, 
                     %TLV{type: TLV.TLVType.salt, value: salt}]

    data = HAP.TLV.encode(response_data)

    Logger.info "sending m2 key_length: #{inspect(byte_size(public_key))} salt length: #{inspect(byte_size(salt))}"
    conn
    |> put_resp_header("connection", "keep-alive")
    |> put_resp_header("content-type", "application/pairing+tlv8")
    |> send_resp(200, data)
  end

  def pair_setup(%Conn{assigns: %{tlvs: [@m3, client_public_key, client_srp_proof]}} = conn, _params) do
    Logger.info "m3 received"
    response_data = case HAP.Pairing.pairing_m3(conn.remote_ip, client_public_key.value, client_srp_proof.value) do
      {:ok, accessory_srp_proof} ->
        [@m4, %TLV{type: TLV.TLVType.proof, value: accessory_srp_proof}]
      {:error, :authentication} ->
        Logger.info "m3 auth error."
        [@m4, %TLV{type: TLV.TLVType.error, value: TLV.TLVError.authentication}]
    end

    data = HAP.TLV.encode(response_data)

    Logger.info "sending m4: #{inspect(data)}"
    conn
    |> put_resp_header("connection", "keep-alive")
    |> put_resp_header("content-type", "application/pairing+tlv8")
    |> send_resp(200, data)
  end

  def pair_setup(%Conn{assigns: %{tlvs: [%TLV{type: :encrypted_data, value: encrypted_data}, @m5]}} = conn, _params) do
    Logger.info "m5 received"
    response_data = case HAP.Pairing.pairing_m5(conn.remote_ip, encrypted_data) do
      {:ok, encrypted_response} ->
        Logger.info "m6 response generation succeeded. #{inspect(encrypted_response)}"
        [@m6, %TLV{type: TLV.TLVType.encrypted_data, value: encrypted_response}]
      _ ->
        Logger.info "m6 response generation failed."
        [@m6, %TLV{type: TLV.TLVType.error, value: TLV.TLVError.authentication}]
    end    

    data = HAP.TLV.encode(response_data)
    Logger.info "sending m6: #{inspect(data)}"
    conn
    |> put_resp_header("connection", "keep-alive")
    |> put_resp_header("content-type", "application/pairing+tlv8")
    |> send_resp(200, data)
  end

  def pair_setup(conn, params) do
    Logger.info "last!"
    Logger.info "params: #{inspect(params)} \n\n\nconn: #{inspect(conn.assigns)}"
    render conn, "index.html"
  end

end
