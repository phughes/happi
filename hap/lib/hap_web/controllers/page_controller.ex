defmodule HapWeb.PageController do
  use HapWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
