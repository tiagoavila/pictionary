defmodule Pictionary.GameStateTest do
  use ExUnit.Case
  alias Pictionary.{GameState, Player}

  setup_all do
    {:ok, player1} = Player.create("John")
    game_state = GameState.create("123", player1)
    {:ok, game_state: game_state, player1: player1}
  end

  test "new/2", %{game_state: game_state, player1: player1} do
    assert game_state.code == "123"
    assert game_state.status == :not_started
    assert Map.keys(game_state.players) |> length() == 1
    assert game_state.players == %{player1.id => player1}
  end

  describe "join/2" do
    test "Join with available spots", %{game_state: game_state, player1: player1} do
      {:ok, player2} = Player.create("Jane")
      {:joined, game_state} = GameState.join(game_state, player2)
      assert Map.keys(game_state.players) |> length() == 2
      assert Map.has_key?(game_state.players, player1.id)
      assert Map.has_key?(game_state.players, player2.id)
    end

    test "Join with Maximum players", %{game_state: game_state} do
      {:ok, player2} = Player.create("Jane")
      {:ok, player3} = Player.create("Jane")
      {:ok, player4} = Player.create("Jane")
      {:ok, player5} = Player.create("Jane")
      {:ok, player6} = Player.create("Jane")
      {:ok, player7} = Player.create("Jane")
      {:ok, player8} = Player.create("Jane")
      {:ok, player9} = Player.create("Jane")
      {:ok, player10} = Player.create("Jane")
      {:ok, player11} = Player.create("Jane")
      {:joined, game_state} = GameState.join(game_state, player2)
      {:joined, game_state} = GameState.join(game_state, player3)
      {:joined, game_state} = GameState.join(game_state, player4)
      {:joined, game_state} = GameState.join(game_state, player5)
      {:joined, game_state} = GameState.join(game_state, player6)
      {:joined, game_state} = GameState.join(game_state, player7)
      {:joined, game_state} = GameState.join(game_state, player8)
      {:joined, game_state} = GameState.join(game_state, player9)
      {:joined, game_state} = GameState.join(game_state, player10)
      result = GameState.join(game_state, player11)
      assert result == {:error, "Max players reached"}
    end
  end

  describe "guess/3" do
    test "Guess correctly", %{game_state: game_state, player1: player1} do
      {:ok, player2} = Player.create("Jane")
      {:joined, game_state} = GameState.join(game_state, player2)
      game_state = GameState.set_word(game_state, "apple")

      {result, game_state} = GameState.guess(game_state, player1.id, "apple")
      assert result == :guessed_correctly
      assert Map.get(game_state.players, player1.id).score == player1.score + 1
    end

    test "Guess incorrectly", %{game_state: game_state, player1: player1} do
      {:ok, player2} = Player.create("Jane")
      {:joined, game_state} = GameState.join(game_state, player2)
      game_state = %{game_state | word: "apple"}

      {result, _} = GameState.guess(game_state, player1.id, "banana")
      assert result == :guessed_incorrectly
    end
  end

  describe "set_word/2" do
    test "Set word", %{game_state: game_state} do
      word = "apple"
      game_state = GameState.set_word(game_state, word)
      assert game_state.word == word
    end
  end

  describe "set_drawing_player_from_queue/1" do
    test "Set new drawing player from queue", %{game_state: game_state, player1: player1} do
      {:ok, player2} = Player.create("Jane")
      {:joined, game_state} = GameState.join(game_state, player2)
      game_state = GameState.set_drawing_player_from_queue(game_state)
      assert game_state.drawing_player_id == player1.id

      game_state = GameState.set_drawing_player_from_queue(game_state)
      assert game_state.drawing_player_id == player2.id
    end
  end
end
