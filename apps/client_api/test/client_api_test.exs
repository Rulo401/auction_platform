defmodule ClientApiTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Repo
  alias ClientApi
  alias AuctionSystem.Supervisors.SystemSupervisor
  doctest ClientApi

  setup do
    trunc = "TRUNCATE TABLE CATEGORIES,
    WEAPONS,
    SKINS,
    ITEMS,
    USERS,
    AUCTIONS;"

    ins_cat = "INSERT INTO CATEGORIES
VALUES (0, 'Knives'),
              (1, 'Gloves'),
              (2, 'Rifles'),
              (3, 'Pistols');"
    ins_wea = "INSERT INTO WEAPONS
  VALUES (0, 'Ak-47', 2),
                              (1, 'M4A4', 2),
                              (2, 'AWP', 2),
                              (3, 'Karambit', 0);"
    ins_ski ="INSERT INTO SKINS
VALUES (0, 0, 453, 'Vulcan', 0.1, 0.4),
              (1, 0, 58, 'Redline', 0.01, 0.7);"
    ins_ite = "INSERT INTO ITEMS
  VALUES (0, 0, 30, 0.2),
                (1, 0, 67, 0.399),
                (2, 1, 11, 0.65);"
    ins_use = "INSERT INTO USERS
  VALUES (0, 'UserTest1', 0.0, 0.0),
                (1, 'UserTest2', 0.0, 27.2),
                (2, 'UserTest3', 50.5, 0.5);"
    ins_auc = "INSERT INTO AUCTIONS
  VALUES (0, 0, 0, 1, 25.0, 27.2, '2024-05-29', FALSE),
                (1, 0, 1, NULL, 50.0, NULL, '2023-05-29', FALSE),
                (2, 0, 2, 2, 0.2, 0.5, '2024-05-29', FALSE);"

      #Insert data into the DB
      {:ok, _} = Repo.query(trunc)
      {:ok, _} = Repo.query(ins_cat)
      {:ok, _} = Repo.query(ins_wea)
      {:ok, _} = Repo.query(ins_ski)
      {:ok, _} = Repo.query(ins_ite)
      {:ok, _} = Repo.query(ins_use)
      {:ok, _} = Repo.query(ins_auc)

      SystemSupervisor.start_link([])
      :ok


  end


  test "UserServer " do
    #Create a user, delete it and try to login
    {status, _} =  ClientApi.create_user("UserTest4")
    assert status == :ok
    assert ClientApi.delete_user("UserTest4") == :ok
    assert ClientApi.delete_user("UserTest4") == {:error, "Username not found"}
    {status, _} = ClientApi.login_user("UserTest1")
    assert status == :ok
    assert ClientApi.login_user("UserTest4") == {:error, "Username not found"}
    assert ClientApi.create_user("UserTest2") == {:error, "Username already exists"}
  end

  test "CreditServer" do
    #Deposit,withdraw and check balance from a user
    {status, _} = ClientApi.login_user("UserTest1")
    assert status == :ok
    {status, _} = ClientApi.login_user("UserTest3")
    assert status == :ok
    assert ClientApi.deposit(0, 10) == {:ok, 10}
    assert ClientApi.deposit(0, -5) == {:error, "Deposit amount must be a positive number"}
    assert ClientApi.withdraw(2, 10) == {:ok, 40.5}
    assert ClientApi.check_balance(0) == {:ok, 10}
    assert ClientApi.check_balance(2) == {:ok, 40.5}
  end

  test "BidServer" do
    #Bid on an auction
    {status, id1} = ClientApi.login_user("UserTest1")
    assert status == :ok
    assert ClientApi.deposit(0, 30) == {:ok, 30.0}
    {status, id3} = ClientApi.login_user("UserTest3")
    assert status == :ok
    assert ClientApi.bid(id1, 2, 1.0) == {:ok,29.0}
    assert ClientApi.bid(id3, 2, 1.5) == {:ok, 49.5}
    assert ClientApi.bid(id1, 2, 2.0) == {:ok, 28.0}
    assert ClientApi.bid(id3, 2, 2.5) == {:ok, 48.5}
    assert ClientApi.bid(id1, 2, 3.0) == {:ok, 27.0}

    #Bid on a closed auction
    assert ClientApi.bid(id3, 1, 30.0) == {:error, "Auction is closed or does not exist"}

    #Bid with a non existant auction
    assert ClientApi.bid(id1, 4, 5.0) == {:error, "Auction is closed or does not exist"}

    #Bid with an amount lower than the current bid
    assert ClientApi.bid(id1, 2, 0.8) == {:error, "Bid must be higher than the current one"}

  end

  #Make tests for the Client api of MarketServer
  test "MarketServer" do
    #List all auctions
    assert ClientApi.list_auctions() == {:ok, [0, 2]}

    #List all auctions of a skin
    assert ClientApi.list_auctions(:skin, 1) == {:ok, [2]}
    assert ClientApi.list_auctions(:skin, 0) == {:ok, [0]}
    assert ClientApi.list_auctions(:skin, 2) == {:error, "Invalid skin or No auctions listed for that skin"}

    #List all auctions of a weapon
    assert ClientApi.list_auctions(:weapon, 0) == {:ok, [0,2]}
    assert ClientApi.list_auctions(:weapon, 1) == {:error, "Invalid weapon or No auctions listed for that weapon"}

    #List all auctions of a category
    assert ClientApi.list_auctions(:category, 2) == {:ok, [0,2]}
    assert ClientApi.list_auctions(:category, 0) == {:error, "Invalid category or No auctions listed for that category"}

    #List all categories
    assert ClientApi.list_categories() == {:ok, [{0, "Knives"}, {1, "Gloves"}, {2, "Rifles"}, {3, "Pistols"}]}

    #List all skins of a weapon
    assert ClientApi.list_skins(0) == {:ok, [{0, "Vulcan"},{1, "Redline"}]}

    #List all weapons of a category
    assert ClientApi.list_weapons(0) == {:ok, [{3, "Karambit"}]}

    #Create an auction
    {status, id} = ClientApi.login_user("UserTest1")
    assert status == :ok
    item = %{skin_id: 0, seed: 233, sfloat: 0.33}
    {status, _} = ClientApi.create_auction(id, item, 10, 5.0)
    assert status == :ok

    #Get auction data
    {_,date} =  NaiveDateTime.new(2024,05,29,00,00,00)
    auction_data = %{weapon: "Ak-47", skin: "Vulcan", seed: 30, skinFloat: 0.2, bid: 27.2, end: date}
    assert ClientApi.auction_data(0) == {:ok, auction_data}
  end
end
