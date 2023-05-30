defmodule AuctionSystemTest.Tasks.FilterListTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Tasks.FilterList
  alias AuctionSystem.Schemas.Category
  doctest FilterList

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

    #Lists all categories in the DB
    test "No Categories listed" do
      pid = self()
      spawn(fn -> FilterList.list_categories(pid, :test) end)

      receive do
        {:market, :test, response} ->
          assert response == {:error, "No categories listed"}

        after 1000 -> refute "timeout" == "timeout"
      end
    end

    #List all weapons from category 2 when there are no weapons for the category
    test "No Weapons for invalid Category" do
      pid = self()
      #No weapons for category
      spawn(fn -> FilterList.list_weapons(pid, :test, 2) end)

      receive do
        {:market, :test, response} ->
          assert response == {:error, "Invalid category or No weapons for that category"}

        after 1000 -> refute "timeout" == "timeout"
      end
    end
  end

  describe "Tests with tables"do
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
  VALUES (0, 0, 453, 'Skin1', 0.1, 0.4),
                (1, 0, 58, 'Skin2', 0.01, 0.7);"

      #Insert data into the DB
      {:ok, _} = Repo.query(trunc)
      {:ok, _} = Repo.query(ins_cat)
      {:ok, _} = Repo.query(ins_wea)
      {:ok, _} = Repo.query(ins_ski)

      :ok
    end

    #Lists all categories in the DB
    test "List Categories" do
      pid = self()
      spawn(fn -> FilterList.list_categories(pid, :test) end)

      receive do
        {:market, :test, {:ok,response}} ->
          assert response == [{0,"Knives"},{1,"Gloves"},{2,"Rifles"},{3,"Pistols"}]

        after 1000 -> refute "timeout" == "timeout"
      end
    end

    #List all weapons from category 2
    test "List Weapons of Category 2" do
      pid = self()
      spawn(fn -> FilterList.list_weapons(pid, :test, 2) end)

      receive do
        {:market, :test, {:ok,response}} ->
          assert response == [{0,"Ak-47"},{1,"M4A4"},{2,"AWP"}]

        after 1000 -> refute "timeout" == "timeout"
      end
    end
    #List all weapons from category 5 that doesnt exist
    test "List Weapons of Category 5" do
      pid = self()
      spawn(fn -> FilterList.list_weapons(pid, :test, 5) end)

      receive do
        {:market, :test, response} ->
          assert response == {:error, "Invalid category or No weapons for that category"}

        after 1000 -> refute "timeout" == "timeout"
      end
    end
  end
end
