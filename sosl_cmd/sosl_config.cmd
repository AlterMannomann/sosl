REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Use this file to redefine the default values of variables, remove comment for sections to be
REM adjusted. Otherwise the defaults from sosl_server.cmd are used.
REM *****************************************************************************************************
REM Path to temporary files the SOSL server uses. Parameter for sql files, limited to 239 chars.
SET SOSL_PATH_TMP=..\..\sosl_tmp\
REM *****************************************************************************************************
REM Path to log files the SOSL server creates. Parameter for sql files, limited to 239 chars.
SET SOSL_PATH_LOG=..\..\sosl_log\
REM *****************************************************************************************************
REM Default login file name of SOSL schema login. Will be used whenever not acting as an executor.
SET SOSL_LOGIN=sosl_login.cfg
REM *****************************************************************************************************
REM Path to configuration files the SOSL server uses. As configuration files contain credentials and
REM secrets the path should be in a safe space with controlled user rights. Must be correct configured if
REM security is important.
SET SOSL_PATH_CFG=..\..\sosl_cfg\
REM *****************************************************************************************************
REM Log file extension to use.
REM SET SOSL_EXT_LOG=log
REM *****************************************************************************************************
REM Default process lock file extension.
REM SET SOSL_EXT_LOCK=lock
REM *****************************************************************************************************
REM Log filename for start and end of SOSL server CMD.
REM SET SOSL_START_LOG=sosl_server
REM *****************************************************************************************************
REM Base log filename for single job runs. Will be extended by GUID.
REM SET SOSL_BASE_LOG=sosl_job_
