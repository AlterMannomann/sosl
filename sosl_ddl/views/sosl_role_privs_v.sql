-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE VIEW sosl_role_privs_v
AS
  SELECT grantee
       , granted_role
       , admin_option
       , delegate_option
       , default_role
       , common
       , inherited
    FROM dba_role_privs
         -- exclude SYS if not function owner
   WHERE (   grantee  != 'SYS'
          OR 'SYS'    IN (SELECT function_owner FROM sosl_executor_definition WHERE executor_active = 1 AND executor_reviewed = 1)
         )
         -- limit to SOSL roles, schema and function owners
     AND (   grantee LIKE 'SOSL\_%' ESCAPE '\'
          OR grantee    = (SELECT sosl_schema FROM sosl_install_v)
          OR grantee   IN (SELECT function_owner FROM sosl_executor_definition WHERE executor_active = 1 AND executor_reviewed = 1)
         )
   ORDER BY grantee
;
GRANT SELECT ON sosl_role_privs_v TO sosl_user;