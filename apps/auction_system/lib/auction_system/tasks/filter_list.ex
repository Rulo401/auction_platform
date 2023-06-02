defmodule AuctionSystem.Tasks.FilterList do
  alias AuctionSystem.Schemas.{Category, Weapon, Skin}
  alias AuctionSystem.Repo
  import Ecto.Query

  @spec list_categories(from :: pid | GenServer.from()) :: :ok
  def list_categories(from) do
    query = from c in Category, select: {c.id, c.name}, order_by: [asc: c.id]
    stream = Repo.stream(query)
    transaction = Repo.transaction(fn -> Enum.to_list(stream) end)

    response =
      case transaction do
        {_, []} ->
          {:error, "No categories listed"}
        {_, categories} ->
          {:ok, categories}
      end
    answer(from, response)
  end

  @spec list_weapons(from :: pid | GenServer.from(), category_id :: integer) :: :ok
  def list_weapons(from,category_id) do
    query = from w in Weapon, where: w.category_id == ^category_id, select: {w.id, w.name}, order_by: [asc: w.id]
    stream = Repo.stream(query)
    transaction = Repo.transaction(fn -> Enum.to_list(stream) end)

    response =
      case transaction do
        {_, []} ->
          {:error, "Invalid category or No weapons for that category"}
        {_, weapons} ->
          {:ok, weapons}
      end
    answer(from, response)
  end

  @spec list_skins(from :: pid | GenServer.from(), weapon_id :: integer) :: :ok
  def list_skins(from, weapon_id)do
    query = from s in Skin, where: s.weapon_id == ^weapon_id, select: {s.id, s.name}, order_by: [asc: s.id]
    stream = Repo.stream(query)
    transaction = Repo.transaction(fn -> Enum.to_list(stream) end)

    response =
      case transaction do
        {_, []} ->
          {:error, "Invalid weapon or No skins for that weapon"}
        {_, skins} ->
          {:ok, skins}
      end
    answer(from, response)
  end

  defp answer(from, response) when is_pid(from) do
    send(from, {:test, response})
    :ok
  end

  defp answer(from, response) do
    GenServer.reply(from, response)
  end

end
