defmodule Reddex.API.Subreddit do
  @moduledoc "Functions for subreddits."

  alias Reddex.HTTP

  @doc "Retrieves information about a subreddit."
  @spec about(String.t()) :: {:ok, map} | HTTP.error()
  def about(subreddit) do
    HTTP.get("/r/#{subreddit}/about")
  end

  @doc """
  Retrieves hot posts from a subreddit.
  See [here](https://www.reddit.com/dev/api#GET_hot) for options.
  """
  @spec hot(String.t(), keyword) :: HTTP.listing_resp()
  def hot(subreddit, opts \\ []) do
    HTTP.get("/r/#{subreddit}/hot", opts)
  end

  @doc """
  Retrieves new posts from a subreddit.
  See [here](https://www.reddit.com/dev/api#GET_new) for options.
  """
  @spec new(String.t(), keyword) :: HTTP.listing_resp()
  def new(subreddit, opts \\ []) do
    HTTP.get("/r/#{subreddit}/new", opts)
  end

  @doc """
  Retrieves top posts from a subreddit.
  See [here](https://www.reddit.com/dev/api#GET_top) for options.
  """
  @spec top(String.t(), keyword) :: HTTP.listing_resp()
  def top(subreddit, opts \\ []) do
    HTTP.get("/r/#{subreddit}/top", opts)
  end

  @doc """
  Retrieves controversial posts from a subreddit.
  See [here](https://www.reddit.com/dev/api#GET_controversial) for options.
  """
  @spec controversial(String.t(), keyword) :: HTTP.listing_resp()
  def controversial(subreddit, opts \\ []) do
    HTTP.get("/r/#{subreddit}/controversial", opts)
  end
end
