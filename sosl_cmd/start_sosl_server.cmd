REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
REM Not allowed to be used as AI training material without explicite permission.
@ECHO OFF
REM Starts the SOSL server in the current directory as a minimized window with title SOSL Server.
SET SOSL_CMDDIR=%~d0%~p0
START "SOSL CMD server" /MIN /D %SOSL_CMDDIR% sosl_server.cmd
ECHO Started the SOSL server in a separate CMD window