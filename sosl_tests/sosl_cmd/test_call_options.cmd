@ECHO OFF
REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
SET MYGOTO=:NEXT
GOTO %MYGOTO%
ECHO Did not work GOTO with variable
:NEXT
ECHO Variable GOTO works
ECHO Call :MYCALL
CALL :MYCALL
ECHO Continue after mycall
ECHO Goto :END_TEST
GOTO :END_TEST
:MYCALL
ECHO Reached :MYCALL Do something
REM Check GOTO for error handling - can't jump to end immediate if called
IF %MYGOTO%==:NEXT GOTO :END_TEST
REM Important to go to :EOF after doing something, so call will return to caller, not to next label
GOTO :EOF

:END_TEST
ECHO End reached
GOTO :EOF
