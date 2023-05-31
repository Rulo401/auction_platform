defmodule FifoTest do
  use ExUnit.Case
  alias Fifo
  doctest Fifo

  setup_all do
    {_, pid} = GenServer.start_link(Fifo, [])
    Process.register(pid, FifoServer)
    :ok
  end

  describe "Empty state Tests" do
    # Pull with empty FIFO
    test "Pull with Empty State" do
      assert nil == GenServer.call(FifoServer, :pull, 500)
    end

    # Pull_backfilling with empty FIFO
    test "Pull_backfilling with Empty State" do
      assert {:ok, nil} == GenServer.call(FifoServer, {:pull_backfilling, fn _x -> false end}, 500)
    end


    # Seek with empty FIFO
    test "Seek with Empty State" do
      assert {:ok, nil} == GenServer.call(FifoServer, :seek, 500)
    end

    # Seek_backfilling with empty FIFO
    test "Seek_backfilling with Empty State" do
      assert {:ok, nil} == GenServer.call(FifoServer, {:seek_backfilling, fn _x -> false end}, 500)
    end
  end

  describe "Tests with state" do
    setup do
      {_, pid} = GenServer.start_link(Fifo, [])
      #Process.register(pid, FifoServer)
      {:ok, server: pid}
    end

    # Pull Push and Seek with elements
    test "Push_Pull_Seek" , state do
      GenServer.cast(state.server, {:push, 3})
      assert {:ok, 3} == GenServer.call(state.server, :pull, 500)

      GenServer.cast(state.server, {:push, 4})
      GenServer.cast(state.server, {:push, 5})
      assert {:ok, 4} == GenServer.call(state.server, :pull, 500)
      assert {:ok, 5} == GenServer.call(state.server, :seek, 500)
      assert {:ok, 5} == GenServer.call(state.server, :pull, 500)
    end

    # Pull and Seek backfilling with elements
    test "Pull_Seek_backfilling" , state do
      GenServer.cast(state.server, {:push, 1})
      GenServer.cast(state.server, {:push, 2})
      GenServer.cast(state.server, {:push, 3})
      GenServer.cast(state.server, {:push, 4})

      assert {:ok, 2} == GenServer.call(state.server, {:pull_backfilling, fn x -> x > 1 end}, 500)

      assert {:ok, 3} == GenServer.call(state.server, {:seek_backfilling, fn x -> x > 1 end}, 500)
      assert {:ok, 1} == GenServer.call(state.server, :pull, 500)
      assert {:ok, 3} == GenServer.call(state.server, :pull, 500)
    end
  end
end
