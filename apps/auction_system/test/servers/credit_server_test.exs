defmodule AuctionSystemTest.Servers.CreditServerTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Servers.CreditServer
  alias AuctionSystem.Schemas.User
  doctest CreditServer

  setup do
    {_, pid} = GenServer.start_link(CreditServer, nil)
    init_size = length(User |> Repo.all)
    # Create four users for testing
    users = [
      user1: %User{nickname: "TestUser1", balance: 20.0},
      user2: %User{nickname: "TestUser2"},
      user3: %User{nickname: "TestUser3"}
     ]

     # Save the user records to the database
     users_state = users
     |> Enum.map(fn {k,u} ->
        {:ok, user} = Repo.insert(u)
        {k,user}
     end)
     |> Map.new()

    {:ok, %{users: users_state,server: pid, init_size: init_size}}
  end

  test "Balance", state do
    # Get the first user from the setup
    user1 = Map.get(state.users, :user1)

    #Check the size of the database
    assert state.init_size + 3 == length(User |> Repo.all)

    # Get the user's balance
    assert {:ok, 20} == GenServer.call(state.server, {:balance, user1.id}, :infinity)

    #Test with a user that doesn´t exists
    assert {:error, "User not found"} == GenServer.call(state.server, {:balance, -1}, :infinity)
  end

  test "Deposit", state do
    # Get the first and second user from the setup
    user1 = Map.get(state.users, :user1)
    user2 = Map.get(state.users, :user2)

    #Check the size of the database
    assert state.init_size + 3 == length(User |> Repo.all)

    # Deposit amount into the user1 account
    assert {:ok, 120} == GenServer.call(state.server, {:deposit, user1.id, 100}, :infinity)

    # Deposit amount into the user2 account
    assert {:ok, 50} == GenServer.call(state.server, {:deposit, user2.id, 50}, :infinity)

    # Deposit negative amount into the user1 account
    assert {:error, "Deposit amount must be a positive number"} == GenServer.call(state.server, {:deposit, user1.id, -25}, :infinity)
  end

  test "Withdraw", state do
    # Get the first and second user from the setup
    user1 = Map.get(state.users, :user1)
    user2 = Map.get(state.users, :user2)

    #Check the size of the database
    assert state.init_size + 3 == length(User |> Repo.all)

    # Withdraw amount from the user1 account
    assert {:ok, 5} == GenServer.call(state.server, {:withdraw, user1.id, 15}, :infinity)

    # Withdraw negative amount into the user1 account
    assert {:error, "Withdraw amount must be a positive number"} == GenServer.call(state.server, {:withdraw, user1.id, -25}, :infinity)

    # Withdraw amount from the user2 account with insufficient balance
    assert {:error, "Insufficient balance"} == GenServer.call(state.server, {:withdraw, user2.id, 50}, :infinity)
  end
end
