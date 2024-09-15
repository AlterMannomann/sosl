@ECHO OFF
REM get region independent timestamp for logs, DATETIME should be defined on caller level
REM SQL format equivalent is TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF6 -')
FOR /f %%a IN ('WMIC OS GET LocalDateTime ^| FIND "."') DO (
  SET DTS=%%a
)
REM format string
SET SOSL_DATETIME=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2% %DTS:~8,2%:%DTS:~10,2%:%DTS:~12,2%.%DTS:~15,6%
SET SOSL_DATETIME=%SOSL_DATETIME% -
REM remove temporary variable
SET DTS=
REM ECHO %SOSL_DATETIME%
@ECHO ON