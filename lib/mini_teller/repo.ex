defmodule MiniTeller.Repo do
  use Ecto.Repo,
    otp_app: :mini_teller,
    adapter: Ecto.Adapters.Postgres
end
