defmodule Project2 do     
    def listen(no_of_nodes_finished, numNodes, start_time, pid) do
        receive do
            {:listen_start_time, start_message} -> 
                start_time = :os.system_time(:millisecond)

            {:message, message} -> 
                no_of_nodes_finished = no_of_nodes_finished + 1
        end


        if no_of_nodes_finished >= numNodes do
            convergence_time = (:os.system_time(:millisecond) - start_time)
            IO.puts "Time taken to reach convergence(ms) : #{convergence_time}"
            send pid, {:message, ""}
        else
            listen(no_of_nodes_finished, numNodes, start_time, pid)
        end
    end

    def get_gossip_pidlist(numNodes, gossip_pidlist, main_listener_pid) do
        if numNodes == 0 do
            gossip_pidlist
        else
            gossip_pidlist = 
                gossip_pidlist ++ 
                [spawn(Gossip, :listen, [main_listener_pid, 0, nil, false, -1])]
            get_gossip_pidlist(numNodes - 1, gossip_pidlist, main_listener_pid)
        end
    end

    def get_pushsum_pidlist(numNodes, pushsum_pidlist, main_listener_pid, i) do
        if numNodes == 0 do
            pushsum_pidlist
        else
            pushsum_pidlist = 
                pushsum_pidlist ++ 
                [spawn(PushSum, :listen, [main_listener_pid, i, 1, nil, [], false])]
                get_pushsum_pidlist(numNodes - 1, pushsum_pidlist, main_listener_pid, i + 1)
        end
    end

    def start_gossip(neighbors_pidlist, main_pid) do
        send main_pid, { :listen_start_time, "" }

        Enum.each neighbors_pidlist,  fn {k, v} ->
            send k, { :main_message, v }
        end

        keys = Map.keys(neighbors_pidlist)
        key = Enum.at(keys, 0)
        send key, { :gossip_start, "string" }
        
    end

    def start_push_sum(neighbors_pidlist, main_pid) do
        
        send main_pid, { :listen_start_time, "" }

        Enum.each neighbors_pidlist,  fn {k, v} ->
            send k, { :main_message, v }
        end

        keys = Map.keys(neighbors_pidlist)
        key = Enum.at(keys, 0)
        send key, { :pushsum_start, "string" }
        
    end

    def get_neighbors_for_full(map, list, count) do
        if count == length list do
            map
        else
            map = Map.put(map, Enum.at(list, count), (List.delete_at(list, count)))
            get_neighbors_for_full(map, list, count + 1)
        end
    end

    def get_neighbors_for_line(map, list, count) do
        if count == length list do
            map
        else
            if count == 0 do
                map = Map.put(map, Enum.at(list, count), [] ++ [Enum.at(list, count + 1)])
                get_neighbors_for_line(map, list, count + 1)    

            else 
                if count == ((length list) - 1) do
                    map = Map.put(map, Enum.at(list, count), [] ++ [Enum.at(list, count - 1)])
                    get_neighbors_for_line(map, list, count + 1)    
                else
                    map = Map.put(map, Enum.at(list, count), [] ++ [Enum.at(list, count + 1)] ++ [Enum.at(list, count - 1)])
                    get_neighbors_for_line(map, list, count + 1)
                end
        
            end
        end
    end

    def build_neigbours_for_2D(neighbors_pidlist,pid_list,index,imperfect,length,size) do
        
            if(index == length) do
            neighbors_pidlist
        else
            val = get_neigbours_for_2D(index, size, pid_list, imperfect)
            neighbors_pidlist = Map.put(neighbors_pidlist,Enum.at(pid_list,index),val)
            index = index + 1
            build_neigbours_for_2D(neighbors_pidlist,pid_list,index,imperfect,length,size)
        end
    
    end

    def get_neigbours_for_2D(index,size,pid_list,imperfect) do
        hor = div(index,size)
        ver = rem(index,size)
            
        horizontal_neighbours = 
                cond do
                    ver == 0 -> [Enum.at(pid_list,index+1)]
                    ver == size - 1 -> [Enum.at(pid_list,index - 1)]
                    true ->  [Enum.at(pid_list, index - 1), Enum.at(pid_list, index + 1)]       
                end

            vertical_neighbours = 
                cond do
                    hor == 0 -> [Enum.at(pid_list,index+size)]
                    hor == size - 1 -> [Enum.at(pid_list,index - size)]
                    true ->  [Enum.at(pid_list, index - size), Enum.at(pid_list, index + size)]       
                end
            
            complete_neighbour = 
                if !imperfect do
                    horizontal_neighbours ++ vertical_neighbours
                
                else
                    complete_neighbour = horizontal_neighbours ++ vertical_neighbours
                    random_neighbour = get_random_neighbour(index, pid_list,complete_neighbour)
                    complete_neighbour ++ random_neighbour
                
                end

        complete_neighbour
    end 

    def get_random_neighbour(index, list, complete_neighbour) do
        Enum.take_random(list -- ([] ++ complete_neighbour ++ [Enum.at(list, index)]), 1)
    end

    def build_topologies(topology, pid_list) do
        neighbors_pidlist = Map.new

        case topology do
            "full" ->
                neighbors_pidlist = get_neighbors_for_full(neighbors_pidlist, pid_list, 0)
            "line" ->
                neighbors_pidlist = get_neighbors_for_line(neighbors_pidlist, pid_list, 0)
            "2D" -> 
                neighbors_pidlist = build_neigbours_for_2D(neighbors_pidlist,pid_list, 0, false, length(pid_list), round(:math.sqrt(length(pid_list))))
                    
            "imp2D" ->
                neighbors_pidlist = build_neigbours_for_2D(neighbors_pidlist, pid_list, 0, true, length(pid_list), round(:math.sqrt(length(pid_list))))
                    
        end
    end

    def main(args) do
        {_, options, _} = OptionParser.parse(args)

        if Enum.count(options) == 3 do

            numNodes = String.to_integer(Enum.at(options, 0))

            if numNodes <= 1 do
                IO.puts "Please enter a valid value for number of nodes : greater than 1"
                exit(:shutdown)
            end
            topology = Enum.at(options, 1)
            algorithm = Enum.at(options, 2)

            if topology == "2D" || topology == "imp2D" do
		if round(:math.sqrt(numNodes)) * round(:math.sqrt(numNodes)) !== numNodes do
                	numNodes =  round(:math.sqrt(numNodes)) * round(:math.sqrt(numNodes))
                	IO.puts "Number of nodes has been rounded off to " <> to_string numNodes
		end
            end

            main_pid = spawn(Project2, :listen, [0, numNodes, :os.system_time(:millisecond), self()])

            case algorithm do
                "gossip" ->
                    gossip_pidlist = get_gossip_pidlist(numNodes, [], main_pid)
                    neighbors_pidlist = build_topologies(topology, gossip_pidlist)
                    start_gossip(neighbors_pidlist, main_pid)
                "push-sum" ->
                    pushsum_pidlist = get_pushsum_pidlist(numNodes, [], main_pid, 1)
                    neighbors_pidlist = build_topologies(topology, pushsum_pidlist)
                    start_push_sum(neighbors_pidlist, main_pid)
            end
            
            receive do
                {:message, message} -> nil
            end
            
        end
    end

end
