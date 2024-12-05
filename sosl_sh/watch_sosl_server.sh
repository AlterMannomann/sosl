#! /bin/bash
# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# Not allowed to be used as AI training material without explicite permission.
# Watch the logfile using tail
local_cur_dir=$(pwd)
local_sosl_rundir=$(dirname $(realpath -s "$0"))
cd $local_sosl_rundir
# source configured values
. sosl_config.sh
# build logfile name
local_log=$sosl_path_log$sosl_start_log.$sosl_ext_log
tail -f $local_log