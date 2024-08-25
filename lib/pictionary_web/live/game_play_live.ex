defmodule PictionaryWeb.GamePlayLive do
  use PictionaryWeb, :live_view

  alias Pictionary.GameServer

  def mount(%{"game" => game_code, "player" => player_id}, _session, socket) do
    # if connected?(socket),
      # do: PubSubHelper.subscribe(game_code)

    game_state = GameServer.get_current_state(game_code)
    {:ok, socket |> assign(game_code: game_code, player_id: player_id, game: game_state)}
  end

  def handle_event("drawClientToServer", %{"coordinates" => coordinates, "color" => color}, socket) do
    IO.puts("received draw event from client with coordinates #{coordinates} and color #{color}")
   {:noreply, socket}
  end
end
