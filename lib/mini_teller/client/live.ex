defmodule MiniTeller.Client.Live do
  @moduledoc """
    Live teller.io sandbox api
    eg.
    MiniTeller.Client.Live.signin("yellow_angel", "saudiarabia")
        MiniTeller.Client.Live.signin("yellow_angel", "saudiarabia")
    MiniTeller.Client.Live.enroll()

    account number
    available balance in cents
    Oldest transaction amount
  """

  @behaviour MiniTeller.Client

  alias MiniTeller.Client.{ParseError, Session, Token}

  require Logger

  def build_client do
    middleware = [
      {Tesla.Middleware.BaseUrl, base_url()},
      {Tesla.Middleware.Timeout, timeout: 30_000},
      Tesla.Middleware.JSON,
      MiniTeller.Client.IOS,
      # do not log sensitive info
      # {Tesla.Middleware.Logger, filter_headers: ~w[api-key device-id r-token f-token s-token]},
      Tesla.Middleware.Logger,
      Tesla.Middleware.Telemetry
    ]

    Tesla.client(middleware, {Tesla.Adapter.Finch, name: MiniTeller.Finch})
  end

  def enroll() do
    Session.cache_device("TCLRS7LZQSJD5ULC")
    username = Application.get_env(:mini_teller, :username)
    password = Application.get_env(:mini_teller, :password)

    with {:ok, %{"devices" => devices}} <- signin(username, password),
         {:ok, _} <- signin_mfa(List.first(devices)["id"]),
         {:ok, %{body: %{"data" => data}} = env} <- verify("123456"),
         {:ok, _result} <- Token.decrypt_a_token(data["a_token"], data["enc_key"]) do
      {:ok, env}
    else
      err -> err
    end
  end

  def signin(username, password) do
    build_client()
    |> Tesla.post("/signin", %{username: username, password: password})
    |> parse_response()
    |> case do
      {:ok, %{"data" => data}} -> {:ok, data}
      err -> err
    end
  end

  def signin_mfa(device_auth_id) do
    %{r_token: r_token, f_token: f_token} = Session.info()

    build_client()
    |> Tesla.request(
      url: "/signin/mfa",
      method: :post,
      body: %{device_id: device_auth_id},
      headers: [
        {"teller-mission", "accepted!"},
        {"r-token", r_token},
        {"f-token", f_token}
      ]
    )
    |> parse_response()
  end

  def verify(code) do
    %{r_token: r_token, f_token: f_token} = Session.info()

    build_client()
    |> Tesla.request(
      url: "/signin/mfa/verify",
      method: :post,
      body: %{code: code},
      headers: [
        {"teller-mission", "accepted!"},
        {"r-token", r_token},
        {"f-token", f_token}
      ]
    )
    |> case do
      {:ok, %{status: 200} = env} -> {:ok, env}
      error -> ParseError.call(error)
    end
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

  defp parse_response(request) do
    case request do
      {:ok, %{status: 200, body: body} = env} ->
        req_id = Tesla.get_header(env, "f-request-id")
        r_token = Tesla.get_header(env, "r-token")
        f_token = Tesla.get_header(env, "f-token-spec") |> Token.create_f_token(req_id)

        Session.store_header(req_id, f_token, r_token)
        {:ok, body}

      error ->
        ParseError.call(error)
    end
  end

  defp base_url, do: Application.get_env(:mini_teller, :base_url)
end
