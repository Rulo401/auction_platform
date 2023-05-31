defmodule AuctionSystem.Schemas.Auction do
  use Ecto.Schema
  alias AuctionSystem.Repo
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
    |> Repo.preload(:bidder)
    |> cast(params, [:bidder_id, :bid, :end, :paid])
    |> validate_required([:seller_id, :item_id, :minBid, :end, :paid])
  end
end
