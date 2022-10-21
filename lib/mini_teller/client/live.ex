defmodule MiniTeller.Client.Live do
  @moduledoc """
    Live teller.io sandbox api
    eg. MiniTeller.Client.Live.signin("yellow_angel", "saudiarabia")
    MiniTeller.Client.Live.enroll()
  """

  @behaviour MiniTeller.Client

  alias MiniTeller.Client.ParseError
  # alias MiniTeller.Client.Session

  require Logger

  def build_client do
    middleware = [
      {Tesla.Middleware.BaseUrl, base_url()},
      {Tesla.Middleware.Timeout, timeout: 30_000},
      Tesla.Middleware.JSON,
      MiniTeller.Client.IOS,
      {Tesla.Middleware.Logger, filter_headers: ~w[]a},
      Tesla.Middleware.Telemetry
    ]

    Tesla.client(middleware, {Tesla.Adapter.Finch, name: MiniTeller.Finch})
  end

  def enroll() do
    with {:ok, mfa, %{f_token: f, r_token: r}} <- signin("yellow_angel", "saudiarabia"),
         {:ok, data} <- signin_mfa(mfa, r, f) do
      data
    else
      err -> err
    end
  end

  def signin(username, password) do
    # Session.establish()
    # %{device_id: id} = Session.info()

    build_client()
    |> Tesla.request(
      url: "/signin",
      method: :post,
      body: %{username: username, password: password},
      headers: [{"device-id", "TCLRS7LZQSJD5ULC"}]
    )
    |> case do
      {:ok, %{status: 200, body: %{"data" => data}} = env} ->
        req_id = Tesla.get_header(env, "f-request-id")
        r = Tesla.get_header(env, "r-token")

        spec = Tesla.get_header(env, "f-token-spec") |> Base.decode64!()
        [_, format] = String.split(spec, "sha-256-b64-np")


        # TODO: dynamically parse f-token
        message = req_id <> format

        {:ok, data, %{f_token: f_token(message), r_token: r}}

      error ->
        ParseError.call(error)
    end
  end

  def signin_mfa(mfa, r_token, f_token) do
    build_client()
    |> Tesla.request(
      url: "/signin/mfa",
      method: :post,
      body: %{device_id: List.first(mfa["devices"])["id"]},
      headers: [
        {"device-id", "TCLRS7LZQSJD5ULC"},
        {"teller-mission", "accepted!"},
        {"r-token", r_token},
        {"f-token", f_token}
      ]
    )
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

  defp f_token(message), do: :crypto.hash(:sha256, message) |> Base.encode64(padding: false)

  def parse_response(request) do
    case request do
      {:ok, %{status: 200, body: %{"data" => data}}} -> {:ok, data}
      error -> ParseError.call(error)
    end
  end

  defp base_url, do: Application.get_env(:mini_teller, :base_url)
end
