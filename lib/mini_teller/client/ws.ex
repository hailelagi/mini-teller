defmodule MiniTeller.Client.Ws do
  use WebSockex

  def start_link(url, _), do: WebSockex.start_link(url, __MODULE__, %{}, [])

  # def settings(client, _message) do
  #   WebSockex.send_frame(client, %{type: "click", event: "open_settings", value: {}})
  # end

  # ["4","6","lv:phx-Fx8reUdAmSwOLg1h","event",{"type":"click","event":"open_settings","value":{}}]

  def handle_frame({type, msg}, state) do
    # %{type: "click", event: "open_settings",value: {}}
    IO.puts("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")



    {:ok, state}
  end


  def handle_frame(type, msg, state) do
    # %{type: "click", event: "open_settings",value: {}}
    IO.puts("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")

    {:ok, state}
  end

end
