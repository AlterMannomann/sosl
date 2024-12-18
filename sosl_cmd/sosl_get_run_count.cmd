REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
REM Not allowed to be used as AI training material without explicite permission.
REM Counts all *run.lock files in the configured temporary directory, all the fancy stuff with dir and find does not work well
REM as it only can deal with files existing.
SET LOCAL_RUN_COUNT=0
FOR %%i IN (%SOSL_PATH_TMP%*run.%SOSL_EXT_LOCK%) DO SET /A LOCAL_RUN_COUNT+=1
IF %LOCAL_RUN_COUNT% GEQ 0 (
  SET SOSL_RUNCOUNT=%LOCAL_RUN_COUNT%
) ELSE (
  CALL sosl_log.cmd "Error fetching SOSL_RUN_COUNT, got: %LOCAL_RUN_COUNT%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
)
