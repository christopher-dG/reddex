defmodule Reddex.API.Me do
  @moduledoc "Functions for your bot's account."

  alias Reddex.HTTP

  @doc """
  Retrieves messages sent to your bot.
  See [here](https://www.reddit.com/dev/api#GET_message_inbox) for options.
  """
  @spec inbox(keyword) :: HTTP.listing_resp()
  def inbox(opts \\ []) do
    HTTP.get("/message/inbox", opts)
  end

  @doc """
  Retrieves submissions saved by your bot.
  See [here](https://www.reddit.com/dev/api#GET_user_{username}_saved) for options.
  """
  @spec saved(keyword) :: HTTP.listing_resp()
  def saved(opts \\ []) do
    listing("saved", opts)
  end

  @spec listing(String.t(), keyword) :: HTTP.listing_resp()
  defp listing(where, opts) do
    username = Application.get_env(:reddex, :username)
    HTTP.get("/user/#{username}/#{where}", opts)
  end
end
