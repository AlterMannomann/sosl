-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- stop queue and drop it afterwards
BEGIN
  DBMS_AQADM.STOP_QUEUE('SOSL_SCRIPT_QUEUE');
  DBMS_AQADM.DROP_QUEUE('SOSL_SCRIPT_QUEUE');
  DBMS_AQADM.DROP_QUEUE_TABLE('SOSL_SCRIPT_QUEUE');
END;
/
-- drop type for the queue
DROP TYPE sosl_payload;