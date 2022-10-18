defmodule MiniTeller.Client.IOS do
  @moduledoc """
    Teller iOS Mobile device headers middleware
  """

  @behaviour Tesla.Middleware

  @impl Tesla.Middleware
  @spec call(Tesla.Env.t(), maybe_improper_list, any) :: any
  def call(env, next, _options) do
    # todo: f
    env
    |> Tesla.put_headers([
      {"user-agent", "Teller Bank iOS 2.0"},
      {"api-key", "HowManyGenServersDoesItTakeToCrackTheBank?"},
      {"device-id", "225WADCDQNZM3CS3"}
    ])
    |> Tesla.run(next)
  end
end
