defmodule Reddex.API.Post do
  @moduledoc "Function for posts."

  alias Reddex.HTTP
  alias Reddex.API.Submission

  @doc """
  Reply to a post.
  See [here](https://www.reddit.com/dev/api#POST_api_comment) for options.
  """
  @spec reply(%{name: String.t()}, String.t(), keyword) :: HTTP.post_resp()
  defdelegate reply(parent, message, opts \\ []), to: Submission

  @doc """
  Save a post.
  See [here](https://www.reddit.com/dev/api#POST_api_save) for options.
  """
  @spec save(%{name: String.t()}, keyword) :: HTTP.post_resp()
  defdelegate save(post, opts \\ []), to: Submission
end
