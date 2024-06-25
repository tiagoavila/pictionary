defmodule PictionaryWeb.HomeLive do
  @moduledoc """
  The `HomeLive` module is responsible for handling live requests for the home page.
  """

  use PictionaryWeb, :live_view

  def mount(_params, _session, socket) do
    message = "Hello Pictionary!"
    {:ok, assign(socket, message: message)}
  end
end
