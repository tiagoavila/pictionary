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

  def handle_event("drawUpdated", %{"game_code" => game_code} = data, socket) do
    IO.puts("received draw event from game #{game_code}")

    update_map = parse_string_keys_to_atom_keys(data)
    PubSubHelper.broadcast_game_state(:draw_updated, game_code, update_map)
    {:noreply, socket}
  end

  def handle_event("FillAreaUpdated", %{"click_coordinates" => [x, y], "fillColor" => fillColor} = data, socket) do
    IO.puts("received fill area event from game #{socket.assigns.game_code} at coordinates #{x}, #{y} with color #{fillColor}")
    update_map = parse_string_keys_to_atom_keys(data)
    PubSubHelper.broadcast_game_state(:fill_area_updated, socket.assigns.game_code, update_map)
    {:noreply, socket}
  end

  def handle_info({:draw_updated, draw_update_data}, socket) do
    last_update_json = Jason.encode!(draw_update_data)
    {:noreply, push_event(socket, "draw-updated", %{data: last_update_json})}
  end

  def handle_info({:fill_area_updated, fill_area_update_data}, socket) do
    last_fill_json = Jason.encode!(fill_area_update_data)
    {:noreply, push_event(socket, "fill-area-updated", %{data: last_fill_json})}
  end

  defp parse_string_keys_to_atom_keys(map_with_string_keys) do
    Map.new(map_with_string_keys, fn {key, value} ->
      {String.to_atom(key), value}
    end)
  end
end
