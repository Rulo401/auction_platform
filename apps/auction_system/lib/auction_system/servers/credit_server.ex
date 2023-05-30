defmodule AuctionSystem.Servers.CreditServer do
  use GenServer
  alias AuctionSystem.Schemas.User
  alias AuctionSystem.Repo
  alias Ecto.Multi
  import Ecto.Query

  @spec init(any) :: {:ok, nil}
  def init(_) do
    {:ok, nil}
  end

  def handle_call({:deposit, user_id, amount}, _, state) when amount > 0 do
    transaction = Multi.new()
    |> Multi.one(:user, (from u in User, where: u.id == ^user_id))
    |> Multi.update(:deposit, fn %{user: user} -> Ecto.Changeset.change(user, balance: user.balance + amount) end)
    |> Repo.transaction()

    case transaction do
      {:ok, changes} ->
        {:reply, {:ok, changes.user.balance + amount}, state}
      {:error, _, _, _} ->
        {:reply, {:error, "Database error"}, state}
    end
  end

  def handle_call({:deposit, _user_id, _amount}, _, state) do
    {:reply, {:error, "Deposit amount must be a positive integer"}, state}
  end

  def handle_call({:withdraw, user_id, amount}, _, state) when amount > 0 do
    case Repo.transaction(fn() -> withdraw_transaction(user_id,amount) end) do
      {:ok, {:ok, user}} ->
        balance = user.balance
        {:reply, {:ok, balance}, state}

      {:ok,{:error,:insufficient_balance}} ->
          {:reply, {:error, "Insufficient balance"}, state}

      {:ok,{:error, _}} ->
        {:reply, {:error, "Database error"}, state}

    end
  end

  def handle_call({:withdraw, _user_id, _amount}, _, state) do
    {:reply, {:error, "Withdraw amount must be a positive integer"}, state}
  end

  def handle_call({:balance, user_id}, _, state) do
    case User |> Repo.get(user_id) do
      nil ->
        {:reply,{:error,"User not found"}, state}
      user ->
        {:reply, {:ok, user.balance}, state}
    end
  end

  defp withdraw_transaction(user_id,amount) do
    query = from u in User, where: u.id == ^user_id and u.balance >= ^amount
    case Repo.one(query) do
      nil ->
        {:error,:insufficient_balance}
      user ->
        changeset = Ecto.Changeset.change(user,(%{balance: user.balance - amount}))
        Repo.update(changeset)
    end
  end
end
