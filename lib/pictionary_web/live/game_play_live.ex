defmodule PictionaryWeb.GamePlayLive do
  use PictionaryWeb, :live_view

  alias Pictionary.GameServer

  def mount(%{"game" => game_code, "player" => player_id}, _session, socket) do
    if connected?(socket),
      do: PubSubHelper.subscribe(game_code)

    game_state = GameServer.get_current_state(game_code)
    {:ok, socket |> assign(game_code: game_code, player_id: player_id, game: game_state)}
  end

  def handle_event("drawClientToServer", %{"game_code" => game_code, "coordinates" => coordinates, "color" => color}, socket) do
    IO.puts("received draw event from game #{game_code} with coordinates #{coordinates} and color #{color}")
    PubSubHelper.broadcast_game_state(game_code, coordinates, color)
    {:noreply, socket}
  end

  def handle_info({:game_state_updated, %{coordinates: coordinates, color: color}}, socket) do
    IO.puts("received game state update with coordinates #{coordinates} and color #{color}")
    {:noreply, socket}
  end
end
