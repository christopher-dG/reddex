defmodule Reddex.Utils do
  @moduledoc false

  @doc "Waits for a number of seconds exponential in `n`, capped at `max`."
  @spec exp_wait(non_neg_integer, non_neg_integer) :: :ok
  def exp_wait(n \\ 0, max \\ 30) do
    round(:math.pow(2, n) - 1)
    |> min(max)
    |> :erlang.*(1000)
    |> Process.sleep()
  end
end
