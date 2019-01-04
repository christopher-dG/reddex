defmodule Reddex.Parser do
  @moduledoc false

  @doc """
  Parses some data.

  ## Examples

      iex> Reddex.Parser.parse(%{data: %{id: 1}})
      %{id: 1}

      iex> Reddex.Parser.parse(%{children: [%{id: 1}, %{id: 2}]})
      [%{id: 1}, %{id: 2}]

      iex> Reddex.Parser.parse(:some_other_data)
      :some_other_data
  """
  def parse(%{data: data}), do: parse(data)
  def parse(%{json: json}), do: parse(json)
  def parse(%{things: things}), do: Enum.map(things, &parse/1)
  def parse(%{children: children}), do: Enum.map(children, &parse/1)
  def parse(data), do: data
end
