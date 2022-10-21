defmodule MiniTeller.Client.Live do
  @moduledoc """
    Live teller.io sandbox api
    eg. MiniTeller.Client.Live.signin("yellow_angel", "saudiarabia")
    MiniTeller.Client.Live.enroll()
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
      # {Tesla.Middleware.Logger, filter_headers: ~w[api-key device-id r-token f-token body]},
      Tesla.Middleware.Logger,
      Tesla.Middleware.Telemetry
    ]

    Tesla.client(middleware, {Tesla.Adapter.Finch, name: MiniTeller.Finch})
  end

  # def enroll() do
  #   # todo: create Session.establish()
  #   Session.cache_device("TCLRS7LZQSJD5ULC")

  #   with {:ok, devices, %{f_token: f, r_token: r}} <- signin("yellow_angel", "saudiarabia"),
  #        {:ok, id} <- select_device(devices),
  #        :ok <- signin_mfa(id, r, f) do
  #     {:ok, "success"}
  #   else
  #     err -> err
  #   end
  # end

  def signin(username, password) do
    build_client()
    |> Tesla.post("/signin", %{username: username, password: password})
    |> case do
      {:ok, %{status: 200, body: %{"data" => data}} = env} ->
        req_id = Tesla.get_header(env, "f-request-id")
        r_token = Tesla.get_header(env, "r-token")
        f_token = Tesla.get_header(env, "f-token-spec") |> Token.create_f_token(req_id)

        Session.store_header(req_id, f_token, r_token)
        {:ok, data}

      error ->
        ParseError.call(error)
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
    |> case do
      {:ok, %{status: 200} = env} ->
        req_id = Tesla.get_header(env, "f-request-id")
        r_token = Tesla.get_header(env, "r-token")
        f_token = Tesla.get_header(env, "f-token-spec") |> Token.create_f_token(req_id)

        Session.store_header(req_id, f_token, r_token)
        :ok

      error ->
        ParseError.call(error)
    end
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
      {:ok, %{status: 200}} -> :ok
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

  defp select_device(%{"devices" => devices}) do
    # todo: refactor call from controller
    {:ok, List.first(devices)["id"]}
  end

  def parse_response(request) do
    case request do
      {:ok, %{status: 200, body: %{"data" => data}}} -> {:ok, data}
      error -> ParseError.call(error)
    end
  end

  defp base_url, do: Application.get_env(:mini_teller, :base_url)
end
