defmodule HapWeb.PairVerifyController do
  use HapWeb, :controller

  require Logger

  def pair_verify(conn, params) do
    Logger.info("conn: #{inspect(conn)} \nparams: #{inspect(params)}")
    render(conn, "index.html")
  end
end
