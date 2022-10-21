defmodule MiniTeller.Client.IOS do
  @moduledoc """
    Teller iOS Mobile device headers
  """

  @behaviour Tesla.Middleware

  alias MiniTeller.Client.Session

  @impl Tesla.Middleware
  def call(env, next, _options) do
    %{device_id: device_id} = Session.info()

    env
    |> Tesla.put_headers([
      {"user-agent", "Teller Bank iOS 2.0"},
      {"accept", "application/json"},
      {"api-key", Application.get_env(:mini_teller, :api_key)},
      {"device-id", device_id}
    ])
    |> Tesla.run(next)
  end
end
