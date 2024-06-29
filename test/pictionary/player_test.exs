defmodule Pictionary.PlayerTest do
  use ExUnit.Case
  alias Pictionary.Player

  test "changeset/1" do
    changeset = Player.changeset(%{})
    refute changeset.valid?
  end

  test "create/1" do
    {:ok, player} = Player.create("John")
    assert player.id != nil
    assert player.name == "John"
    assert player.score == 0
  end
end
