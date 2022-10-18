defmodule MiniTeller.Client.Ws do
  use WebSockex

  def start(url, _), do: WebSockex.start(url, __MODULE__, nil)

  def settings(client, _message) do
    WebSockex.send_frame(client, %{type: "click", event: "open_settings",value: {}})
  end

  def handle_frame({type, msg}, state) do
    # %{type: "click", event: "open_settings",value: {}}
    IO.puts("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
    {:ok, state}
  end

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

    Ws.start("wss://test.teller.engineering/live/websocket?_csrf_token=#{token}", %{})

    # todo: ws:// connection + csrf
  end
end
