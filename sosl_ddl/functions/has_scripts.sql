-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE FUNCTION has_scripts
  RETURN NUMBER
IS
  /* Wrapper function for defined executor has_scripts functions.
  * Collects and sums the output of all defined executor has_scripts functions of active and reviewed executors that
  * return a number greater 0. Will log all functions in error.
  *
  * @return The amount of scripts waiting for all valid executor has_scripts functions or -1 if all functions have errors.
  */
  l_return            NUMBER;
  l_self_log_category sosl_server_log.log_category%TYPE := 'HAS_SCRIPTS';
  l_self_caller       sosl_server_log.caller%TYPE       := 'has_scripts wrapper';
BEGIN
  l_return := sosl_sys.has_scripts;
  RETURN l_return;
EXCEPTION
  WHEN OTHERS THEN
    -- log the error instead of RAISE
    sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
    RETURN -1;
END;
/
-- grants, everyone can see if scripts are available, inherited by others
GRANT EXECUTE ON has_scripts TO sosl_guest;
