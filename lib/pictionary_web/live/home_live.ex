defmodule PictionaryWeb.HomeLive do
  @moduledoc """
  The `HomeLive` module is responsible for handling live requests for the home page.
  """

  alias Pictionary.GameStarter
  use PictionaryWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, changeset: GameStarter.changeset())}
  end

  def handle_event("validate", %{"game_starter" => params}, socket) do
    changeset = GameStarter.changeset(params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("submit_game", %{"game_starter" => params}, socket) do
    changeset = GameStarter.changeset(params) |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end
end
