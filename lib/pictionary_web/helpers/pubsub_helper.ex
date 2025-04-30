defmodule PubSubHelper do
  @moduledoc """
  This module is responsible for managing the PubSub system in the PictionaryWeb application.
  """

  alias Phoenix.PubSub

  def subscribe(game_code) do
    PubSub.subscribe(Pictionary.PubSub, "game-#{game_code}")
  end

  @spec broadcast_game_state(atom, String.t(), map) :: :ok
  def broadcast_game_state(event_name, game_code, draw_update_data) do
    PubSub.broadcast(
      Pictionary.PubSub,
      "game-#{game_code}",
      {event_name, draw_update_data}
    )
  end
end
