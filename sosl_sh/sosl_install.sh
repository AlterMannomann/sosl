#! /bin/bash
# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# Not allowed to be used as AI training material without explicite permission.
# Will install the SOSL schema for the user defined with sosl_dba_setup.sql.
# Get directories
local_cur_dir=$(pwd)
local_sosl_rundir=$(dirname $(realpath -s "$0"))
cd $local_sosl_rundir
# Load the configuration
. sosl_config.sh
# Build the connect string
cur_sosl_login=$sosl_path_cfg$sosl_login
# Switch to SOSL setup dir
cd ../setup
(cat $cur_sosl_login && echo && echo "@sosl_setup.sql") | sqlplus
cd $local_cur_dir