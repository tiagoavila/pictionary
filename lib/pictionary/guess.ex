defmodule Pictionary.Guess do
  defstruct player_id: nil, guessed_word: nil

  @type t :: %__MODULE__{
          player_id: String.t(),
          guessed_word: String.t()
        }
end
