#!/bin/bash

MEMORY=0.0

declare -A prev_name_max=()
declare -A curr_pid_name=()
declare -A curr_name_max=()

echo "pid    Name                                          CurrMem Max "
echo "====   ============================================  ======= ===="
printf "\n"




while true
do   
    IFS=$'\n'
    DATA=($("jps"))
    
    #clear previous loop output from screen
    tput cuu $(( ${#prev_name_max[@]} )) && tput el
    
    #for each we get in jps in current loop
    IFS=$' '
    for LINE in "${DATA[@]}"
    do
        read -ra TOKENS <<< "$LINE"
        
        #skip the process if its Jps or Jstat itself 
        if [ "${TOKENS[1]}" == "Jps" ] || [ "${TOKENS[1]}" == "Jstat" ] || [ "${TOKENS[0]}" -eq 0 ]
        then
            continue
        fi
        
        # insert to associative array
        curr_pid_name["${TOKENS[0]}"]=${TOKENS[1]}
        
        if [ ${prev_name_max["${TOKENS[1]}"]+_} ]; then
            curr_name_max["${TOKENS[1]}"]=${prev_name_max["${TOKENS[1]}"]}
        else
            curr_name_max["${TOKENS[1]}"]=0
        fi
        
    done


    #get the memroy use for each pid in curr_pid_name
    for pid in "${!curr_pid_name[@]}"; 
    do
        name=${curr_pid_name["$pid"]}
        MEMORY=$(jstat -gc $pid | tail -n 1 | awk '{split($0,a," "); sum=a[3]+a[4]+a[6]+a[8]; mb=sum/1024; print mb}')
        if (( ${prev_name_max[$name]+_}  )) && (( $(echo "${curr_name_max[$name]} < ${prev_name_max[$name]}" |bc -l) ));
        then
            curr_name_max["$name"]=${prev_name_max[$name]}
        else
            curr_name_max["$name"]=$MEMORY
        fi
            
        #output for current pid
        printf "%-6s %-45s %-7.2f %-7.2f\n" $pid $name $MEMORY ${curr_name_max["$name"]} | sort
    done
    
    
    
    
    #clean stuff of this iteration
    unset prev_name_max
    declare -A prev_name_max=()
    
    #insert all current name and max_memory into prev_associative_array
    for name in "${!curr_name_max[@]}";
    do
        prev_name_max[$name]=${curr_name_max[$name]}
    done
    
    #unset current associative array to make it empty
    unset curr_pid_name
    declare -A curr_pid_name=()
    unset curr_name_max
    declare -A curr_name_max=()

done