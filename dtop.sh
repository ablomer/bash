#!/bin/bash

# First, get all container IDs and their stack names
declare -A stacks
while IFS= read -r container; do
    stack_name=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$container" 2>/dev/null || echo "no_stack")
    # If empty, mark as no_stack
    if [ -z "$stack_name" ]; then
        stack_name="no_stack"
    fi
    stacks["$container"]="$stack_name"
done < <(docker ps -q -a)

# Get unique stack names
declare -A stack_containers
for container in "${!stacks[@]}"; do
    stack_name="${stacks[$container]}"
    stack_containers["$stack_name"]+="$container "
done

# Process each stack
for stack_name in "${!stack_containers[@]}"; do
    echo -e "\033[1;36m=== $stack_name ===\033[0m"
    
    # Process each container in this stack
    for id in ${stack_containers[$stack_name]}; do
        name=$(docker inspect -f '{{.Name}}' "$id" | sed 's/\///')
        image=$(docker inspect -f '{{.Config.Image}}' "$id")
        command=$(docker inspect -f '{{.Config.Cmd}}' "$id")
        
        echo -e "\033[1;33mContainer ID: $id, Name: $name, Image: $image, Command: $command\033[0m"

        if docker inspect -f '{{.State.Running}}' "$id" 2>/dev/null | grep -q "true"; then
            docker top "$id" -eo pid,user,%cpu,rss,command | tail -n +2 | awk '
                BEGIN {
                    printf "%-8s %-8s %-5s %-7s %-8s\n", "PID", "USER", "%CPU", "Mem", "   COMMAND";
                }
                {
                    total_cpu += $3;
                    total_mem += $4;
                    printf "%-8s %-8s %-5s %-7.1fMB  %-8s\n", $1,$2,$3,$4/1024,$5;
                }
                END {
                    printf "\033[1m%-8s %-8s %-5.1f %-7.1fMB\033[0m\n", "Total", "", total_cpu, total_mem/1024;
                }
            '
        else
            echo "The container is not running"
        fi
        echo # Add a blank line to separate output
    done
done
