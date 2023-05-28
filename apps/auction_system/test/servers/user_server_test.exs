defmodule AuctionSystemTest.Servers.UserServerTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Servers.UserServer
  alias AuctionSystem.Schemas.User
  doctest UserServer

  setup do
    {_,pid} = GenServer.start_link(UserServer, nil)
    {:ok, server: pid}
  end


  test "Creating users", state do
    init_size = length(User |> Repo.all)

    #Create user with invalid username
    {status, err} = GenServer.call(state.server,{:create, 14},:infinity)
    IO.puts("Error: #{inspect(err)}")
    assert :error == status

    #Create user1
    {status, id} = GenServer.call(state.server,{:create, "User1"},:infinity)
    IO.puts("ID : #{inspect(id)}")
    assert :ok == status

    #Check the size of the database
    assert init_size + 1 == length(User |> Repo.all)

    #Recreate user1
    {status, err} = GenServer.call(state.server,{:create, "User1"},:infinity)
    IO.puts("Error: #{inspect(err)}")
    assert :error == status

    #Create user2
    {status, id} = GenServer.call(state.server,{:create, "User2"},:infinity)
    IO.puts("ID : #{inspect(id)}")
    assert :ok == status

    #Check the size of the database
    assert init_size + 2 == length(User |> Repo.all)
  end

  test "Deleting users", state do
    init_size = length(User |> Repo.all)

    #Delete user who does not exist
    {status, err} = GenServer.call(state.server,{:delete, "User1"},:infinity)
    IO.puts("Error: #{inspect(err)}")
    assert :error == status

    #Check the size of the database
    assert init_size == length(User |> Repo.all)

    #Insert user for test
    {status, id} = GenServer.call(state.server,{:create, "User1"},:infinity)
    IO.puts("ID : #{inspect(id)}")
    assert :ok == status

    #Check the size of the database
    assert init_size + 1 == length(User |> Repo.all)

    #Delete user1
    assert :ok == GenServer.call(state.server,{:delete, "User1"},:infinity)

    #Check the size of the database
    assert init_size == length(User |> Repo.all)

    #Insert user for test
    {status, id} = GenServer.call(state.server,{:create, "User2"},:infinity)
    IO.puts("ID : #{inspect(id)}")
    assert :ok == status
    #Update user with balance
    User
    |> Repo.get(id)
    |> User.changeset(%{balance: 15})
    |> Repo.update()

    #Delete user with balance
    {status, err} = GenServer.call(state.server,{:delete, "User2"},:infinity)
    IO.puts("Error: #{inspect(err)}")
    assert :error == status


    #Insert user for test
    {status, id} = GenServer.call(state.server,{:create, "User3"},:infinity)
    IO.puts("ID : #{inspect(id)}")
    assert :ok == status
    #Update user with freezed balance
    User
    |> Repo.get(id)
    |> User.changeset(%{freezed: 1.3})
    |> Repo.update()

    #Delete user with freezed balance
    {status, err} = GenServer.call(state.server,{:delete, "User3"},:infinity)
    IO.puts("Error: #{inspect(err)}")
    assert :error == status

    #Check the size of the database
    assert init_size + 2 == length(User |> Repo.all)
  end

  test "Login", state do
    init_size = length(User |> Repo.all)

    #Login user who does not exist
    {status, err} = GenServer.call(state.server,{:login, "User1"},:infinity)
    IO.puts("Error: #{inspect(err)}")
    assert :error == status

    #Check the size of the database
    assert init_size == length(User |> Repo.all)

    #Create user1
    {status, idc} = GenServer.call(state.server,{:create, "User1"},:infinity)
    IO.puts("ID : #{inspect(idc)}")
    assert :ok == status

    #Check the size of the database
    assert init_size + 1 == length(User |> Repo.all)

    #Login user1
    {status, idl} = GenServer.call(state.server,{:login, "User1"},:infinity)
    IO.puts("ID : #{inspect(idl)}")
    assert :ok == status

    #Check the size of the database
    assert init_size + 1 == length(User |> Repo.all)

    #Check both ids are the same
    assert idc == idl
  end
end
