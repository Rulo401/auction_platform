defmodule AuctionSystem.Tasks.AuctionList do
  alias AuctionSystem.Schemas.Weapon
  alias AuctionSystem.Schemas.{Auction, Item, Skin, Weapon}
  alias AuctionSystem.Repo
  import Ecto.Query

  def list_auctions(pid, cid, :all) do
    query = from a in Auction, select: a.id, order_by: [asc: a.id]
    stream = Repo.stream(query)
    transaction = Repo.transaction(fn -> Enum.to_list(stream) end)

    response =
      case transaction do
        {_, []} ->
          {:error, "No auctions listed"}
        {_, stream} ->
          {:ok, stream}
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

    stream = Repo.stream(query)
    transaction = Repo.transaction(fn -> Enum.to_list(stream) end)

    response =
      case transaction do
        {_, []} ->
          {:error, "Invalid category or No auctions listed for that category"}
        {_, auctions} ->
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

    stream = Repo.stream(query)
    transaction = Repo.transaction(fn -> Enum.to_list(stream) end)

    response =
      case transaction do
        {_, []} ->
          {:error, "Invalid weapon or No auctions listed for that weapon"}
        {_, auctions} ->
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

    stream = Repo.stream(query)
    transaction = Repo.transaction(fn -> Enum.to_list(stream) end)

    response =
      case transaction do
        {_, []} ->
          {:error, "Invalid skin or No auctions listed for that skin"}
        {_, auctions} ->
          {:ok, auctions}
      end
      send(pid, {:market, cid, response})
  end
end
