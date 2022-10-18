defmodule MiniTeller.Client.Live do
  @moduledoc """
    Live teller.io sandbox api
    eg. MiniTeller.Client.Live.sign_in("yellow_angel", "saudiarabia")
  """

  @behaviour MiniTeller.Client

  alias MiniTeller.Client.ParseError
  alias MiniTeller.Client.Session

  require Logger

  def build_client do
    middleware = [
      {Tesla.Middleware.BaseUrl, base_url()},
      {Tesla.Middleware.Timeout, timeout: 30_000},
      Tesla.Middleware.JSON,
      MiniTeller.Client.IOS,
      {Tesla.Middleware.Logger, filter_headers: ~w[device-id api-key]},
      Tesla.Middleware.Telemetry,
    ]

    Tesla.client(middleware, {Tesla.Adapter.Finch, name: MiniTeller.Finch})
  end

  def sign_in(username, password) do
    Session.establish()
    %{device_id: id} = Session.info()

    build_client()
    |> Tesla.request(
      url: "/signin",
      method: :post,
      body: %{username: username, password: password},
      headers: [{"device-id", id}]
    )
    |> parse_response()
  end

  def enroll() do
    build_client()
    |> Tesla.get("/")
    |> parse_response()
  end

  def reauthenticate() do
    build_client()
    |> Tesla.get("/")
    |> parse_response()
  end

  def accounts() do
    build_client()
    |> Tesla.get("/")
    |> parse_response()
  end

  def transactions() do
    build_client()
    |> Tesla.get("/")
    |> parse_response()
  end

  def parse_response(request) do
    case request do
      {:ok, %{status: 200, body: %{"data" => data}}} -> {:ok, data}
      error -> ParseError.call(error)
    end
  end

  defp base_url, do: Application.get_env(:mini_teller, :base_url)
end
