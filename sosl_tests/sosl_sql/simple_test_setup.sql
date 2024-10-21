-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CLEAR COLUMNS
-- clean everything before
DELETE FROM sosl_group_plan;
DELETE FROM sosl_batch_plan;
DELETE FROM sosl_script_group;
DELETE FROM sosl_batch_group;
DELETE FROM sosl_script;
COMMIT;
-- insert test script
INSERT INTO sosl_script (script_name, script_schema, script_description) VALUES ('..\sosl_tests\sosl_sql\sosl_hello_world.sql', 'sosl', 'SOSL basic test script');
COMMIT;
COLUMN SCRID NEW_VAL SCRID
SELECT script_id AS SCRID
  FROM sosl_script
;
INSERT INTO sosl_batch_group (batch_group_name, batch_group_description) VALUES ('SOSL Batch test group', 'SOSL basic test group');
COMMIT;
COLUMN GRPID NEW_VAL GRPID
SELECT batch_group_id AS GRPID
  FROM sosl_batch_group
;
INSERT INTO sosl_script_group (batch_group_id, script_id, batch_description) VALUES (&GRPID, &SCRID, 'SOSL test assignment group-script');
COMMIT;
COLUMN BATID NEW_VAL BATID
SELECT batch_id AS BATID
  FROM sosl_script_group
;
INSERT INTO sosl_batch_plan (plan_name, plan_active, plan_accepted) VALUES ('SOSL Test plan', 'YES', 'YES');
COMMIT;
COLUMN PLANID NEW_VAL PLANID
SELECT plan_id AS PLANID
  FROM sosl_batch_plan
;
INSERT INTO sosl_group_plan (plan_id, batch_group_id, plan_group_description) VALUES (&PLANID, &GRPID, 'SOSL Test plan group association');
COMMIT;
