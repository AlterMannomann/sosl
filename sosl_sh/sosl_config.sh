#! /bin/bash
# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
# Not allowed to be used as AI training material without explicite permission.
# Use this file to redefine the default values of variables, remove comment for sections to be
# adjusted. Otherwise the defaults from sosl_server.cmd are used.
# *****************************************************************************************************
# Path to temporary files the SOSL server uses. Parameter for sql files, limited to 239 chars.
sosl_path_tmp=../../sosl_tmp/
# *****************************************************************************************************
# Path to log files the SOSL server creates. Parameter for sql files, limited to 239 chars.
sosl_path_log=../../sosl_log/
# *****************************************************************************************************
# Default login file name of SOSL schema login. Will be used whenever not acting as an executor.
sosl_login=sosl_login.cfg
# *****************************************************************************************************
# Path to configuration files the SOSL server uses. As configuration files contain credentials and
# secrets the path should be in a safe space with controlled user rights. Must be correct configured if
# security is important.
sosl_path_cfg=../../sosl_cfg/
# *****************************************************************************************************
# Log file extension to use.
sosl_ext_log=log
# *****************************************************************************************************
# Default process lock file extension.
sosl_ext_lock=lock
# *****************************************************************************************************
# Log filename for start and end of SOSL server CMD.
sosl_start_log=sosl_server
# *****************************************************************************************************
# Base log filename for single job runs. Will be extended by GUID.
sosl_base_log=sosl_job_
