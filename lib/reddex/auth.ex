defmodule Reddex.Auth do
  @moduledoc false

  alias Tesla.Middleware
  import Reddex.Utils
  require Logger
  use GenServer

  @url "https://www.reddit.com/api/v1/access_token"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, "", name: __MODULE__)
  end

  @impl true
  def init(_state) do
    if Enum.any?([:username, :password, :client_id, :client_secret, :user_agent], fn k ->
         is_nil(Application.get_env(:reddex, k))
       end) do
      {:stop, :missing_credentials}
    else
      send(__MODULE__, :refresh)
      {:ok, ""}
    end
  end

  @impl true
  def handle_call(:token, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:refresh, _state) do
    Logger.debug("Refreshing OAuth token")
    %{token: token, expiry: expiry} = get_token()
    Logger.debug("Refreshed OAuth token")
    Process.send_after(__MODULE__, :refresh, expiry - 120_000)
    {:noreply, token}
  end

  # Gets an OAuth token.
  @spec get_token(non_neg_integer) :: %{token: String.t(), expiry: integer}
  defp get_token(n \\ 0) do
    exp_wait(n)

    client =
      Tesla.client([
        {Middleware.Headers, [{"user-agent", Application.get_env(:reddex, :user_agent)}]},
        {Middleware.BasicAuth,
         username: Application.get_env(:reddex, :client_id),
         password: Application.get_env(:reddex, :client_secret)},
        Middleware.FormUrlencoded,
        {Middleware.DecodeJson, engine_opts: [keys: :atoms]}
      ])

    body = %{
      grant_type: "password",
      username: Application.get_env(:reddex, :username),
      password: Application.get_env(:reddex, :password)
    }

    case Tesla.post(client, @url, body) do
      {:ok, %{body: %{access_token: token, expires_in: expiry}}} ->
        %{token: "bearer " <> token, expiry: expiry * 1000}

      {:ok, %{status: status, body: body}} ->
        Logger.warn("""
        OAuth token refresh failed (retrying)
        status code = #{status}
        body = #{inspect(body)}
        """)

        get_token(n + 1)

      {:error, reason} ->
        Logger.warn("OAuth token refresh failed (retrying): #{inspect(reason)}")
        get_token(n + 1)
    end
  end

  @doc "Retrieves an OAuth token."
  @spec token :: String.t()
  def token do
    GenServer.call(__MODULE__, :token)
  end
end
