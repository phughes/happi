defmodule Ui.PairingsController do
  use Ui.Web, :controller

  require Logger

  def pairings(conn, params) do
    Logger.info "conn: #{inspect(conn)} \nparams: #{inspect(params)}"
    render conn, "index.html"
  end
end
