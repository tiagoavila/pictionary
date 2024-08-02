defmodule Pictionary.GameServerTest do
  use ExUnit.Case, async: true
  alias Pictionary.{GameServer, Player}

  describe "start_or_join_game/2" do
    test "Start a new game" do
      {:ok, player} = Player.create("John")
      assert {:ok, :started} == GameServer.start_or_join_game("ABCD", player)

      game_state = GameServer.get_current_state("ABCD")
      assert game_state.status == :not_started
      assert game_state.players |> Map.keys() |> length == 1
    end

    test "Join an existing game" do
      game_code = "EFGH"
      {:ok, player} = Player.create("John")
      {:ok, player2} = Player.create("Jane")
      assert {:ok, :started} == GameServer.start_or_join_game(game_code, player)
      assert {:ok, :joined} == GameServer.start_or_join_game(game_code, player2)

      game_state = GameServer.get_current_state(game_code)
      assert game_state.players |> Map.keys() |> length == 2
    end

    test "Join until reaches limit of players" do
      game_code = "IJKL"
      {:ok, player} = Player.create("Player1")
      assert {:ok, :started} == GameServer.start_or_join_game(game_code, player)

      player_names = [
        "Jane",
        "Jack",
        "Jill",
        "Jim",
        "Jenny",
        "Jared",
        "Jasmine",
        "Jesse",
        "Jared"
      ]

      Enum.reduce(player_names, {:ok, :started}, fn name, _ ->
        {:ok, player} = Player.create(name)
        assert {:ok, :joined} == GameServer.start_or_join_game(game_code, player)
        {:ok, :joined}
      end)

      game_state = GameServer.get_current_state(game_code)
      assert game_state.players |> Map.keys() |> length == 10

      {:ok, player} = Player.create("Carlos")
      assert {:error, "Max players reached"} == GameServer.start_or_join_game(game_code, player)
    end
  end

  describe "set_word/2" do
    test "Set word works" do
      game_code = "MNOP"
      word = "apple"
      {:ok, player} = Player.create("John")
      assert {:ok, :started} == GameServer.start_or_join_game(game_code, player)
      assert {:ok, :word_set} == GameServer.set_word(game_code, word)

      game_state = GameServer.get_current_state(game_code)
      assert game_state.word == word
    end
  end

  describe "guess_word/3" do
    test "Guess word incorrectly" do
      game_code = "QRST"
      {:ok, player} = Player.create("Player1")
      assert {:ok, :started} == GameServer.start_or_join_game(game_code, player)
      assert {:ok, :word_set} == GameServer.set_word(game_code, "apple")
      player_id = GameServer.get_current_state(game_code).players |> Map.keys() |> hd()

      assert :guessed_incorrectly == GameServer.guess_word(game_code, player_id, "banana")
    end

    test "Guess word correctly" do
      game_code = "UVWX"
      word = "apple"
      {:ok, player} = Player.create("John")
      assert {:ok, :started} == GameServer.start_or_join_game(game_code, player)
      assert {:ok, :word_set} == GameServer.set_word(game_code, word)
      player_id = GameServer.get_current_state(game_code).players |> Map.keys() |> hd()

      assert :guessed_correctly == GameServer.guess_word(game_code, player_id, word)
    end
  end
end
