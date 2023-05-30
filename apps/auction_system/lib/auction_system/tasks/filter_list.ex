defmodule AuctionSystem.Tasks.FilterList do
  alias AuctionSystem.Schemas.{Category, Weapon}
  alias AuctionSystem.Repo
  import Ecto.Query

  def list_categories(pid,cid) do
    response = case Repo.all(from c in Category, select: {c.id, c.name}, order_by: [asc: c.id]) do
      [] ->
        {:error, "No categories listed"}
      categories ->
        {:ok, categories}
    end
    send(pid, {:market, cid, response})
  end

  def list_weapons(pid,cid,category_id) do
    response = case Repo.all(from w in Weapon, where: w.category_id == ^category_id, select: {w.id, w.name}, order_by: [asc: w.id]) do
      [] ->
        {:error, "Invalid category or No weapons for that category"}
      weapons ->
        {:ok, weapons}
    end
    send(pid, {:market, cid, response})
  end

end
