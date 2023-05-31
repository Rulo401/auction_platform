defmodule AuctionSystemTest.Tasks.AuctionListTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Tasks.AuctionList
  doctest AuctionList

  describe "Empty tables Test"do
    setup do
      trunc = "TRUNCATE TABLE CATEGORIES,
    WEAPONS,
    SKINS,
    ITEMS,
    USERS,
    AUCTIONS;"

      #Insert data into the DB
      {:ok, _} = Repo.query(trunc)

      :ok
    end

    #Lists all auctions in the DB
    test "No Auctions listed" do
      pid = self()
      spawn(fn -> AuctionList.list_auctions(pid, :test, :all) end)

      receive do
        {:market, :test, response} ->
          assert response == {:error, "No auctions listed"}

        after 1000 -> refute "timeout" == "timeout"
      end
    end

    #Lists all auctions by a category thats not in the DB
    test "No Auctions for Invalid category" do
      pid = self()
      spawn(fn -> AuctionList.list_auctions(pid, :test, :category, 1) end)

      receive do
        {:market, :test, response} ->
          assert response == {:error, "Invalid category or No auctions listed for that category"}

        after 1000 -> refute "timeout" == "timeout"
      end
    end
  end

  describe "Tests with tables" do
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
    VALUES (0, 0, 0, 1, 25.0, 27.2, '2023-05-29', FALSE),
                  (1, 0, 1, NULL, 50.0, NULL, '2023-05-29', FALSE),
                  (2, 0, 2, 2, 0.2, 0.5, '2024-05-29', FALSE);"

      {:ok, _} = Repo.query(trunc)
      {:ok, _} = Repo.query(ins_cat)
      {:ok, _} = Repo.query(ins_wea)
      {:ok, _} = Repo.query(ins_ski)
      {:ok, _} = Repo.query(ins_ite)
      {:ok, _} = Repo.query(ins_use)
      {:ok, _} = Repo.query(ins_auc)

      :ok
    end

    #Lists all auctions in the DB
    test "Listed Auctions" do
      pid = self()
      spawn(fn -> AuctionList.list_auctions(pid, :test, :all) end)

      receive do
        {:market, :test, response} ->
          assert response == {:ok,[0,1,2]}

        after 1000 -> refute "timeout" == "timeout"
      end
    end

    #Lists all auctions with weapon from category 2
    test "Listed Auctions with Weapon from Category 2" do
      pid = self()
      spawn(fn -> AuctionList.list_auctions(pid, :test, :category, 2) end)

      receive do
        {:market, :test, response} ->
          assert response == {:ok,[0,1,2]}

        after 1000 -> refute "timeout" == "timeout"
      end
    end

    #Lists all auctions with weapon from category 4 that doesnt exist
    test "Listed Auctions with Weapon from Category 4" do
      pid = self()
      spawn(fn -> AuctionList.list_auctions(pid, :test, :category, 4) end)

      receive do
        {:market, :test, response} ->
          assert response == {:error, "Invalid category or No auctions listed for that category"}

        after 1000 -> refute "timeout" == "timeout"
      end
    end
  end
end
