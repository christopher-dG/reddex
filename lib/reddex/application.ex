defmodule Reddex.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Reddex.HTTP,
      Reddex.Auth
    ]

    opts = [strategy: :one_for_one, name: Reddex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
