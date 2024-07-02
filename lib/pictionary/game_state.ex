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
            guesses: [],
            players_queue: []

  @type t :: %__MODULE__{
          code: String.t(),
          drawing_player_id: String.t(),
          status: :not_started | :in_progress | :in_progress_waiting_for_word | :finished,
          players: %{String.t() => Player.t()},
          word: String.t(),
          # draw: Pictionary.Draw.t(),
          draw: String.t(),
          guesses: [Guess.t()],
          players_queue: [Qex.t()]
        }

  @spec create(String.t(), Pictionary.Player.t()) :: Pictionary.GameState.t()
  def create(code, %Player{} = player1) do
    %__MODULE__{
      code: code,
      players: %{player1.id => player1},
      players_queue: Qex.new([player1.id])
    }
  end

  @spec join(Pictionary.GameState.t(), Pictionary.Player.t()) ::
          {:error, <<_::152>>} | {:joined, Pictionary.GameState.t()}
  def join(%__MODULE__{} = game_state, %Player{} = player) do
    case Map.keys(game_state.players) |> length() do
      n when n < @max_players ->
        {:joined,
         %{
           game_state
           | players: Map.put(game_state.players, player.id, player),
             players_queue: Qex.push(game_state.players_queue, player.id)
         }}

      _ ->
        {:error, "Max players reached"}
    end
  end

  @spec guess(Pictionary.GameState.t(), String.t(), String.t()) ::
          {:guessed_correctly, Pictionary.GameState.t()}
          | {:guessed_incorrectly, Pictionary.GameState.t()}
  def guess(%__MODULE__{} = game_state, player_id, guessed_word) do
    guess = %Guess{player_id: player_id, guessed_word: guessed_word}
    game_state = %{game_state | guesses: game_state.guesses ++ [guess]}

    case game_state.word do
      ^guessed_word ->
        {:guessed_correctly, game_state |> update_score_after_guessed_word(player_id)}

      _ ->
        {:guessed_incorrectly, game_state}
    end
  end

  @spec set_drawing_player_from_queue(Pictionary.GameState.t()) :: Pictionary.GameState.t()
  def set_drawing_player_from_queue(%__MODULE__{} = game_state) do
    {drawing_player_id, queue} = Qex.pop!(game_state.players_queue)

    %{
      game_state
      | drawing_player_id: drawing_player_id,
        players_queue: Qex.push(queue, drawing_player_id)
    }
  end

  @spec set_word(Pictionary.GameState.t(), String.t()) :: Pictionary.GameState.t()
  def set_word(%__MODULE__{} = game_state, word) do
    %{game_state | word: word}
  end

  defp update_score_after_guessed_word(%__MODULE__{} = game_state, player_id) do
    player = Map.get(game_state.players, player_id)
    player = %{player | score: player.score + 1}
    %{game_state | players: Map.put(game_state.players, player_id, player)}
  end
end
