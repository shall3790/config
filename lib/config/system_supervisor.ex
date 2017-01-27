# Starts the to-do system. Assumes that process registry is already started
# and working.

defmodule Config.SystemSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: :system_supervisor)
  end

  def init(_) do
    
    processes = [
      supervisor(Config.Database, ["./persist/"]),
      supervisor(Config.ServerSupervisor, []),
      worker(Config.Cache, []),
      worker(Config.Stash, [])
    ]
    supervise(processes, strategy: :one_for_one)
  end
end
