defmodule Pictionary.GameServer do
  use GenServer
  require Logger

  alias __MODULE__
  alias Pictionary.{GameState, Player, Guess}

  @spec start_or_join_game(String.t(), Player.t()) ::
          {:ok, :started} | {:ok, :joined} | {:error, any()}
  def start_or_join_game(game_code, player) do
    case Horde.DynamicSupervisor.start_child(
           Pictionary.DistributedSupervisor,
           {GameServer, [game_code: game_code, player: player]}
         ) do
      {:ok, _pid} ->
        Logger.info("Started game server #{inspect(game_code)}")
        {:ok, :started}

      :ignore ->
        Logger.info("Game server #{inspect(game_code)} already running. Joining")

        case join_game(game_code, player) do
          {:ok, _} -> {:ok, :joined}
          {:error, _reason} = error -> error
        end
    end
  end

  def child_spec(opts) do
    game_code = Keyword.get(opts, :game_code, GameServer)
    player = Keyword.fetch!(opts, :player)

    %{
      id: "#{__MODULE__}_#{game_code}",
      start: {__MODULE__, :start_link, [game_code, player]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  def start_link(game_code, player) do
    case GenServer.start_link(__MODULE__, {game_code, player}, name: via_tuple(game_code)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("already started at #{inspect(pid)}, returning :ignore")
        :ignore

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec join_game(String.t(), Player.t()) :: any()
  def join_game(game_code, player) do
    GenServer.call(via_tuple(game_code), {:join, player})
  end

  def get_current_state(game_code) do
    GenServer.call(via_tuple(game_code), :get_current_state)
  end

  def set_word(game_code, word) do
    GenServer.call(via_tuple(game_code), {:set_word, word})
  end

  def guess_word(game_code, player_id, guessed_word) do
    GenServer.call(via_tuple(game_code), {:guess, player_id, guessed_word})
  end

  ##########################################################################################
  # Server Callbacks
  ##########################################################################################

  def init({game_code, player}) do
    {:ok, GameState.create(game_code, player)}
  end

  def handle_call(:get_current_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:join, player}, _from, state) do
    if is_server_running?(state.code) do
      case GameState.join(state, player) do
        {:joined, new_state} ->
          {:reply, {:ok, "#{player.name} joined the game"}, new_state}

        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:error, "Game not started"}, state}
    end
  end

  def handle_call({:set_word, word}, _from, state) do
    if is_server_running?(state.code) do
      {:reply, {:ok, :word_set}, GameState.set_word(state, word)}
    else
      {:reply, {:error, "Game not started"}, state}
    end
  end

  def handle_call({:guess, player_id, guessed_word}, _from, state) do
    if is_server_running?(state.code) do
      case GameState.guess(state, player_id, guessed_word) do
        {:guessed_correctly, new_state} ->
          {:reply, :guessed_correctly, new_state}

        {:guessed_incorrectly, new_state} ->
          {:reply, :guessed_incorrectly, new_state}
      end
    else
      {:reply, {:error, "Game not started"}, state}
    end
  end

  ##########################################################################################
  # Other functions
  ##########################################################################################

  def is_server_running?(game_code) do
    game_code = String.upcase(game_code)

    case Horde.Registry.lookup(Pictionary.GameRegistry, game_code) do
      [] -> false
      _ -> true
    end
  end

  def via_tuple(game_code) do
    game_code = String.upcase(game_code)
    {:via, Horde.Registry, {Pictionary.GameRegistry, game_code}}
  end
end
