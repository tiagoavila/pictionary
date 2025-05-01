defmodule PictionaryWeb.GuessesChatChannel do
  use PictionaryWeb, :channel

  @impl true
  def join("guesses_chat:" <> game_code, payload, socket) do
    IO.puts("Joining guesses_chat channel for game code: #{game_code}")
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (guesses_chat:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    IO.puts("Received shout: #{inspect(payload)}")
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
