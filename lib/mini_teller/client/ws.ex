defmodule MiniTeller.Client.Ws do
  use WebSockex

  def start(url, _), do: WebSockex.start(url, __MODULE__, nil)

    # ["4","8","lv:phx-Fx8cHq_shkB7LAdx","event",{"type":"click","event":"open_settings","value":{}}]

  def handle_frame({type, msg}, state) do
    IO.puts "Received Message - Type: #{inspect type} -- Message: #{inspect msg}"
    {:ok, state}
  end
end
