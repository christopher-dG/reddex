defmodule Reddex.HTTP do
  @moduledoc "Makes HTTP requests."

  alias Reddex.Auth
  alias Reddex.Parser
  require Logger
  use GenServer

  @base_url "https://oauth.reddit.com"

  @type error :: {:error, {:tesla, term} | {:status, 100..199 | 300..599}}
  @type listing :: [%{name: String.t()}]
  @type listing_resp :: {:ok, listing} | error
  @type post_resp :: {:ok, term} | error

  @doc false
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{remaining: 1, reset: 0}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:request, opts}, _from, %{remaining: remaining, reset: reset} = state) do
    # Wait for the rate limit.
    if remaining === 0 do
      Logger.info("Rate limit exceeded, waiting #{reset} seconds")
      Process.sleep(reset * 1000)
    end

    # Make the request and parse the result.
    result = Tesla.request(client(), opts)
    reply = cast_response(result)

    # Update the rate limit.
    newstate =
      with {:ok, resp} <- result,
           remaining when is_binary(remaining) <- Tesla.get_header(resp, "x-ratelimit-remaining"),
           {remaining, ""} <- Float.parse(remaining),
           reset when is_binary(reset) <- Tesla.get_header(resp, "x-ratelimit-reset"),
           {reset, ""} <- Float.parse(reset) do
        %{remaining: round(remaining), reset: round(reset)}
      else
        _ -> state
      end

    {:reply, reply, newstate}
  end

  @doc "Makes a GET request."
  @spec get(String.t(), keyword) :: {:ok, term} | error
  def get(url, query \\ []) do
    request(method: :get, url: url, query: query)
  end

  @doc "Makes a POST request."
  @spec post(String.t(), keyword) :: {:ok, term} | error
  def post(url, body \\ %{}) do
    request(method: :post, url: url, body: body)
  end

  @doc "Makes a PUT request."
  @spec put(String.t(), keyword) :: {:ok, term} | error
  def put(url, body \\ %{}) do
    request(method: :put, url: url, body: body)
  end

  @doc "Makes a DELETE request."
  @spec delete(String.t(), keyword) :: {:ok, term} | error
  def delete(url, body \\ %{}) do
    request(method: :delete, url: url, body: body)
  end

  # Makes a request.
  @spec request(keyword) :: {:ok, term} | error
  defp request(opts) do
    GenServer.call(__MODULE__, {:request, opts}, :infinity)
  end

  # Converts a response to a more meaningful value.
  @spec cast_response({:ok, term} | {:error, term}) :: {:ok, term} | error
  defp cast_response({:error, reason}) do
    {:error, {:tesla, reason}}
  end

  defp cast_response({:ok, %{status: status}}) when status not in 200..299 do
    {:error, {:status, status}}
  end

  defp cast_response({:ok, %{body: body}}) do
    {:ok, Parser.parse(body)}
  end

  # Creates a Tesla HTTP client.
  @spec client :: Tesla.Client.t()
  defp client do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, @base_url},
      {Tesla.Middleware.Headers,
       [
         {"authorization", Auth.token()},
         {"user-agent", Application.get_env(:reddex, :user_agent)}
       ]},
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.FollowRedirects,
      {Tesla.Middleware.DecodeJson, engine_opts: [keys: :atoms]}
    ])
  end
end
