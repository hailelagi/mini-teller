defmodule MiniTeller.Client do
  @moduledoc """
    Build your own client that will allow you to:
     enroll, reauthenticate, list accounts and list transactions
  """

  @callback enroll() ::  {:ok, binary()}
  @callback reauthenticate() :: {:ok, binary()}
  @callback accounts() :: {:ok, binary()}
  @callback transactions() :: {:ok, nil}

  def enroll(), do: impl().enroll()
  def reauthenticate(), do: impl().reauthenticate()
  def accounts(), do: impl().accounts()
  def transactions(), do: impl().transactions()

  defp impl, do: Application.get_env(:mini_teller, :client, MiniTeller.Live)
end
