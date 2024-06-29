defmodule Pictionary.GameServer do
  use GenServer
  require Logger

  alias __MODULE__
  alias Pictionary.{GameState, Player, Guess}

  @spec start_or_join_game(String.t(), any()) ::
          {:ok, :started, pid} | {:ok, :joined} | {:error, any()}
  def start_or_join_game(game_code, player_name) do
    case Horde.DynamicSupervisor.start_child(
           Pictionary.DistributedSupervisor,
           {GameServer, [game_code: game_code, player_name: player_name]}
         ) do
      {:ok, _pid} ->
        Logger.info("Started game server #{inspect(game_code)}")
        {:ok, :started}

      :ignore ->
        Logger.info("Game server #{inspect(game_code)} already running. Joining")

        {:ok, :joined}

        # case join_game(game_code, player) do
        #   {:ok, _} -> {:ok, :joined}
        #   {:error, _reason} = error -> error
        # end
    end
  end

  def child_spec(opts) do
    game_code = Keyword.get(opts, :game_code, GameServer)
    player_name = Keyword.fetch!(opts, :player_name)

    %{
      id: "#{__MODULE__}_#{game_code}",
      start: {__MODULE__, :start_link, [game_code, player_name]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  def start_link(game_code, player_name) do
    case GenServer.start_link(__MODULE__, {game_code, player_name}, name: via_tuple(game_code)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("already started at #{inspect(pid)}, returning :ignore")
        :ignore

      {:error, reason} ->
        {:error, reason}
    end
  end

  def init({game_code, player_name}) do
    {:ok, player} = Player.create(player_name)
    {:ok, GameState.create(game_code, player)}
  end

  def via_tuple(game_code) do
    game_code = String.upcase(game_code)
    {:via, Horde.Registry, {Pictionary.GameRegistry, game_code}}
  end
end
