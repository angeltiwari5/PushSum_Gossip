defmodule PushSum do
    
    def listen(main_listener_pid, s, w, neighbors_pid_list, round_condition_ratio, is_terminated) do
        receive do
            {:main_message, message} -> 
                neighbors_pid_list = message

            {:pushsum_start, message} ->
                s = s / 2
                w = w / 2

                ratio = s / w
                round_condition_ratio = round_condition_ratio ++ [ratio]
                push_sum(s, w, neighbors_pid_list)

            {:message, message} ->
                if !is_terminated do
                    s = s + Enum.at(message, 0)
                    w = w + Enum.at(message, 1)

                    s = s / 2
                    w = w / 2

                    ratio = s / w

                    #IO.puts(inspect(self()) <> " --- " <> to_string ratio)
                    
                    if round_condition_ratio == nil || (length round_condition_ratio) < 4 do
                        round_condition_ratio = round_condition_ratio ++ [ratio]
                    else
                        round_condition_ratio = round_condition_ratio ++ [ratio]
                        round_condition_ratio = List.delete_at(round_condition_ratio, 0)
                    end

                    push_sum(s, w, neighbors_pid_list)
                end
            after 100 ->
                #IO.puts "No msg in mailbox for " <> inspect(self()) <> " after 100ms"
        end

        if round_condition_ratio != nil && (length round_condition_ratio) ==  4 do
            if !is_terminated do
                if abs((Enum.at(round_condition_ratio, 1) - Enum.at(round_condition_ratio, 0))) <= 0.0000000001 &&
                    abs((Enum.at(round_condition_ratio, 2) - Enum.at(round_condition_ratio, 1))) <= 0.0000000001 &&
                    abs((Enum.at(round_condition_ratio, 3) - Enum.at(round_condition_ratio, 2))) <= 0.0000000001 do
                    is_terminated = true
                    send main_listener_pid, { :message, "terminated" }
                end
            else
                :timer.sleep(100)
                push_sum(s, w, neighbors_pid_list)
            end 
        end

        listen(main_listener_pid, s, w, neighbors_pid_list, round_condition_ratio, is_terminated)
    end

    def push_sum(s, w, neighbors_pid_list) do
        if neighbors_pid_list != nil do
            random_pid = :rand.uniform(length neighbors_pid_list) - 1
            pid_to_gossip = Enum.at(neighbors_pid_list, random_pid)
            send pid_to_gossip, { :message, [] ++ [s] ++ [w]}
        end
    end

end
