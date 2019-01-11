defmodule Reddex.Stream do
  @moduledoc "Streams listings."

  alias Reddex.HTTP
  import Reddex.Utils
  require Logger

  @default_interval 30_000

  @doc """
  Creates an infinite stream of unique results from the listing function `fun`.
  Options are passed on to `fun`, with the exception of `:interval`, which specifies the
  number of milliseconds between requests (#{@default_interval} by default).

  ## Examples

      iex> result = Reddex.Stream.create(&Reddex.API.Me.inbox/1) |> Enum.take(1)
      iex> match?([%{id: _id}], result)
      true

      iex> result = Reddex.Stream.create(&Reddex.API.Subreddit.new/2, "all", limit: 100) |> Enum.take(1)
      iex> match?([%{id: _id}], result)
      true
  """
  @spec create((keyword -> HTTP.listing_resp())) :: Enumerable.t()
  def create(fun) when is_function(fun, 1) do
    create(fun, [])
  end

  @spec create((keyword -> HTTP.listing_resp()), keyword) :: Enumerable.t()
  def create(fun, opts) when is_function(fun, 1) do
    {interval, opts} = parse_opts(opts)
    Stream.resource(start_fun(fun, opts), next_fun(fun, opts, interval), after_fun())
  end

  @spec create((term, keyword -> HTTP.listing_resp()), term) :: Enumerable.t()
  def create(fun, arg) when is_function(fun, 2) do
    create(fun, arg, [])
  end

  @spec create((term, keyword -> HTTP.listing_resp()), term, keyword) :: Enumerable.t()
  def create(fun, arg, opts) when is_function(fun, 2) do
    {interval, opts} = parse_opts(opts)
    Stream.resource(start_fun(fun, arg, opts), next_fun(fun, arg, opts, interval), after_fun())
  end

  # Creates a function that initializes the stream.
  @spec start_fun((keyword -> HTTP.listing_resp()), keyword) :: (() -> HTTP.listing())
  defp start_fun(fun, opts) do
    fn -> retry(fun, opts) end
  end

  @spec start_fun((keyword, term -> HTTP.listing_resp()), term, keyword) :: (() -> HTTP.listing())
  defp start_fun(fun, arg, opts) do
    fn -> retry(fun, arg, opts) end
  end

  # Creates a function tht gets the next stream value.
  @spec next_fun((() -> HTTP.listing()), (String.t() -> HTTP.listing()), non_neg_integer) ::
          (term -> {HTTP.listing(), term})
  defp next_fun(fun0, fun1, interval) when is_function(fun0, 0) and is_function(fun1, 1) do
    fn acc ->
      els =
        case acc do
          els when is_list(acc) ->
            # This is reached by the initial state which doesn't need to sleep.
            els

          before when is_binary(before) ->
            Process.sleep(interval)

            # If a post is removed, then using its name as an anchor always returns empty.
            # Therefore, whenever we get an empty response, try omitting the anchor.
            # No, this is not super efficient nor kind to the rate limits.
            # This strategy will skip posts on high-traffic listings if the interval is high.
            case fun1.(before) do
              [] -> Enum.filter(fun0.(), fn %{name: name} -> name > before end)
              els -> els
            end
        end

      before =
        cond do
          Enum.empty?(els) and is_binary(acc) ->
            acc

          Enum.empty?(els) ->
            nil

          true ->
            els
            |> hd()
            |> Map.get(:name)
        end

      {els, before}
    end
  end

  @spec next_fun((keyword -> HTTP.listing_resp()), keyword, non_neg_integer) ::
          (HTTP.listing() | String.t() -> {HTTP.listing(), String.t()})
  defp next_fun(fun, opts, interval) do
    next_fun(
      fn -> retry(fun, Keyword.put(opts, :limit, 1000)) end,
      fn before -> retry(fun, Keyword.put(opts, :before, before)) end,
      interval
    )
  end

  @spec next_fun((term, keyword -> HTTP.listing_resp()), term, keyword, non_neg_integer) ::
          (HTTP.listing() | String.t() -> {HTTP.listing(), String.t()})
  defp next_fun(fun, arg, opts, interval) do
    next_fun(
      fn -> retry(fun, arg, Keyword.put(opts, :limit, 1000)) end,
      fn before -> retry(fun, arg, Keyword.put(opts, :before, before)) end,
      interval
    )
  end

  # Creates a function that finalizes the stream.
  @spec after_fun :: (term -> nil)
  defp after_fun do
    fn _ -> nil end
  end

  @spec parse_opts(keyword) :: {non_neg_integer, keyword}
  defp parse_opts(opts) do
    opts
    |> Keyword.drop([:before, :after])
    |> Keyword.pop(:interval, @default_interval)
  end

  # Retries a listing function until it succeeds.
  @spec retry((keyword -> HTTP.listing()), keyword) :: HTTP.listing()
  defp retry(fun, opts) do
    retry(fun, opts, 0)
  end

  @spec retry((keyword -> HTTP.listing()), keyword, non_neg_integer) :: HTTP.listing()
  defp retry(fun, opts, n) when is_integer(n) do
    exp_wait(n)

    case fun.(opts) do
      {:ok, els} ->
        els

      {:error, reason} ->
        Logger.warn("Streamed function #{inspect(fun)} failed (retrying): #{inspect(reason)}")
        retry(fun, opts, n + 1)
    end
  end

  @spec retry((term, keyword -> HTTP.listing()), term, keyword) :: HTTP.listing()
  defp retry(fun, arg, opts) do
    retry(fun, arg, opts, 0)
  end

  @spec retry((term, keyword -> HTTP.listing()), term, keyword, non_neg_integer) :: HTTP.listing()
  defp retry(fun, arg, opts, n) do
    exp_wait(n)

    case fun.(arg, opts) do
      {:ok, els} ->
        els

      {:error, reason} ->
        Logger.warn("Streamed function #{inspect(fun)} failed (retrying): #{inspect(reason)}")
        retry(fun, arg, opts, n + 1)
    end
  end
end
