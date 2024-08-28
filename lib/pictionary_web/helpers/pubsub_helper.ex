defmodule PubSubHelper do
  @moduledoc """
  This module is responsible for managing the PubSub system in the PictionaryWeb application.
  """

  alias Phoenix.PubSub

  def subscribe(game_code) do
    PubSub.subscribe(Pictionary.PubSub, "game-#{game_code}")
  end

  def broadcast_game_state(game_code, coordinates, color) do
    PubSub.broadcast(
          Pictionary.PubSub,
          "game-#{game_code}",
          {:game_state_updated, %{coordinates: coordinates, color: color}}
        )
  end
end
