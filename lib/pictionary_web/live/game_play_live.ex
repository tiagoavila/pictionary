defmodule PictionaryWeb.GamePlayLive do
  use PictionaryWeb, :live_view

  alias Pictionary.GameServer

  def mount(%{"game" => game_code, "player" => player_id}, _session, socket) do
    if connected?(socket),
      do: PubSubHelper.subscribe(game_code)

    game_state = GameServer.get_current_state(game_code)

    {:ok,
     socket
     |> assign(game_code: game_code, player_id: player_id, game: game_state, last_update: [])}
  end

  def handle_event(event_name, data, socket) do
    update_map = parse_string_keys_to_atom_keys(data)
    PubSubHelper.broadcast_game_state(event_name, socket.assigns.game_code, update_map)
    {:noreply, socket}
  end

  def handle_info({event_name, data}, socket) do
    data_json = Jason.encode!(data)
    {:noreply, push_event(socket, event_name, %{data: data_json})}
  end

  defp parse_string_keys_to_atom_keys(map_with_string_keys) do
    Map.new(map_with_string_keys, fn {key, value} ->
      {String.to_atom(key), value}
    end)
  end
end
