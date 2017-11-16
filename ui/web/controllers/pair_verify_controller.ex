defmodule Ui.PairVerifyController do
  use Ui.Web, :controller

  require Logger

  def pair_verify(conn, params) do
    Logger.info "conn: #{inspect(conn)} \nparams: #{inspect(params)}"
    render conn, "index.html"
  end
end
