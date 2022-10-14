defmodule MiniTellerWeb.PageController do
  use MiniTellerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
