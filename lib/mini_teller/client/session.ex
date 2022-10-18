defmodule MiniTeller.Client.Session do
  @moduledoc """
    Establish a new teller bank client session,
    store the client cookie and configure the client device's environment.
  """
  use Agent

  alias MiniTeller.Client.ParseError
  require Logger

  def init(_), do: {:ok, nil}

  def start_link(_) do
    Agent.start_link(fn -> %{cookie: nil, device_id: nil} end, name: __MODULE__)
  end

  def info, do: Agent.get(__MODULE__, & &1)

  def establish do
    case Tesla.request(method: :get, url: base_url()) do
      {:ok, %Tesla.Env{} = env} ->
        request_id = Tesla.get_header(env, "x-request-id")
        Logger.warn("[mini_teller] is establishing a new session #{request_id}")

        cookie = Tesla.get_header(env, "set-cookie")
        id = nil

        Agent.update(__MODULE__, fn _ -> %{cookie: cookie, device_id: id} end)

      error ->
        ParseError.call(error)
    end
  end

  defp base_url, do: Application.get_env(:mini_teller, :base_url)
end
