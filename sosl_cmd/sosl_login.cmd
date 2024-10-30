REM @ECHO OFF
REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM This is a wrapper script that can be modified to produce a similar output.
REM It simply shows the content of the configuration file sosl_login.cfg in the configured directory with TYPE.
REM It relies on the variable SOSL_PATH_CFG to be configured.
TYPE %SOSL_PATH_CFG%%SOSL_LOGIN%