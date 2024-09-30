REM Must be called from this directory to work
REM And example connection sosl/sosl@soslinstance must be set up for test
ECHO Call the test script using template
REM Switch to UTF8 and add an extra line with ECHO. to ensure that script call starts on a new line
CALL CHCP 65001 && (TYPE ..\..\sosl_templates\sosl_login.cfg && ECHO. && ECHO @..\sosl_sql\sosl_hello_world.sql) | sqlplus
ECHO Exit with %ERRORLEVEL%