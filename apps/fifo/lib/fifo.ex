defmodule Fifo do
  use GenServer

  def init(_) do
    {:ok, []}
  end

  def handle_cast({:push, element}, state) do
    {:noreply, state ++ [element]}
  end

  def handle_call(:pull, _from, []) do
    {:reply, nil, []}
  end

  def handle_call(:pull, _from, [element|tail]) do
    {:reply, {:ok, element}, tail}
  end

  def handle_call({:pull_backfilling, _}, _from, []) do
    {:reply, {:ok, nil}, []}
  end

  def handle_call({:pull_backfilling, fun}, _from, state) do
    {new_state, response} = pull_backfilling([], state, fun)
    {:reply, response, new_state}
  end

  def handle_call(:seek, _from, []) do
    {:reply, {:ok, nil}, []}
  end

  def handle_call(:seek, _from, [head | tail]) do
    {:reply, {:ok, head}, [head | tail]}
  end


  def handle_call({:seek_backfilling, _fun}, _from, []) do
    {:reply, {:ok, nil}, []}
  end

  def handle_call({:seek_backfilling, fun}, _from, state) do
    response = seek_backfilling(state, fun)
    {:reply, response, state}
  end


  defp pull_backfilling(prefix, [], _fun) do
    {prefix, {:ok, nil}}
  end

  defp pull_backfilling(prefix, [head | tail], fun) do
    cond do
      fun.(head)->
        {prefix ++ tail, {:ok, head}}
      true ->
        pull_backfilling(prefix ++ [head], tail, fun)

    end
  end

  defp seek_backfilling([], _fun) do
    {:ok, nil}
  end

  defp seek_backfilling([head | tail], fun) do
    cond do
      fun.(head)->
        {:ok, head}
      true ->
        seek_backfilling(tail, fun)
    end
  end
end
