defmodule Pictionary.GameStarter do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pictionary.GameStarter
  alias Pictionary.GameServer

  @alphabet [
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z"
  ]

  embedded_schema do
    field(:player_name, :string)
    field(:game_code, :string)
    # field(:type, Ecto.Enum, values: [:start, :join], default: :start)
  end

  @type t :: %__MODULE__{
          player_name: String.t(),
          game_code: String.t()
        }

  def changeset(attrs \\ %{}) do
    %__MODULE__{}
    |> cast(attrs, [:player_name, :game_code])
    |> validate_required([:player_name])
    |> validate_length(:player_name, max: 50)
    |> validate_length(:game_code, is: 4)
  end

  @spec create(
          :invalid
          | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: {:error, Ecto.Changeset.t()} | {:ok, GameStarter.t()}
  def create(attrs \\ %{}) do
    attrs
    |> changeset()
    |> validate_if_there_is_a_game_running()
    |> generate_game_code_if_creation()
    |> apply_action(:create)
  end

  defp validate_if_there_is_a_game_running(changeset) do
    with true <- changeset.valid?,
         game_code <- get_change(changeset, :game_code),
         false <- is_nil(game_code) do
      case GameServer.is_server_running?(game_code) do
        true -> changeset
        false -> add_error(changeset, :game_code, "There is no game running with this code")
      end
    else
      _ -> changeset
    end
  end

  defp generate_game_code_if_creation(changeset) do
    with true <- changeset.valid?,
         game_code <- get_change(changeset, :game_code),
         true <- is_nil(game_code) do
      case generate_game_code() do
        {:ok, code} -> put_change(changeset, :game_code, code)
        {:error, reason} -> add_error(changeset, :game_code, reason)
      end
    else
      _ -> changeset
    end
  end

  @doc """
  Generates a unique game code.
  """
  def generate_game_code() do
    codes =
      1..3
      |> Enum.map(fn _ -> Enum.map_join(1..4, fn _ -> Enum.random(@alphabet) end) end)

    case Enum.find(codes, &(!GameServer.is_server_running?(&1))) do
      nil -> {:error, "Didn't find unused code, try again later"}
      code -> {:ok, code}
    end
  end
end
