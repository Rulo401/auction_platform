defmodule AuctionSystem.Schemas.User do
  use Ecto.Schema

  schema "user" do
    field :nickname, :string
    field :balance, :float, default: 0
    field :freezed, :float, default: 0
  end
end
