@ECHO OFF
REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
SET CURRDIR=%CD%
ECHO called from %CURRDIR%
ECHO given dir: %~f1
ECHO change with CD
CD %~f1
ECHO current dir: %CD%
ECHO change with CD /D
CD /D %~f1
ECHO current dir: %CD%
ECHO go back to call directory
CD /D %CURRDIR%
