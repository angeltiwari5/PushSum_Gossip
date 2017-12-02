defmodule Gossip do    
    def listen(main_listener_pid, msgcount, nplist, is_terminated, arbitrary_pid) do
        receive do
            {:main_message, message} -> 
                nplist = message        
                
            {:gossip_start, message} ->
                msgcount = msgcount + 1

            {:message, message} -> 
                msgcount = msgcount + 1

            after 100 -> nil
              	
        end

        if msgcount >= 5 && !is_terminated do
            is_terminated = true
            
            send main_listener_pid, { :message, "terminated" }
            listen(main_listener_pid, msgcount, nplist, is_terminated, arbitrary_pid) 
        else
            if is_terminated do
                
                :timer.sleep(1000)
                random_pid = :rand.uniform(length nplist) - 1
                pid_to_gossip = Enum.at(nplist, random_pid)
                send pid_to_gossip, { :message, ""}    
            end
            if msgcount > 0 do
                gossip(nplist, msgcount)
            end
            listen(main_listener_pid, msgcount, nplist, is_terminated, arbitrary_pid)
        end
    end

    def gossip(nplist, msgcount) do
        if nplist != nil && msgcount < 5 do
            random_pid = :rand.uniform(length nplist) - 1
            pid_to_gossip = Enum.at(nplist, random_pid)
            send pid_to_gossip, { :message, ""}

            random_pid = :rand.uniform(length nplist) - 1
            pid_to_gossip = Enum.at(nplist, random_pid)
            send pid_to_gossip, { :message, ""}
        end
    end

end
