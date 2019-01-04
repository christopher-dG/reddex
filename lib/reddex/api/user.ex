defmodule Reddex.API.User do
  @moduledoc "Functions for users."

  alias Reddex.HTTP

  @doc "Retrieves information about a user."
  @spec about(String.t()) :: {:ok, map} | HTTP.error()
  def about(username) do
    HTTP.get("/user/#{username}/about")
  end
end
