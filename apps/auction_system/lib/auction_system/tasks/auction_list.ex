defmodule AuctionSystem.Tasks.AuctionList do
  alias AuctionSystem.Schemas.Weapon
  alias AuctionSystem.Schemas.{Auction, Item, Skin, Weapon}
  alias AuctionSystem.Repo
  import Ecto.Query

  @spec list_auctions(pid | GenServer.from(), :all) :: :ok
  def list_auctions(from, :all) do
    query = from a in Auction, where: a.end > datetime_add(^NaiveDateTime.utc_now(),0,"second"), select: a.id, order_by: [asc: a.id]
    stream = Repo.stream(query)
    transaction = Repo.transaction(fn -> Enum.to_list(stream) end)

    response =
      case transaction do
        {_, []} ->
          {:error, "No auctions listed"}
        {_, stream} ->
          {:ok, stream}
      end
    answer(from, response)
  end

  @spec list_auctions(pid | GenServer.from(), :category, category_id :: integer) :: :ok
  def list_auctions(from, :category, category_id) do
    query =
      from(a in Auction,
        join: i in Item, on: a.item_id == i.id,
        join: s in Skin, on: i.skin_id == s.id,
        join: w in Weapon, on: s.weapon_id == w.id,
        where: w.category_id == ^category_id and a.end > datetime_add(^NaiveDateTime.utc_now(),0,"second"),
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
    answer(from, response)
  end

  @spec list_auctions(pid | GenServer.from(), :weapon, weapon_id :: integer) :: :ok
  def list_auctions(from, :weapon, weapon_id) do
    query =
      from(a in Auction,
        join: i in Item, on: a.item_id == i.id,
        join: s in Skin, on: i.skin_id == s.id,
        where: s.weapon_id == ^weapon_id and a.end > datetime_add(^NaiveDateTime.utc_now(),0,"second"),
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
    answer(from, response)
  end

  @spec list_auctions(pid | GenServer.from(), :skin, skin_id :: integer) :: :ok
  def list_auctions(from, :skin, skin_id) do
    query =
      from(a in Auction,
        join: i in Item, on: a.item_id == i.id,
        where: i.skin_id== ^skin_id and a.end > datetime_add(^NaiveDateTime.utc_now(),0,"second"),
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
    answer(from, response)
  end

  defp answer(from, response) when is_pid(from) do
    send(from, {:test, response})
  end

  defp answer(from, response) do
    GenServer.reply(from, response)
  end
end
