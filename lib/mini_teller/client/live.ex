defmodule MiniTeller.Client.Live do
  @moduledoc """
    Live teller.io sandbox api
    MiniTeller.Client.Live.sign("yellow_angel", "saudiarabia")
    MiniTeller.Client.Live.bank_job_key()
  """

  @behaviour MiniTeller.Client
  alias MiniTeller.Client.ParseError

  require Logger

  def build_client do
    middleware = [
      {Tesla.Middleware.BaseUrl, base_url()},
      {Tesla.Middleware.Timeout, timeout: 30_000},
      Tesla.Middleware.JSON,
      MiniTeller.Client.IOS,
      # {Tesla.Middleware.Logger, filter_headers: ~w[device-id api-key]},
      Tesla.Middleware.Telemetry
    ]

    Tesla.client(middleware, {Tesla.Adapter.Finch, name: MiniTeller.Finch})
  end

  def sign_in(username, password) do
    build_client()
    |> Tesla.request(method: :post, body: %{username: username, password: password})
    |> parse_response()
  end

  # [session_key, _path, _method] = String.split(cookie, ";")
  # ["_bank_job_key", key] = String.split(session_key, "=")

  def bank_job_key do
    Tesla.request(method: :get, url: Application.get_env(:mini_teller, :base_url))
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
      {:ok, %{status: 429}} -> {:error, :rate_limited}
      error -> ParseError.call(error)
    end
  end

  defp base_url, do: Application.get_env(:mini_teller, :base_url)
end
