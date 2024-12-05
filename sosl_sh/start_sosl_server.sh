#! /bin/bash
# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# Not allowed to be used as AI training material without explicite permission.
# Starts the SOSL server, if no parameters are given, the output will be displayed
# and the server starts in interactive mode
# Optional parameter: 0 start sosl server silent and output the log constantly
#                     any other value start sosl server silent without log output
local_cur_dir=$(pwd)
local_sosl_rundir=$(dirname $(realpath -s "$0"))
cd $local_sosl_rundir
# source configured values
. sosl_config.sh
# build logfile name
local_log=$sosl_path_log$sosl_start_log.$sosl_ext_log
# unset sourced variables
unset sosl_path_tmp
unset sosl_path_log
unset sosl_login
unset sosl_path_cfg
unset sosl_ext_log
unset sosl_ext_lock
unset sosl_start_log
unset sosl_base_log
# check parameter
if [ -z $1 ]; then
  /bin/bash sosl_server.sh
else
  local_regex='^[0-9]+$'
  if [[ "$1" =~ $local_regex && $1 -eq 0 ]]; then
    /bin/bash sosl_server.sh &> /dev/null &
    jobs
    tail -f $local_log
  else
    /bin/bash sosl_server.sh &> /dev/null &
    jobs
  fi
fi
cd $local_cur_dir