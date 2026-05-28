defmodule Arango.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: Arango.Finch}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Arango.Supervisor)
  end
end
