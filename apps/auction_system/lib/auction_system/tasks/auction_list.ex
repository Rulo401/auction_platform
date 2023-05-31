defmodule AuctionSystem.Tasks.AuctionList do
  alias AuctionSystem.Schemas.Weapon
  alias AuctionSystem.Schemas.{Auction, Item, Skin, Weapon}
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

  def list_auctions(pid, cid, :category, category_id) do
    query =
      from(a in Auction,
        join: i in Item, on: a.item_id == i.id,
        join: s in Skin, on: i.skin_id == s.id,
        join: w in Weapon, on: s.weapon_id == w.id,
        where: w.category_id == ^category_id,
        select: a.id
      )
    response = case Repo.all(query) do
      [] ->
        {:error, "Invalid category or No auctions listed for that category"}
      auctions ->
        {:ok, auctions}
    end
    send(pid, {:market, cid, response})
  end

  def list_auctions(pid, cid, :weapon, weapon_id) do
    query =
      from(a in Auction,
        join: i in Item, on: a.item_id == i.id,
        join: s in Skin, on: i.skin_id == s.id,
        where: s.weapon_id == ^weapon_id,
        select: a.id
      )
    response = case Repo.all(query) do
      [] ->
        {:error, "Invalid weapon or No auctions listed for that weapon"}
      auctions ->
        {:ok, auctions}
    end
    send(pid, {:market, cid, response})
  end

  def list_auctions(pid, cid, :skin, skin_id) do
    query =
      from(a in Auction,
        join: i in Item, on: a.item_id == i.id,
        where: i.skin_id== ^skin_id,
        select: a.id
      )
    response = case Repo.all(query) do
      [] ->
        {:error, "Invalid skin or No auctions listed for that skin"}
      auctions ->
        {:ok, auctions}
    end
    send(pid, {:market, cid, response})
  end
end
