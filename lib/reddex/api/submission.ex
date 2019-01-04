defmodule Reddex.API.Submission do
  @moduledoc false

  alias Reddex.HTTP

  def reply(%{name: name}, message, opts \\ []) do
    body =
      opts
      |> Keyword.merge(api_type: "json", thing_id: name, text: message)
      |> Map.new()

    HTTP.post("/api/comment", body)
  end

  def save(%{name: name}, opts \\ []) do
    body =
      opts
      |> Keyword.merge(id: name)
      |> Map.new()

    HTTP.post("/api/save", body)
  end
end
