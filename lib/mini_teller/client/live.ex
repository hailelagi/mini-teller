defmodule MiniTeller.Client.Live do
  @moduledoc """
    Live teller.io sandbox api eg.
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
      {Tesla.Middleware.Logger, filter_headers: ~w[api-key device-id r-token f-token s-token]},
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
         {:ok, s_token} <- Token.generate_s_token(data["enc_key"], env),
         {:ok, env} <- account(:details, data["accounts"], s_token) do
      env
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
      {:ok, %{status: 200, body: %{"data" => data}} = env} ->
        Session.cache_auth(data["a_token"])

        {:ok, env}

      error ->
        ParseError.call(error)
    end
  end

  def reauthenticate do
    %{a_token: a_token} = Session.info()

    build_client()
    |> Tesla.post("/signin/token", %{token: a_token})
    |> parse_response()
  end

  def account(type, %{"checking" => acc}, s_token) do
    id = List.first(acc)["id"]
    %{r_token: r_token, f_token: f_token} = Session.info()

    url =
      case type do
        :details -> "accounts/#{id}/details"
        :balances -> "accounts/#{id}/balances"
      end

    build_client()
    |> Tesla.request(
      url: url,
      method: :get,
      headers: [
        {"r-token", r_token},
        {"f-token", f_token},
        {"s-token", s_token},
        {"teller-mission", "accepted!"}
      ]
    )
    |> case do
      {:ok, data} -> {:ok, data}
      err -> err
    end
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
