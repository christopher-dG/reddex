defmodule Reddex.Stream do
  @moduledoc "Streams listings."

  alias Reddex.HTTP
  require Logger

  @type streamable :: (() -> {:ok, [%{id: term}]} | {:error, HTTP.error()})

  @doc """
  Creates a stream which yields the unique results from `fun` every `interval` milliseconds.
  It is assumed that `fun` is not pure, and its results will change over time, such as when
  polling a Reddit listing.
  """
  @spec create(streamable, non_neg_integer) :: Enumerable.t()
  def create(fun, interval) do
    Stream.resource(
      fn -> call(fun) end,
      fn acc ->
        {els, seen} =
          if is_list(acc) do
            {acc, MapSet.new()}
          else
            Process.sleep(interval)
            {call(fun), acc}
          end

        replies = Enum.reject(els, fn %{id: id} -> id in seen end)

        seen =
          els
          |> Enum.map(&Map.get(&1, :id))
          |> MapSet.new()
          |> MapSet.union(seen)

        {replies, seen}
      end,
      fn _ -> nil end
    )
  end

  @spec call(streamable) :: [%{id: term}]
  def call(fun) do
    case fun.() do
      {:ok, els} ->
        els

      {:error, reason} ->
        Logger.warn("Streamed function failed (retrying): #{reason}")
        call(fun)
    end
  end
end
