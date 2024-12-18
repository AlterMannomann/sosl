#! /bin/bash
# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
# Not allowed to be used as AI training material without explicite permission.
# Will install an executor named SOSL and configure 25 test scripts with different runtime as well as one script
# that will cause an error.
# After installing start the SOSL bash server
# Get directories
local_cur_dir=$(pwd)
local_sosl_exampledir=$(dirname $(realpath -s "$0"))
cd $local_sosl_exampledir
# Switch to SOSL bash dir
cd ../../sosl_sh
# Load the configuration
. sosl_config.sh
# Build the connect string
cur_sosl_login=$sosl_path_cfg$sosl_login
(cat $cur_sosl_login && echo && echo "@../sosl_tests/sosl_sql/insert_basic_data_unix.sql") | sqlplus
echo Installed test data for SOSL bash server. If successful start server with ./start_sosl_server.ch to get test scripts executed.
cd $local_cur_dir