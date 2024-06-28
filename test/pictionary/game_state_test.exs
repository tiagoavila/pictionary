defmodule Pictionary.GameStateTest do
  use ExUnit.Case
  alias Pictionary.{GameState, Player}

  test "new/2" do
    {:ok, player1} = Player.create(%{name: "John"})
    game_state = GameState.new("123", player1)
    assert game_state.code == "123"
    assert game_state.status == :not_started
    assert Map.keys(game_state.players) |> length() == 1
    assert game_state.players == %{player1.id => player1}
  end

  describe "join/2" do
    test "Join with available spots" do
      {:ok, player1} = Player.create(%{name: "John"})
      {:ok, player2} = Player.create(%{name: "Jane"})
      game_state = GameState.new("123", player1)
      game_state = GameState.join(game_state, player2)
      assert Map.keys(game_state.players) |> length() == 2
      assert Map.has_key?(game_state.players, player1.id)
      assert Map.has_key?(game_state.players, player2.id)
    end

    test "Join with Maximum players" do
      {:ok, player1} = Player.create(%{name: "John"})
      {:ok, player2} = Player.create(%{name: "Jane"})
      {:ok, player3} = Player.create(%{name: "Jack"})
      {:ok, player4} = Player.create(%{name: "Jill"})
      {:ok, player5} = Player.create(%{name: "Jim"})
      {:ok, player6} = Player.create(%{name: "Jill"})
      {:ok, player7} = Player.create(%{name: "Jill"})
      {:ok, player8} = Player.create(%{name: "Jill"})
      {:ok, player9} = Player.create(%{name: "Jill"})
      {:ok, player10} = Player.create(%{name: "Jill"})
      {:ok, player11} = Player.create(%{name: "Jill"})
      game_state = GameState.new("123", player1)
      game_state = GameState.join(game_state, player2)
      game_state = GameState.join(game_state, player3)
      game_state = GameState.join(game_state, player4)
      game_state = GameState.join(game_state, player5)
      game_state = GameState.join(game_state, player6)
      game_state = GameState.join(game_state, player7)
      game_state = GameState.join(game_state, player8)
      game_state = GameState.join(game_state, player9)
      game_state = GameState.join(game_state, player10)
      game_state = GameState.join(game_state, player11)
      assert game_state == {:error, "Max players reached"}
    end
  end

  describe "guess/3" do
    test "Guess correctly" do
      {:ok, player1} = Player.create(%{name: "John"})
      game_state = GameState.new("123", player1)
      game_state = GameState.join(game_state, player1)
      game_state = %{game_state | word: "apple"}

      {result, game_state} = GameState.guess(game_state, player1.id, "apple")
      assert result == :guessed_correctly
      assert Map.get(game_state.players, player1.id).score == player1.score + 1
    end

    test "Guess incorrectly" do
      {:ok, player1} = Player.create(%{name: "John"})
      game_state = GameState.new("123", player1)
      game_state = GameState.join(game_state, player1)
      game_state = %{game_state | word: "apple"}

      {result, _} = GameState.guess(game_state, player1.id, "banana")
      assert result == :guessed_incorrectly
    end
  end
end
