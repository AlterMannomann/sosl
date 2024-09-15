This folder contains the CMD script components of the Simple Oracle Script Loader.

Check system from SQLPlus side
SELECT CASE WHEN INSTR(process, ':') > 0 THEN 'WINDOWS' ELSE 'UNIX' END AS os FROM v$session WHERE sid = SYS_CONTEXT('USERENV', 'SID');