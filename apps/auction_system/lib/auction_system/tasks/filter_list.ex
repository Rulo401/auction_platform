defmodule AuctionSystem.Tasks.Filterlist do
  alias AuctionSystem.Schemas.{Category, Skin, Weapon}
  alias AuctionSystem.Repo
  import Ecto.Query


  def list_categories(pid,cid) do
    response = case Repo.all(from c in Category) do
      [] ->
        {:error, "Database error"}
      categories ->
        {:ok, categories}
    end
    send(pid, {:market, cid, response})
  end
end
