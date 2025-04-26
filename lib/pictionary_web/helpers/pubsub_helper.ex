defmodule PubSubHelper do
  @moduledoc """
  This module is responsible for managing the PubSub system in the PictionaryWeb application.
  """

  alias Phoenix.PubSub

  def subscribe(game_code) do
    PubSub.subscribe(Pictionary.PubSub, "game-#{game_code}")
  end

  def broadcast_game_state(game_code, draw_update_data) do
    PubSub.broadcast(
      Pictionary.PubSub,
      "game-#{game_code}",
      {:draw_updated, draw_update_data}
    )
  end
end
