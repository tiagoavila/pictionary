defmodule Pictionary.GameStarterTest do
  use ExUnit.Case, async: true

  alias Pictionary.{GameServer, GameStarter, Player}

  test "changeset/1" do
    changeset =
      GameStarter.changeset(%{"game_code" => "", "name" => "Player2"})
      |> Map.put(:action, :validate)

    assert changeset.valid?
  end

  test "Create without game_code will create a new game" do
    {:ok, game} =
      GameStarter.create(%{"game_code" => "", "name" => "Player2"})

    assert game.game_code != nil
  end

  test "Create when game_code is provided will attempt to join a running game
    and will return errors if there's no game with given code" do
    {:error, changeset} =
      GameStarter.create(%{"game_code" => "AABB", "name" => "Player2"})

    assert changeset.valid? == false
    assert changeset.errors |> length() >= 1
    assert changeset.errors[:game_code] == {"There is no game running with this code", []}
  end

  test "Create when game_code is provided will attempt to join a running game
    and will return true if there's a game with given code" do
    game_code = "AAAB"
    {:ok, player} = Player.create("Player1")
    GameServer.start_or_join_game(game_code, player)

    result = GameStarter.create(%{"game_code" => game_code, "name" => "Player2"})

    assert {:ok, game} = result
  end
end
