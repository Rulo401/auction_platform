defmodule AuctionSystem.Tasks.AuctionList do
  alias AuctionSystem.Schemas.{Auction}
  alias AuctionSystem.Repo
  import Ecto.Query

  def list_auctions(pid, cid, :all) do
    response = case Repo.all(from a in Auction, select: a.id, order_by: [asc: a.id]) do
      [] ->
        {:error, "No auctions listed"}
      auctions ->
        {:ok, auctions}
    end
    send(pid, {:market, cid, response})
  end

  def list_auctions(_pid, _cid, :category, _category_id) do
    nil
  end

  def list_auctions(_pid, _cid, :weapon, _weapon_id) do
    nil
  end

  def list_auctions(_pid, _cid, :skin, _skin_id) do
    nil
  end
end
