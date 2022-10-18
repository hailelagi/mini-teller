Mox.defmock(MiniTeller.Mock, for: MiniTeller.Client)
Application.put_env(:mini_teller, :client, MiniTeller.Mock)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(MiniTeller.Repo, :manual)
