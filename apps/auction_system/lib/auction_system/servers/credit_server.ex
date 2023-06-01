defmodule AuctionSystem.Servers.CreditServer do
  use GenServer
  alias AuctionSystem.Schemas.User
  alias AuctionSystem.Repo
  alias Ecto.Multi
  alias AuctionSystem.Tasks.Balance
  import Ecto.Query

  def start_link([supervisor]) do
    GenServer.start_link(__MODULE__, supervisor, name: __MODULE__)
  end

  @impl true
  def init(supervisor) do
    {:ok, supervisor}
  end

  @impl true
  def handle_call({:deposit, user_id, amount}, _, supervisor) when amount > 0 do
    transaction = Multi.new()
    |> Multi.one(:user, (from u in User, where: u.id == ^user_id))
    |> Multi.update(:deposit, fn %{user: user} -> Ecto.Changeset.change(user, balance: user.balance + amount) end)
    |> Repo.transaction()

    case transaction do
      {:ok, changes} ->
        {:reply, {:ok, changes.user.balance + amount}, supervisor}
      {:error, _, _, _} ->
        {:reply, {:error, "Database error"}, supervisor}
    end
  end

  def handle_call({:deposit, _user_id, _amount}, _, supervisor) do
    {:reply, {:error, "Deposit amount must be a positive float"}, supervisor}
  end

  def handle_call({:withdraw, user_id, amount}, _, supervisor) when amount > 0 do
    case Repo.transaction(fn() -> withdraw_transaction(user_id,amount) end) do
      {:ok, {:ok, user}} ->
        balance = user.balance
        {:reply, {:ok, balance}, supervisor}

      {:ok,{:error,:insufficient_balance}} ->
          {:reply, {:error, "Insufficient balance"}, supervisor}

      {:ok,{:error, _}} ->
        {:reply, {:error, "Database error"}, supervisor}

    end
  end

  def handle_call({:withdraw, _user_id, _amount}, _, supervisor) do
    {:reply, {:error, "Withdraw amount must be a positive float"}, supervisor}
  end

  def handle_call({:balance, user_id}, _, nil) do
    case User |> Repo.get(user_id) do
      nil ->
        {:reply,{:error,"User not found"}, nil}
      user ->
        {:reply, {:ok, user.balance}, nil}
    end
  end

  def handle_call({:balance, user_id}, from, supervisor) do
    list = Supervisor.which_children(supervisor)
    ds = Enum.find_value(list, fn x -> find_ds(x) end)
    DynamicSupervisor.start_child(ds, %{id: Balance, start: {Balance, :balance, [from, user_id]}, restart: :temporary})
    {:noreply, supervisor}
  end

  defp find_ds(x) do
    case x do
      {:balance_ds, child, :supervisor, _} ->
        child
      _ ->
        false
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
