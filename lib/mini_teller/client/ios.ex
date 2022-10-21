defmodule MiniTeller.Client.IOS do
  @moduledoc """
    Teller iOS Mobile device headers
  """

  @behaviour Tesla.Middleware

  @impl Tesla.Middleware

  def call(env, next, _options) do
    env
    |> Tesla.put_headers([
      {"user-agent", "Teller Bank iOS 2.0"},
      {"accept", "application/json"},
      {"api-key", Application.get_env(:mini_teller, :api_key)},
    ])
    |> Tesla.run(next)
  end
end
