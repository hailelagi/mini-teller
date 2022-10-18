defmodule MiniTeller.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MiniTeller.Repo,
      MiniTellerWeb.Telemetry,
      {Phoenix.PubSub, name: MiniTeller.PubSub},
      MiniTellerWeb.Endpoint,
      {Finch, name: MiniTeller.Finch},
      {MiniTeller.Client.Session, nil}
    ]

    opts = [strategy: :one_for_one, name: MiniTeller.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MiniTellerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
