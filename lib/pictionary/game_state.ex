defmodule Pictionary.GameState do
  @moduledoc """
  This module is responsible for managing the game state and actions like draw, guess, etc
  """
  alias Pictionary.{Player, Guess}

  @max_players 10

  defstruct code: nil,
            drawing_player_id: nil,
            status: :not_started,
            players: %{},
            word: nil,
            draw: nil,
            guesses: []

  @type t :: %__MODULE__{
          code: String.t(),
          drawing_player_id: String.t(),
          status: :not_started | :started | :finished,
          players: %{String.t() => Player.t()},
          word: String.t(),
          # draw: Pictionary.Draw.t(),
          draw: String.t(),
          guesses: [Guess.t()]
        }

  @spec new(String.t(), Pictionary.Player.t()) :: Pictionary.GameState.t()
  def new(code, %Player{} = player1) do
    %__MODULE__{code: code, players: %{player1.id => player1}}
  end

  @spec join(Pictionary.GameState.t(), Pictionary.Player.t()) ::
          {:error, <<_::152>>} | Pictionary.GameState.t()
  def join(%__MODULE__{} = game_state, %Player{} = player) do
    case Map.keys(game_state.players) |> length() do
      n when n < @max_players ->
        %{game_state | players: Map.put(game_state.players, player.id, player)}

      _ ->
        {:error, "Max players reached"}
    end
  end

  def guess(%__MODULE__{} = game_state, player_id, guessed_word) do
    guess = %Guess{player_id: player_id, guessed_word: guessed_word}
    game_state = %{game_state | guesses: game_state.guesses ++ [guess]}

    case game_state.word do
      ^guessed_word ->
        {:guessed_correctly,
         game_state |> update_score_after_guessed_word(player_id)}

      _ ->
        {:guessed_incorrectly, game_state}
    end
  end

  defp update_score_after_guessed_word(%__MODULE__{} = game_state, player_id) do
    player = Map.get(game_state.players, player_id)
    player = %{player | score: player.score + 1}
    %{game_state | players: Map.put(game_state.players, player_id, player)}
  end
end
