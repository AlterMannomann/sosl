@ECHO OFF
REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
ECHO Expansion disabled
SETLOCAL DISABLEEXTENSIONS
ECHO Pure parameter: %1
ECHO Parameter not enclosed: %~1
ECHO Complete filename: %~f1
ECHO Complete path: %~dp1
ECHO Expansion enabled
SETLOCAL ENABLEEXTENSIONS
ECHO Pure parameter: %1
ECHO Parameter not enclosed: %~1
ECHO Complete filename: %~f1
ECHO Complete path: %~dp1
ECHO Expansion enabled
ENDLOCAL