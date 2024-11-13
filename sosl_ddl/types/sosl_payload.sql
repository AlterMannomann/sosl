-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- basic api exchange type, only header, no member function
CREATE OR REPLACE TYPE sosl_payload
  AS OBJECT
    /* This type is used to exchange information on executor, external script id and the script filename including
    * relative or full path which must exist on the server SOSL is running.
    * It does not provide any member functions only fields to fill. Object initialization basic example:
    * DECLARE
    *   -- to access the type from other schemas, do not forget to qualify it with the SOSL schema used
    *   l_sosl_payload SOSL.SOSL_PAYLOAD;
    * BEGIN
    *   l_sosl_payload := sosl_payload(1, 'My script ID', '../../mydir/scriptfile.sql');
    * END;
    */
    ( executor_id    NUMBER(38, 0)  -- the executor_id from SOSL_EXECUTOR_DEFINITION responsible for the script
    , ext_script_id  VARCHAR2(4000) -- the external script id managed by the executor
    , script_file    VARCHAR2(4000) -- the script file name with full or relative path on the server where SOSL is running locally
    )
;
/
GRANT EXECUTE ON sosl_payload TO sosl_executor;