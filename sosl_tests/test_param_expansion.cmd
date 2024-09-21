@ECHO OFF
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