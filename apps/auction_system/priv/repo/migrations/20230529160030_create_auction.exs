defmodule AuctionSystem.Repo.Migrations.CreateAuction do
  use Ecto.Migration

  def change do
    create table(:auctions) do
      add :seller_id, references(:users), null: false
      add :item_id, references(:items), null: false
      add :bidder_id, references(:users)
      add :minBid, :float, null: false
      add :bid, :float
      add :end, :naive_datetime, null: false
      add :paid, :boolean, default: false
    end
  end
end
