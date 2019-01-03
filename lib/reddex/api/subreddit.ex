defmodule Reddex.API.Subreddit do
  @moduledoc "Reddit subreddits."

  alias Reddex.HTTP

  @doc "Retrieves information about a subreddit."
  @spec about(String.t()) :: {:ok, [map]} | HTTP.error()
  def about(subreddit) do
    HTTP.get("/r/#{subreddit}/about")
  end
end
