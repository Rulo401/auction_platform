defmodule AuctionSystem.Tasks.FilterList do
  alias AuctionSystem.Schemas.{Category}
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
end
