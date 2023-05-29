defmodule AuctionSystem.Servers.CreditServer do
  use GenServer
  alias AuctionSystem.Schemas.User
  alias AuctionSystem.Repo
  alias Ecto.Multi

  @spec init(any) :: {:ok, nil}
  def init(_) do
    {:ok, nil}
  end

  def handle_call({:deposit, user_id, amount}, _, state) do
    transaction = Multi.new()
    |> Multi.one(:user, User, id: user_id)
    |> Multi.update(:deposit, fn %{user: user} -> Ecto.Changeset.change(user, balance: user.balance + amount) end)
    |> Repo.transaction()

    case transaction do
      {:ok, changes} ->
        {:reply, {:ok, changes.user.balance + amount}, state}
      {:error, _, _, _} ->
        {:reply, {:error, "Database error"}, state}
    end
  end
  #  result =
  #    Repo.transaction(fn ->
  #      Multi.new()
  #      |> Multi.run(:deposit, fn ->
  #        user = %User{id: user_id}
  #        new_balance = user.balance + amount
  #        case Multi.update(user, %{balance: new_balance}) do
  #          {:ok, _} ->
  #            {:ok, new_balance}
  #          _ ->
  #            {:error, "Database error"}
  #        end
  #      end)
  #    end)
#
  #  case result do
  #    {:ok, new_balance} ->
  #      {:reply, {:ok, new_balance}, state}
  #    {:error, error} ->
  #      {:reply, {:error, error, state}}
  #  end
#
  #end

  def handle_call({:withdraw, user_id, amount}, _, state) do
    transaction = Multi.new()
    |> Multi.one(:user, User, id: user_id)
    |> Multi.update(:deposit, fn %{user: user} -> Ecto.Changeset.change(user, balance: user.balance - amount) end)
    |> Repo.transaction()

    case transaction do
      {:ok, changes} ->
        {:reply, {:ok, changes.user.balance - amount}, state}
      {:error, _, _, _} ->
        {:reply, {:error, "Database error"}, state}
    end
  end

  def handle_call({:balance, user_id}, _, state) do
    case User |> Repo.get(user_id) do
      nil ->
        {:reply,{:error,"User not found"}, state}
      user ->
        {:reply, {:ok, user.balance}, state}
    end
  end
end
