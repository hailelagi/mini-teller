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
    Agent.start_link(fn -> %{key: nil, token: nil, device_id: nil} end, name: __MODULE__)
  end
  def info, do: Agent.get(__MODULE__, & &1)
  def establish do
    with {:ok, %Tesla.Env{} = env} <- Tesla.request(method: :get, url: base_url()),
         {:ok, document} <- Floki.parse_document(env.body) do
      request_id = Tesla.get_header(env, "x-request-id")
      Logger.warn("[mini_teller] is establishing a new session #{request_id}")

      cookie = Tesla.get_header(env, "set-cookie")
      [session_key, _path, _method] = String.split(cookie, ";")

      IO.inspect(session_key)
      ["_bank_job_key", key] = String.split(session_key, "=")
      [{"meta", [{"content", token}, _], _}] = Floki.find(document, "meta[name='csrf-token']")

      Agent.update(__MODULE__, fn _ -> %{key: key, token: token, device_id: nil} end)
    else
      error -> ParseError.call(error)
    end
  end

  def test do
    Session.establish()
    %{key: key} = Session.info()
    Joken.peek_claims(key)
    # {:ok, jwt} = Joken.expand(key)
  end

  @spec device_id :: {:error, any} | {:ok, pid}
  def device_id do
    Session.establish()
    %{token: token} = Session.info()

    # ["4","4","lv:phx-Fx8e1m5POtAc1gpB",
    # "phx_join",{"url":"https://test.teller.engineering/",
    # "params":{"_csrf_token":"KzgLKBQ1ACMsHQcFKgldGiYTFQgYf1ojioeIXoupOwPcN13vIjwLj8-V","
    # _track_static":["https://test.teller.engineering/assets/app-79148234bf1b30d62b2e5f2a9bed082d.css?vsn=d",
    # "https://test.teller.engineering/assets/app-fc7eb2b4b0cf2496408462484996946c.js?vsn=d"],"_mounts":0},
    # "session":"SFMyNTY.g2gDaAJhBXQAAAAIZAACaWRtAAAAFHBoeC1GeDhlMW01UE90QWMxZ3BCZAAMbGl2ZV9zZXNzaW9uaAJkAAdkZWZhdWx0bggAF6TMM1PVHhdkAApwYXJlbnRfcGlkZAADbmlsZAAIcm9vdF9waWRkAANuaWxkAAlyb290X3ZpZXdkABpFbGl4aXIuQmFua0pvYldlYi5NYWluTGl2ZWQABnJvdXRlcmQAGEVsaXhpci5CYW5rSm9iV2ViLlJvdXRlcmQAB3Nlc3Npb250AAAAAGQABHZpZXdkABpFbGl4aXIuQmFua0pvYldlYi5NYWluTGl2ZW4GAGHLXOqDAWIAAVGA.dIw2msn6XXb2ncU5L88as6ZCLYFF3bqOTFp8wRG0WM8",
    # "static":"SFMyNTY.g2gDaAJhBXQAAAADZAAKYXNzaWduX25ld2pkAAVmbGFzaHQAAAAAZAACaWRtAAAAFHBoeC1GeDhlMW01UE90QWMxZ3BCbgYAYctc6oMBYgABUYA.Y5HqDrAG91s40Dpa2sYYAc2uPTG0PouIRq1dCIYFwwg"}]
    # # ["4","14","lv:phx-Fx8e1m5POtAc1gpB","event",{"type":"click","event":"open_settings","value":{}}]

    Ws.start_link("wss://test.teller.engineering/live/websocket?_csrf_token=#{token}", %{})

    # ["4","4","lv:phx-Fx8rAZegSHLO6Qzh","phx_join",{"url":"https://test.teller.engineering/","params":{"_csrf_token":"HTw-MTkQGWUtAWYUSW84CigdFRQIDCAX_kPPuJl6Nk1r-WVfGdwPzKWb","_track_static":["https://test.teller.engineering/assets/app-79148234bf1b30d62b2e5f2a9bed082d.css?vsn=d","https://test.teller.engineering/assets/app-fc7eb2b4b0cf2496408462484996946c.js?vsn=d"],"_mounts":0},"session":"SFMyNTY.g2gDaAJhBXQAAAAIZAACaWRtAAAAFHBoeC1GeDhyQVplZ1NITE82UXpoZAAMbGl2ZV9zZXNzaW9uaAJkAAdkZWZhdWx0bggAF6TMM1PVHhdkAApwYXJlbnRfcGlkZAADbmlsZAAIcm9vdF9waWRkAANuaWxkAAlyb290X3ZpZXdkABpFbGl4aXIuQmFua0pvYldlYi5NYWluTGl2ZWQABnJvdXRlcmQAGEVsaXhpci5CYW5rSm9iV2ViLlJvdXRlcmQAB3Nlc3Npb250AAAAAGQABHZpZXdkABpFbGl4aXIuQmFua0pvYldlYi5NYWluTGl2ZW4GAB3zKOuDAWIAAVGA.yeJqxnV74tpKTpgS4kc67i1fiv4tHvv7MhUnli6eoJE","static":"SFMyNTY.g2gDaAJhBXQAAAADZAAKYXNzaWduX25ld2pkAAVmbGFzaHQAAAAAZAACaWRtAAAAFHBoeC1GeDhyQVplZ1NITE82UXpobgYAHfMo64MBYgABUYA.9pcvM1Otw3ZYVk6emxWCs-73apFxSrx5Y3jAPj76VhI"}]
    # todo: ws:// connection + csrf
  end

  defp base_url, do: Application.get_env(:mini_teller, :base_url)
end
