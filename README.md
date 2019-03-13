# Reddex [![Build Status](https://travis-ci.com/christopher-dG/reddex.svg?branch=master)](https://travis-ci.com/christopher-dG/reddex)

Reddit API client for Elixir.

## Disclaimer

This library was built for my own simple use cases, and it's unlikely to ever be feature complete.
The existing features are:

* Automatic authentication
* Automatic rate limiting
* Streaming listings
* Replying to and saving submissions
* Getting information on subreddits and users

## Installation

Add the following to `deps/0` in `mix.exs`:

```elixir
{:reddex, "~> 0.1"}
```

## Configuration

Add the following configuration to your application:

```elixir
config :reddex,
  username: "REDDIT_USERNAME",
  password: "REDDIT_PASSWORD",
  client_id: "REDDIT_CLIENT_ID",
  client_secret: "REDDIT_CLIENT_SECRET",
  user_agent: "REDDIT_USER_AGENT"
```

As a fallback, environment variables are used.
The application will not start if there are missing credentials,

## Usage

Here is a simple post reply bot:

```elixir
defmodule PostReplyBot do
  @moduledoc "Praises good doggos."

  alias Reddex.{Stream, API.Post, API.Subreddit}

  @subreddit "rarepuppers"

  def start_link(opts) do
    Task.start_link(fn -> praise_doggos(opts) end)
  end

  defp praise_doggos(opts \\ []) do
    Stream.create(&Subreddit.new/2, @subreddit, opts)
    |> Enum.each(fn post ->
      unless post.saved do
        Post.reply(post, "11/10 doggo")
        Post.save(post)
      end
    end)
  end
end

{:ok, _pid} = PostReplyBot.start_link(limit: 10, interval: 60_000)
```
