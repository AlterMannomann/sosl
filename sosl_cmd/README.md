This folder contains the CMD script components of the Simple Oracle Script Loader.

Notes:
- cd /D will change drive and directory
- rework to use CALL on labels, labels set SOSL_EXITCODE and SOSL_ERRMSG, will make file more readable
  - so the following should work
  - CALL :LABEL
  - IF %SOSL_EXITCODE%==-1 GOTO :error_label
  - :LABEL should have an GOTO :EOF after statements to return to caller correctly
- Use SOSL_FILE_CFG with full path to the configuration file used for login instead of path
- Keep path clean, no trailing \