defmodule PictionaryWeb.DrawUpdatesChannel do
  use PictionaryWeb, :channel

  @impl true
  def join("draw_updates:lobby", _payload, socket) do
    {:ok, assign(socket, :message, "Welcome to the Pictionary lobby!")}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    IO.puts("Received ping from client: #{inspect(payload)}")
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (draw_updates:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
