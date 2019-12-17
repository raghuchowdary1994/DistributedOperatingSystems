defmodule Twitterengine.Repo do
  use Ecto.Repo,
    otp_app: :twitterengine,
    adapter: Ecto.Adapters.Postgres
end
