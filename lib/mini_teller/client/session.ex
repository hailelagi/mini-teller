defmodule MiniTeller.Client.Session do
  @moduledoc """
    Establish a new teller bank client session,
    store the client cookie and configure the client device's environment.
  """
  use Agent

  alias MiniTeller.Client.{ParseError, Session, Ws}

  require Logger

  def init(_), do: {:ok, nil}

  def start_link(_) do
    Agent.start_link(fn -> %{key: nil, device_id: nil} end, name: __MODULE__)
  end

  def info, do: Agent.get(__MODULE__, & &1)

  def establish do
    with {:ok, %Tesla.Env{} = env} <- Tesla.request(method: :get, url: base_url()),
         {:ok, document} <- Floki.parse_document(env.body) do
      request_id = Tesla.get_header(env, "x-request-id")
      Logger.warn("[mini_teller] is establishing a new session #{request_id}")

      cookie = Tesla.get_header(env, "set-cookie")
      [session_key, _path, _method] = String.split(cookie, ";")

      ["_bank_job_key", key] = String.split(session_key, "=")
      [{"meta", [{"content", token}, _], _}] = Floki.find(document, "meta[name='csrf-token']")

      Agent.update(__MODULE__, fn _ -> %{key: key, token: token, device_id: nil} end)
    else
      error -> ParseError.call(error)
    end
  end

  defp base_url, do: Application.get_env(:mini_teller, :base_url)
end
