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

defmodule HapWeb.Plugs.DecodeTLV do
  import Plug.Conn

  alias HAP.TLV
  require Logger

  def init(options), do: options

  def call(conn, _options) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, length: 1_000_000)
    tlvs = TLV.decode(body)
    Logger.info("TLVs: #{inspect(tlvs)}")
    assign(conn, :tlvs, tlvs)
  end
end
