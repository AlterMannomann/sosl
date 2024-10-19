-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- creates a basic internal queue using AQ, has to be started separately

-- first create the payload type for queue only header, no member function
CREATE OR REPLACE TYPE sosl_payload
  AS OBJECT
    /* This type is used by the internal message queue of SOSL. It does not provide any member functions
    * only fields to fill. Object initialization basic example:
    * DECLARE
    *   -- to access the type from other schemas, do not forget to qualify it with the SOSL schema used
    *   l_sosl_payload SOSL.SOSL_PAYLOAD;
    * BEGIN
    *   l_sosl_payload := sosl_payload(1, 'My script ID', '../../mydir/scriptfile.sql');
    * END;
    */
    ( executor_id    NUMBER(38, 0)  -- the executor_id from SOSL_EXECUTOR responsible for the script
    , ext_script_id  VARCHAR2(4000) -- the external script id managed by the executor
    , script_file    VARCHAR2(4000) -- the script file name with full or relative path on the server where SOSL is running locally
    )
;
/
-- create and start the queue using explicite AQ defaults, so if defaults change behavior is still the same
BEGIN
  DBMS_AQADM.CREATE_QUEUE_TABLE( queue_table => 'SOSL_SCRIPT_QUEUE'
                               , queue_payload_type => 'SOSL_PAYLOAD'
                               , storage_clause => NULL
                               , sort_list => NULL
                               , multiple_consumers => NULL
                               , message_grouping => DBMS_AQADM.NONE
                               , comment => 'Queue table that holds the external script id and executor_id to be processed. Needed for parallel requests from different executors.'
                               , auto_commit => NULL
                               , primary_instance => 0
                               , secondary_instance => 0
                               , compatible => NULL
                               , secure => FALSE
                               , replication_mode => DBMS_AQADM.NONE
                               );
  DBMS_AQADM.CREATE_QUEUE( queue_name => 'SOSL_SCRIPT_QUEUE'
                         , queue_table => 'SOSL_SCRIPT_QUEUE'
                         , queue_type => DBMS_AQADM.NORMAL_QUEUE
                         , max_retries => 5
                         , retry_delay => 0
                         , retention_time => 0
                         , dependency_tracking => FALSE
                         , comment => 'Queue that holds the external script id and executor_id to be processed. Needed for parallel requests from different executors.'
                         , auto_commit => TRUE
                         );
  DBMS_AQADM.START_QUEUE('SOSL_SCRIPT_QUEUE', TRUE, TRUE);
END;
/
