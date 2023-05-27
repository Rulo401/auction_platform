import Config

config :auction_system, AuctionSystem.Repo,
  database: "auction",
  username: "auction_system",
  password: "auction_system",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
