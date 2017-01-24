#!/usr/bin/env bash
START=$(date +%s.%N)
# do something #######################

"$@" &> /dev/null

#######################################
END=$(date +%s.%N)
DIFF=$( echo "scale=6; (${END} - ${START})*1/1" | bc )
echo "${DIFF}"