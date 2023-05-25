defmodule AuctionSystem.Repo do
  use Ecto.Repo,
    otp_app: :auction_system,
    adapter: Ecto.Adapters.Postgres
end
