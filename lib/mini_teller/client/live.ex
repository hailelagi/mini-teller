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
      # do not log sensitive info
      {Tesla.Middleware.Logger, filter_headers: ~w[api-key device-id r-token f-token]},
      # todo(debug): Tesla.Middleware.Logger,
      Tesla.Middleware.Telemetry
    ]

    Tesla.client(middleware, {Tesla.Adapter.Finch, name: MiniTeller.Finch})
  end

  def enroll() do
    # Session.establish()
    # %{device_id: id} = Session.info()

    with {:ok, devices, %{f_token: f, r_token: r}} <- signin("yellow_angel", "saudiarabia"),
         {:ok, id} <- select_device(devices),
         {:ok, data} <- signin_mfa(id, r, f) do
      data
    else
      err -> err
    end
  end

  def signin(username, password) do
    device_id = "TCLRS7LZQSJD5ULC"

    build_client()
    |> Tesla.request(
      url: "/signin",
      method: :post,
      body: %{username: username, password: password},
      headers: [{"device-id", device_id}]
    )
    |> case do
      {:ok, %{status: 200, body: %{"data" => data}} = env} ->
        req_id = Tesla.get_header(env, "f-request-id")
        r = Tesla.get_header(env, "r-token")

        spec = Tesla.get_header(env, "f-token-spec") |> Base.decode64!()
        [_, format] = String.split(spec, ~r{sha-256-b64-np\(})
        [format, _] = String.split(format, ")")

        format = String.split(format, "-") |> Enum.join("")
        [seperator] = Regex.run(~r/[[:punct:]]+/, format)

       message =
        String.split(format, seperator)
        |> Enum.map(&order_hash(&1, device_id, req_id, username))
        |> Enum.join(seperator)

        {:ok, data, %{f_token: f_token(message), r_token: r}}

      error ->
        ParseError.call(error)
    end
  end

  defp order_hash(spec, device_id, req_id, username) do
    case spec do
      "deviceid" -> device_id
      "lastrequestid" -> req_id
      "username" -> username
      "apikey" -> Application.get_env(:mini_teller, :api_key)
    end
  end

  def signin_mfa(id, r_token, f_token) do
    build_client()
    |> Tesla.request(
      url: "/signin/mfa",
      method: :post,
      body: %{device_id: id},
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

  defp select_device(%{"devices" => devices}) do
    # todo: refactor call from controller
    {:ok, List.first(devices)["id"]}
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
