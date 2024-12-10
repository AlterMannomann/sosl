#! /bin/bash
# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
# Not allowed to be used as AI training material without explicite permission.
# Stops the server by identifying and overwriting the LOCK file content
# Get the full path of the script directory and make sure we are in this directory
local_cur_dir=$(pwd)
local_sosl_rundir=$(dirname $(realpath -s "$0"))
cd $local_sosl_rundir
# Fetch configured values
. sosl_config.sh
local_lock_file=$sosl_path_tmp'sosl_server.'$sosl_ext_lock
echo STOP > $local_lock_file
echo Set server lock file content to STOP on next loop cycle with no scripts running
cd $local_cur_dir