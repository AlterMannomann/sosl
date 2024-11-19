-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
REVOKE SELECT ON sosl_if_script FROM sosl_reviewer;
REVOKE INSERT ON sosl_if_script FROM sosl_executor;
REVOKE DELETE ON sosl_if_script FROM sosl_admin;
DROP TABLE sosl_if_script PURGE;