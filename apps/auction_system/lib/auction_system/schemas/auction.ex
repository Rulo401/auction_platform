defmodule AuctionSystem.Schemas.Auction do
  use Ecto.Schema
  alias AuctionSystem.Schemas.User
  alias AuctionSystem.Schemas.Item
  import Ecto.Changeset

  schema "auctions" do
    belongs_to :seller, User
    belongs_to :item, Item
    belongs_to :bidder, User
    field :minBid, :float, default: 0.1
    field :bid, :float
    field :end, :naive_datetime
    field :paid, :boolean, default: false
  end

  def changeset(auction, params \\ %{}) do
    auction
    |> cast(params, [:bidder, :bid, :end, :paid])
    |> validate_required([:seller, :item, :minbid, :end, :paid])
  end
end
