#!/bin/bash

# =============================================================================
# Author: Daniel Doezema
# Author URI: http://dan.doezema.com
# 
# Copyright (c) 2013, Daniel Doezema
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * The names of the contributors and/or copyright holder may not be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL DANIEL DOEZEMA BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# =============================================================================

# == FUNCTIONS ================================================================

function get_current_tty {
  local TTY_PATH=`tty` # => /dev/ttys003
  echo ${TTY_PATH:5}   # => ttys003
}

function get_zeus_ps_lines {
  echo "`ps -o tty,pid,stat,command -ax | grep ^$CURRENT_TTY.*`"
}

# @param $LINE - a `get_zeus_ps_lines` line.
function get_ps_line_pid {
  local LINE=$1
  local INDEX="0"
  for PART in $1; do
    if [[ $INDEX -eq "1" ]]; then echo $PART; break; fi
    INDEX=$(($INDEX+1))
  done
}

# @param $LINE - a `get_zeus_ps_lines` line.
function get_ps_line_state {
  local LINE=$1
  local INDEX="0"
  for PART in $1; do
    if [[ $INDEX -eq "2" ]]; then echo ${PART:0:1}; break; fi
    INDEX=$(($INDEX+1))
  done
}

# @param $LINE - a `get_zeus_ps_lines` line.
function get_ps_line_command {
  local LINE=$1
  local INDEX="1"
  local CMD=""
  for PART in $1; do
    if [[ $INDEX -gt "1" ]]; then CMD="$CMD $PART"; fi
    INDEX=$(($INDEX+1))
  done
  echo $CMD
}

function is_zeus_running {
  if [[ `get_zeus_ps_lines | grep start | wc -l` -eq "2" ]]; then echo "1"; else echo "0"; fi
}

# @param $PID - a process id.
function pid_exists {
  ps -p $1 &> /dev/null
  if [[ $? -eq 0 ]]; then echo "1"; else echo "0"; fi
}

