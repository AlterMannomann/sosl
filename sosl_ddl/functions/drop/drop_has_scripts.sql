-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- revoke grants
REVOKE EXECUTE ON has_scripts FROM sosl_guest;
REVOKE EXECUTE ON has_scripts FROM sosl_user;
REVOKE EXECUTE ON has_scripts FROM sosl_reviewer;
REVOKE EXECUTE ON has_scripts FROM sosl_executor;
REVOKE EXECUTE ON has_scripts FROM sosl_admin;
-- drop function
DROP FUNCTION has_scripts;