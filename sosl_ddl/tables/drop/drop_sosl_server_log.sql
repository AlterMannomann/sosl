-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
REVOKE SELECT ON sosl_server_log FROM sosl_reviewer;
DROP TABLE sosl_server_log PURGE;