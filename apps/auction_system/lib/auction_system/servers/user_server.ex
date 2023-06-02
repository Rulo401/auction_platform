defmodule AuctionSystem.Servers.UserServer do
  use GenServer
  alias AuctionSystem.Schemas.User
  alias AuctionSystem.Repo
  @type method() :: :create | :delete | :update

  @spec start_link(any) :: Supervisor.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec init(any) :: {:ok, map()}
  def init(_) do
    db_users =  User |> Repo.all
    users = Map.new(db_users, fn x -> {x.nickname, x.id} end)
    {:ok, users}
  end

  @spec handle_call({method(), username :: String.t() }, any, map()) :: {:reply, {:ok, user_id :: integer}, map()}
  def handle_call({:create, username}, _, state) do
    cond do
      not is_binary(username) ->
        {:reply, {:error,"Invalid username"}, state}
      Map.has_key?(state, username) ->
        {:reply, {:error,"Username already exists"}, state}
      true ->
        user = %User{nickname: username}
        case Repo.insert(user) do
          {:ok, user} ->
            {:reply, {:ok, user.id}, Map.put_new(state, username, user.id)}
          _ ->
            {:reply, {:error,"Database error"}, state}
        end
    end
  end

  def handle_call({:delete, username}, _, state) do
    case Map.get(state, username) do
      nil ->
        {:reply, {:error,"Username not found"}, state}
      id ->
        case User |> Repo.get(id) do
          nil ->
            {:reply, {:error,"Deleted user"}, Map.delete(state, username)}
          user when user.balance == 0 and user.freezed == 0 ->
            case Repo.delete(user) do
              {:ok, _} ->
                {:reply, :ok, Map.delete(state, username)}
              {:error, _} ->
                {:reply, {:error,"Database error"}, state}
            end
          user ->
            {:reply, {:error,"Unable to delete an account with balance (#{inspect(user.balance)}, #{inspect(user.freezed)})"}, state}
        end
    end
  end

  def handle_call({:login, username}, _, state) do
    case Map.get(state, username) do
      nil ->
        {:reply, {:error,"Username not found"}, state}
      id ->
        {:reply, {:ok, id}, state}
    end
  end
end
