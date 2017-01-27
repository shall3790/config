defmodule Config.Server do
    use GenServer

    ##################
    # External API
    ##################
    def start_link(name) do
        IO.puts "starting config server (start_link) for config (name= #{name})"
        init_map = %{}
        # GenServer.start_link
        {:ok, pid} = GenServer.start_link(__MODULE__, name, name: via_tuple(name))
    end

    def ferror(config_server, num) do
        GenServer.call(config_server, {:increment_number, num})
    end

    def test(config_server, val) do
        GenServer.call(config_server, {:test, val});
    end

    def entries(config_server) do
        # IO.puts "looking up entries for config"
        GenServer.call(config_server, {:entries})
    end

    def put(config_server, key, value) do
        # IO.puts "adding key: " <> key <> ", value: " <> value
        GenServer.cast(config_server, {:put, key, value})
    end

    def get(config_server, key) do
        # IO.puts "reading key: " <> key
        GenServer.call(config_server, {:get, key})
        # GenServer.call(
    end

    def whereis(name) do
        #Config.ProcessRegistry.whereis_name({:config_server, name})
        :gproc.whereis_name({:n, :l, {:config_server, name}})
    end

    defp via_tuple(name) do
        #{:via, Config.ProcessRegistry, {:config_server, name}}
        {:via, :gproc, {:n, :l, {:config_server, name}}}
    end

    ##################
    # GenServer impl
    ##################
    def init(name) do
        # init_map = KvServer.Stash.get_value stash_pid
        # state
        #{ :ok, {init_map, stash_pid} }
        init_map = %{}
        # load state from stash process
        {:ok, {name, Config.Stash.get_value(name) || init_map} }

        # load state from db
        #{:ok, {name, Config.Database.get(name) || init_map} }
    end

    def handle_call( {:test, val}, _from, {name, state} ) do
        IO.puts "test call: " <> val
        IO.puts "calling stash server"
        Config.Stash.test(val)
        {:reply, val, {name, state} }
    end

    def handle_cast( {:increment_number, num}, {name, state} ) do
        v = num + 1
        {:reply, state }
    end

    def handle_cast({:put, key, value}, {name, state}) do
        #{:noreply, HashDict.put(state, key, value)}
        #This will only work if key is present
        #new_map = %{ state | key => value }
        new_map = Map.update(state, key, value, fn v -> value end)
        # persist to db
        
        #Config.Database.store(name, new_map)
        # send response
        {:noreply, {name, new_map} }
    end

    def handle_call({:entries}, _, {name, state}) do
        #IO.puts "loading entries for config: #{name}"

        {:reply, Map.keys(state), {name, state} }
    end

    def handle_call({:get, key}, _from, {name, state} ) do
        #{:reply, HashDict.get(state, key), state}
        {:reply, Map.get(state, key), {name, state} }
    end

    # on terminate save state to Stash
    def terminate(_reason, state) do
        IO.puts "Config.Server terminate - sending state to stash..."
        # IO.puts Map.keys(state)
        Config.Stash.test(state)
        # KvServer.Stash.save_value(stash_pid, state)
    end

    # def terminate(_reason, {current_number, stash_pid}) do
    #     Sequence.Stash.save_value stash_pid, current_number
    # end


    def format_status(_reason, [ _pdict, state ]) do
        [data: [{'State', "My current state is '#{inspect state}', and I'm happy"}]]
    end

     # Needed for testing purposes
    def handle_info(:stop, state), do: {:stop, :normal, state}
    def handle_info(_, state), do: {:noreply, state}
end
