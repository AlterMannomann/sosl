REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Create a unique id, variable SOSL_GUID should be defined by the caller
REM Using BITSADMIN to create a GUID for a job and then cancel the job
FOR /f "delims={}" %%I IN ('bitsadmin /rawreturn /create guid') DO (
  SET TMP_GUID=%%~I
)
REM >NUL bitsadmin /cancel {%TMP_GUID%}
bitsadmin /cancel {%TMP_GUID%} 1>NUL
SET SOSL_GUID=%TMP_GUID%
SET TMP_GUID=
REM ECHO %SOSL_GUID%