defmodule Reddex.Parser do
  @moduledoc "Parses data into structs."

  alias Reddex.API.Subreddit
  alias Reddex.API.User
  require Logger

  @kind_user "t2"
  @kind_subreddit "t5"

  def parse(%{kind: @kind_user, data: data}) do
    struct(User, data)
  end

  def parse(%{kind: @kind_subreddit, data: data}) do
    struct(Subreddit, data)
  end

  def parse(%{kind: kind, data: data}) do
    Logger.warn("Unknown type '#{kind}' (returning unparsed)")
    data
  end
end