function get_latest_zeus_output {
  local INDEX="0"
  
  while read LINE; do 
    # Stop if we hit the last updated mark.
    if [[ `echo "$LINE" | grep ====` != "" ]]; then break; fi
    REVERSE_OUTPUT_LINES[$INDEX]="${LINE}"
    INDEX=$(($INDEX+1))
  done <<< "$(tail -r -n 50 $ZEUS_OUTPUT_FILE)"

  for (( INDEX=${#REVERSE_OUTPUT_LINES[@]}-1 ; INDEX>=0 ; INDEX-- )) ; do
    echo ${REVERSE_OUTPUT_LINES[INDEX]}
  done
}

function start_zeus_in_background {
  zeus start &> $ZEUS_OUTPUT_FILE &
  ZEUS_PID=$! # Notice, not a local variable.
  echo $ZEUS_PID > $ZEUS_PID_FILE # Write PID to file.
}

function block_until_zeus_is_loaded {
  local POLL_DELAY_SECONDS="0.5"
  local POLL_TIMEOUT_SECONDS="30"
  local POLL_ELAPSED_SECONDS="0"
  local POLL_COUNT="0"

  local STATUSES=""
  local STATUSES_POLL=""
  local STATUSES_SAME_COUNT="0"
  
  while [ true ]; do
    STATUSES_POLL=""
    while read -r LINE; do
        local PROCESSES_STATE=`get_ps_line_state "$LINE"`
        local PROCESSES_CMD=`get_ps_line_command "$LINE"`
                
        if [[ "$PROCESSES_CMD" == *zeus\ slave:* ]]; then
          STATUSES_POLL="${STATUSES_POLL}${PROCESSES_STATE}"
        fi
    done <<< "`get_zeus_ps_lines`"
    
    # Keep track of how many times the stats has stayed the same over polls
    STATUSES_SAME_COUNT=$((STATUSES_SAME_COUNT + 1))
    if [[ "$STATUSES" != "$STATUSES_POLL" ]]; then STATUSES_SAME_COUNT="0"; fi

    # Save the current poll status to the main statues variable (e.g, SSR, SSSR, SSSSS)
    STATUSES=$STATUSES_POLL
    
    # Loading Message ...
    printf "Loading Zeus Processes "
    for (( idx="0" ; idx<=$POLL_COUNT ; idx++ )) ; do printf "."; done
    printf "\r"
    
    # When 3 checks are confirmed && 2 or more zeus slave processes are in "S" (sleep) state -- break the loop
    if [[ `echo $STATUSES | grep -e "^S\{2,\}$"` != "" ]] && [[ $STATUSES_SAME_COUNT == 3 ]]; then 
      printf "\n"
      break 
    fi
    
    # Timeout Check
    ELAPSED_SECONDS=$(echo "$POLL_DELAY_SECONDS * $POLL_COUNT" | bc)
    if [[ $(echo "$ELAPSED_SECONDS > $POLL_TIMEOUT_SECONDS" | bc) == "1" ]]; then
      echo "ERROR: Start Up Polling Timeout Reached - Killing Zeus Process: $ZEUS_PID"
      kill $ZEUS_PID
      exit 1
    fi

    POLL_COUNT=$(($POLL_COUNT+1))
    sleep $POLL_DELAY_SECONDS    
  done
}

function check_if_zeus_is_running {
  if [[ `is_zeus_running` -eq "1" ]]; then 
    if [[ $ZEUS_PID != false ]]; then printf "[PID: $ZEUS_PID] - "; fi
    printf "Zeus is already running.\n\r"
    echo "$(get_latest_zeus_output)"

    if [[ $ZEUS_PID != false ]]; then 
      echo ""
      read -n 1 -p "${TBOLD}ACTIONS:${TNORMAL} [${TBOLD}R${TNORMAL}]estart Zeus, [${TBOLD}K${TNORMAL}]ill Zeus, [${TBOLD}c${TNORMAL}]ontinue? [${TBOLD}RKc${TNORMAL}]: " RESPONSE
      echo ""
      if [[ "$RESPONSE" == "K" ]]; then
        echo "[PID: $ZEUS_PID] - Killing Existing Zeus Processes."
        kill $ZEUS_PID
        exit 0
      elif [[ "$RESPONSE" == "R" ]]; then
        echo "[PID: $ZEUS_PID] - Killing Existing Zeus Processes."
        kill $ZEUS_PID
      else # Continue
        exit 0 
      fi
    else
      # Zues is running, but this script did not start it -- bail out!
      exit 0
    fi
  fi
}

function bootstrap {
  # Text Style Variables
  TBOLD=`tput bold`
  TNORMAL=`tput sgr0`
    
  # Set Current TTY
  CURRENT_TTY=`get_current_tty` # => ttys003

  # Set the Zeus Meta Directory
  ZEUS_META_DIR="$HOME/.zeus.meta/$CURRENT_TTY/"

  # Set the PID File path
  ZEUS_PID_FILE="${ZEUS_META_DIR}start.pid"

  # Set the zeus output file path.
  ZEUS_OUTPUT_FILE="${ZEUS_META_DIR}output.txt"

  # Check if zeus pid directory needs to be created.
  if [[ ! -d $ZEUS_META_DIR ]]; then mkdir -p $ZEUS_META_DIR; fi

  # Attempt to get the PID of the `zeus start` command.
  ZEUS_PID=false
  if [[ -e $ZEUS_PID_FILE ]]; then
    ZEUS_PID=$(<$ZEUS_PID_FILE)
    
    # Check if the process is no longer running.
    if [[ `pid_exists $ZEUS_PID` -eq "0" ]]; then
      ZEUS_PID=false
      rm $ZEUS_PID_FILE
    fi
  fi
}

# == START OF EXECUTION =======================================================

bootstrap

check_if_zeus_is_running

start_zeus_in_background

echo "[PID: $ZEUS_PID] - Starting Zeus in background."

block_until_zeus_is_loaded

echo "[PID: $ZEUS_PID] - Zeus is now running."
echo "$(get_latest_zeus_output)"