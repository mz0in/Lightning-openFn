defmodule Lightning.AuthProviders.Google do
  @moduledoc """
  Handles the specifics of the Google OAuth authentication process.
  """
  @behaviour Lightning.AuthProviders.OAuthBehaviour

  alias Lightning.AuthProviders.Common
  require Logger

  @impl true
  def build_client(opts \\ []) do
    Common.build_client(:google, opts)
  end

  @impl true
  def authorize_url(client, state, scopes \\ [], opts \\ []) do
    default_scopes = [
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/userinfo.profile"
    ]

    combined_scopes = scopes ++ default_scopes
    Common.authorize_url(client, state, combined_scopes, opts)
  end

  @impl true
  def get_token(client, params) do
    Common.get_token(client, params)
  end

  @impl true
  def refresh_token(client, token) do
    Common.refresh_token(client, token)
  end

  @impl true
  def refresh_token(token) do
    {:ok, %OAuth2.Client{} = client} = build_client()
    refresh_token(client, token)
  end

  @impl true
  def get_userinfo(client, token) do
    Common.get_userinfo(client, token, :google)
  end
end
