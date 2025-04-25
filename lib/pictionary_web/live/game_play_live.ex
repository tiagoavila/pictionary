defmodule PictionaryWeb.GamePlayLive do
  use PictionaryWeb, :live_view

  alias Pictionary.GameServer

  def mount(%{"game" => game_code, "player" => player_id}, _session, socket) do
    if connected?(socket),
      do: PubSubHelper.subscribe(game_code)

    game_state = GameServer.get_current_state(game_code)
    {:ok, socket |> assign(game_code: game_code, player_id: player_id, game: game_state, last_update: [])}
  end

  def handle_event("drawClientToServer", %{"game_code" => game_code, "coordinates" => coordinates, "color" => color, "time_diff" => time_diff, "player_id" => player_id} = data, socket) do
    IO.puts("received draw event from game #{game_code}")
    update_map = Map.new(data, fn {key, value} ->
      {String.to_atom(key), value}
    end)
    PubSubHelper.broadcast_game_state(game_code, update_map)
    {:noreply, socket}
  end

  def handle_info({:draw_updated, draw_update_data}, socket) do
    IO.puts("received draw update event from broadcast")
    last_update_json = Jason.encode!(draw_update_data)
    {:noreply, assign(socket, last_update: last_update_json)}
  end
end
