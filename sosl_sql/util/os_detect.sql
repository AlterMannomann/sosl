-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Requires SOSL login, based on the typical subprocesses Windows has with processes like 23928932:2323AAS.
-- Check system from SQLPlus side
SELECT CASE
         WHEN INSTR(process, ':') > 0
         THEN 'WINDOWS'
         ELSE 'UNIX'
       END AS os
  FROM v$session
 WHERE sid    = SYS_CONTEXT('USERENV', 'SID')
   AND ROWNUM = 1
;