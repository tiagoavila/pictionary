defmodule Pictionary.Player do
  @moduledoc """
  This module is responsible for managing the player state
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field(:name, :string)
    field(:score, :integer, default: 0)
  end

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          score: integer()
        }

  def changeset(params \\ %{}) do
    %Player{}
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, max: 30)
    |> generate_id()
  end

  @spec create(String.t()) :: {:error, Ecto.Changeset.t()} | {:ok, map()}
  def create(player_name) do
    %{name: player_name}
    |> changeset()
    |> apply_action(:create)
  end

  defp generate_id(changeset) do
    case get_change(changeset, :id) do
      nil -> put_change(changeset, :id, Ecto.UUID.generate())
      _ -> changeset
    end
  end
end
