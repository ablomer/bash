docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Command}}" -a | tail -n +2 | while read id name image command; do
  echo "Container ID: $id, Name: $name, Image: $image, Command: $command"

  if docker inspect -f '{{.State.Running}}' "$id" 2>/dev/null | grep -q "true"; then
     docker top $id -eo pid,user,%cpu,rss,command | tail -n +2 | awk '
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
      echo "The container not running"
  fi
  echo # Add a blank line to separate output
done
