defmodule PictionaryWeb.HomeLive do
  @moduledoc """
  The `HomeLive` module is responsible for handling live requests for the home page.
  """

  alias Pictionary.{GameStarter, GameServer, Player}
  use PictionaryWeb, :live_view

  def mount(_params, _session, socket) do
    IO.puts("mounting home live view")
    {:ok, assign(socket, changeset: GameStarter.changeset())}
  end

  def handle_event("validate", %{"game_starter" => params}, socket) do
    IO.puts("validating game starter params")
    changeset = GameStarter.changeset(params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("submit_game", %{"game_starter" => params}, socket) do
    IO.puts("submitting game starter params")

    with {:ok, game_starter} <- GameStarter.create(params),
         {:ok, player} <- Player.create(game_starter.player_name),
         {:ok, game_status} <- GameServer.start_or_join_game(game_starter.game_code, player) do
      IO.puts("Game create #{game_starter.game_code} - player #{game_starter.player_name}")

      {:noreply,
       push_navigate(socket, to: ~p"/play?game=#{game_starter.game_code}&player=#{player.id}")}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
