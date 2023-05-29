defmodule AuctionSystemTest.Servers.CreditServerTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Servers.CreditServer
  alias AuctionSystem.Schemas.User
  doctest CreditServer

  setup do
    {_, pid} = GenServer.start_link(CreditServer, nil)
    {:ok, server: pid}
  end

  test "Balance", state do
    init_size = length(User |> Repo.all)

    # Create a user for testing
    user = %User{nickname: "TestUser"}

    # Save the user record to the database
    {:ok, user} = Repo.insert(user)

    #Check the size of the database
    assert init_size + 1 == length(User |> Repo.all)

    # Get the user's balance
    assert {:ok, 0} == GenServer.call(state.server, {:balance, user.id}, :infinity)

    #Test with a user that doesn´t exists
    Repo.delete(user)
    assert {:error, "User not found"} == GenServer.call(state.server, {:balance, user.id}, :infinity)
  end

  test "Deposit", state do
    init_size = length(User |> Repo.all)

    # Create a user for testing
    user = %User{nickname: "TestUser"}

    # Save the user record to the database
    {:ok, user} = Repo.insert(user)

    #Check the size of the database
    assert init_size + 1 == length(User |> Repo.all)

    # Deposit amount into the user's account
    assert {:ok, 100} == GenServer.call(state.server, {:deposit, user.id, 100}, :infinity)

  end

  test "Withdraw", state do
    init_size = length(User |> Repo.all)

    # Create a user for testing
    user = %User{nickname: "TestUser"}

    # Save the user record to the database
    {:ok, user} = Repo.insert(user)

    #Check the size of the database
    assert init_size + 1 == length(User |> Repo.all)

    # Deposit amount into the user's account
    GenServer.call(state.server, {:deposit, user.id, 100}, :infinity)

    # Withdraw amount from the user's account
    assert {:ok, 50} == GenServer.call(state.server, {:withdraw, user.id, 50}, :infinity)

  end
end
