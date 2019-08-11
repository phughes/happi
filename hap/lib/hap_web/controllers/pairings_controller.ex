defmodule HapWeb.PairingsController do
  use HapWeb, :controller

  require Logger

  def pairings(conn, params) do
    Logger.info("conn: #{inspect(conn)} \nparams: #{inspect(params)}")
    render(conn, "index.html")
  end
end
