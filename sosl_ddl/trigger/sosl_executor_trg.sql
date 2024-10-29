-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- requires login with the correct schema, either SOSL or your own SOSL schema
-- requires table to have been created before, as well as used packages
CREATE OR REPLACE TRIGGER sosl_executor_ins_trg
  BEFORE INSERT ON sosl_executor
  FOR EACH ROW
DECLARE
  l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_EXECUTOR';
  l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_executor_ins_trg';
BEGIN
  :NEW.created            := SYSDATE;
  :NEW.created_by         := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.created_by_os      := SYS_CONTEXT('USERENV', 'OS_USER');
  :NEW.updated            := SYSDATE;
  :NEW.updated_by         := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.updated_by_os      := SYS_CONTEXT('USERENV', 'OS_USER');
  :NEW.executor_active    := 0;
  :NEW.executor_reviewed  := 0;
  -- transform users and functions to UPPERCASE, no support currently for special mix-case.
  :NEW.function_owner       := UPPER(:NEW.function_owner);
  :NEW.db_user              := UPPER(:NEW.db_user);
  :NEW.fn_has_scripts       := UPPER(:NEW.fn_has_scripts);
  :NEW.fn_get_next_script   := UPPER(:NEW.fn_get_next_script);
  :NEW.fn_set_script_status := UPPER(:NEW.fn_set_script_status);
  :NEW.fn_send_db_mail      := UPPER(:NEW.fn_send_db_mail);
  -- check user
  IF NOT sosl_util.has_db_user(:NEW.db_user)
  THEN
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20005 The given database user "' || NVL(:NEW.db_user, sosl_constants.GEN_NULL_TEXT) || '" is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.'
                              , 'Wrong database user for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20005, 'The given database user "' || NVL(:NEW.db_user, sosl_constants.GEN_NULL_TEXT) || '" is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.');
  END IF;
  IF NOT sosl_util.has_db_user(:NEW.function_owner)
  THEN
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20006 The given function owner database user "' || NVL(:NEW.function_owner, sosl_constants.GEN_NULL_TEXT) || '" is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.'
                              , 'Wrong function owner for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20006, 'The given function owner database user "' || NVL(:NEW.function_owner, sosl_constants.GEN_NULL_TEXT) || '" is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.');
  END IF;
  -- check configured functions
  IF NOT sosl_util.has_function(:NEW.function_owner, :NEW.fn_has_scripts, 'NUMBER')
  THEN
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20007 The given function "' || NVL(:NEW.fn_has_scripts, sosl_constants.GEN_NULL_TEXT) || '" for has_scripts is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                              , 'Wrong function has_scripts for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20007, 'The given function "' || NVL(:NEW.fn_has_scripts, sosl_constants.GEN_NULL_TEXT) || '" for has_scripts is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_util.has_function(:NEW.function_owner, :NEW.fn_get_next_script, 'OBJECT')
  THEN
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20008 The given function "' || NVL(:NEW.fn_get_next_script, sosl_constants.GEN_NULL_TEXT) || '" for get_next_script is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype OBJECT or is not granted with EXECUTE rights to SOSL.'
                              , 'Wrong function get_next_script for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20008, 'The given function "' || NVL(:NEW.fn_get_next_script, sosl_constants.GEN_NULL_TEXT) || '" for get_next_script is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype OBJECT or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_util.has_function(:NEW.function_owner, :NEW.fn_set_script_status, 'NUMBER')
  THEN
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20009 The given function "' || NVL(:NEW.fn_set_script_status, sosl_constants.GEN_NULL_TEXT) || '" for set_script_status is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                              , 'Wrong function set_script_status for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20009, 'The given function "' || NVL(:NEW.fn_set_script_status, sosl_constants.GEN_NULL_TEXT) || '" for set_script_status is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  -- check mail
  IF :NEW.use_mail = 1
  THEN
    IF NOT sosl_util.has_function(:NEW.function_owner, :NEW.fn_send_db_mail, 'NUMBER')
    THEN
      sosl_log.minimal_error_log( l_self_caller
                                , l_self_log_category
                                , '-20010 The given function "' || NVL(:NEW.fn_send_db_mail, sosl_constants.GEN_NULL_TEXT) || '" for send_db_mail is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                                , 'Wrong function send_db_mail for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                )
      ;
      RAISE_APPLICATION_ERROR(-20010, 'The given function "' || NVL(:NEW.fn_send_db_mail, sosl_constants.GEN_NULL_TEXT) || '" for send_db_mail is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
    END IF;
  END IF;
  -- log the insert
  sosl_log.minimal_info_log( l_self_caller
                           , l_self_log_category
                           , 'A new executor named ' || :NEW.executor_name || ' has been defined for DB user: ' || :NEW.db_user || ' with function owner: ' || :NEW.function_owner || '.'
                           )
  ;
EXCEPTION
  WHEN OTHERS THEN
    -- catch and log all undefined exceptions
    IF SQLCODE NOT IN (-20005, -20006, -20007, -20008, -20009, -20010)
    THEN
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
    END IF;
    -- raise all errors
    RAISE;
END;
/
CREATE OR REPLACE TRIGGER sosl_executor_upd_trg
  BEFORE UPDATE ON sosl_executor
  FOR EACH ROW
DECLARE
  l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_EXECUTOR';
  l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_executor_upd_trg';
BEGIN
  :NEW.updated        := SYSDATE;
  :NEW.updated_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.updated_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  -- no overwrite for this values, log changes
  sosl_log.log_column_change(:OLD.created, :NEW.created, 'SOSL_EXECUTOR.CREATED', l_self_caller);
  :NEW.created := :OLD.created;
  sosl_log.log_column_change(:OLD.created_by, :NEW.created_by, 'SOSL_EXECUTOR.CREATED_BY', l_self_caller);
  :NEW.created_by := :OLD.created_by;
  sosl_log.log_column_change(:OLD.created_by_os, :NEW.created_by_os, 'SOSL_EXECUTOR.CREATED_BY_OS', l_self_caller);
  :NEW.created_by_os := :OLD.created_by_os;
  sosl_log.log_column_change(:OLD.function_owner, :NEW.function_owner, 'SOSL_EXECUTOR.FUNCTION_OWNER', l_self_caller);
  :NEW.function_owner := :OLD.function_owner;
  sosl_log.log_column_change(:OLD.db_user, :NEW.db_user, 'SOSL_EXECUTOR.DB_USER', l_self_caller);
  :NEW.db_user := :OLD.db_user;
  -- prepare possibly modified values
  sosl_log.log_column_change(:OLD.executor_active, :NEW.executor_active, 'SOSL_EXECUTOR.EXECUTOR_ACTIVE', l_self_caller, FALSE);
  sosl_log.log_column_change(:OLD.executor_reviewed, :NEW.executor_reviewed, 'SOSL_EXECUTOR.EXECUTOR_REVIEWED', l_self_caller, FALSE);
  sosl_log.log_column_change(:OLD.use_mail, :NEW.use_mail, 'SOSL_EXECUTOR.USE_MAIL', l_self_caller, FALSE);
  sosl_log.log_column_change(:OLD.fn_has_scripts, :NEW.fn_has_scripts, 'SOSL_EXECUTOR.FN_HAS_SCRIPTS', l_self_caller, FALSE);
  :NEW.fn_has_scripts := UPPER(:NEW.fn_has_scripts);
  sosl_log.log_column_change(:OLD.fn_get_next_script, :NEW.fn_get_next_script, 'SOSL_EXECUTOR.FN_GET_NEXT_SCRIPT', l_self_caller, FALSE);
  :NEW.fn_get_next_script := UPPER(:NEW.fn_get_next_script);
  sosl_log.log_column_change(:OLD.fn_set_script_status, :NEW.fn_set_script_status, 'SOSL_EXECUTOR.FN_SET_SCRIPT_STATUS', l_self_caller, FALSE);
  :NEW.fn_set_script_status := UPPER(:NEW.fn_set_script_status);
  sosl_log.log_column_change(:OLD.fn_send_db_mail, :NEW.fn_send_db_mail, 'SOSL_EXECUTOR.FN_SEND_DB_MAIL', l_self_caller, FALSE);
  :NEW.fn_send_db_mail := UPPER(:NEW.fn_send_db_mail);
  -- do all checks again including user
  -- check user
  IF NOT sosl_util.has_db_user(:NEW.db_user)
  THEN
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20005 The given database user "' || NVL(:NEW.db_user, sosl_constants.GEN_NULL_TEXT) || '" is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.'
                              , 'Wrong database user for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20005, 'The given database user "' || NVL(:NEW.db_user, sosl_constants.GEN_NULL_TEXT) || '" is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.');
  END IF;
  IF NOT sosl_util.has_db_user(:NEW.function_owner)
  THEN
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20006 The given function owner database user "' || NVL(:NEW.function_owner, sosl_constants.GEN_NULL_TEXT) || '" is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.'
                              , 'Wrong function owner for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20006, 'The given function owner database user "' || NVL(:NEW.function_owner, sosl_constants.GEN_NULL_TEXT) || '" is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.');
  END IF;
  -- check configured functions
  IF NOT sosl_util.has_function(:NEW.function_owner, :NEW.fn_has_scripts, 'NUMBER')
  THEN
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20007 The given function "' || NVL(:NEW.fn_has_scripts, sosl_constants.GEN_NULL_TEXT) || '" for has_scripts is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                              , 'Wrong function has_scripts for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20007, 'The given function "' || NVL(:NEW.fn_has_scripts, sosl_constants.GEN_NULL_TEXT) || '" for has_scripts is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_util.has_function(:NEW.function_owner, :NEW.fn_get_next_script, 'OBJECT')
  THEN
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20008 The given function "' || NVL(:NEW.fn_get_next_script, sosl_constants.GEN_NULL_TEXT) || '" for get_next_script is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype OBJECT or is not granted with EXECUTE rights to SOSL.'
                              , 'Wrong function get_next_script for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20008, 'The given function "' || NVL(:NEW.fn_get_next_script, sosl_constants.GEN_NULL_TEXT) || '" for get_next_script is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype OBJECT or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_util.has_function(:NEW.function_owner, :NEW.fn_set_script_status, 'NUMBER')
  THEN
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20009 The given function "' || NVL(:NEW.fn_set_script_status, sosl_constants.GEN_NULL_TEXT) || '" for set_script_status is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                              , 'Wrong function set_script_status for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20009, 'The given function "' || NVL(:NEW.fn_set_script_status, sosl_constants.GEN_NULL_TEXT) || '" for set_script_status is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  -- check mail
  IF :NEW.use_mail = 1
  THEN
    IF NOT sosl_util.has_function(:NEW.function_owner, :NEW.fn_send_db_mail, 'NUMBER')
    THEN
      sosl_log.minimal_error_log( l_self_caller
                                , l_self_log_category
                                , '-20010 The given function "' || NVL(:NEW.fn_send_db_mail, sosl_constants.GEN_NULL_TEXT) || '" for send_db_mail is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                                , 'Wrong function send_db_mail for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                )
      ;
      RAISE_APPLICATION_ERROR(-20010, 'The given function "' || NVL(:NEW.fn_send_db_mail, sosl_constants.GEN_NULL_TEXT) || '" for send_db_mail is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
    END IF;
  END IF;
  -- check grants if active and reviewed
  IF      :NEW.executor_active    = sosl_constants.NUM_YES
     AND  :NEW.executor_reviewed  = sosl_constants.NUM_YES
  THEN
    IF    NOT sosl_util.grant_role(:NEW.db_user, 'SOSL_USER')
       OR NOT sosl_util.grant_role(:NEW.function_owner, 'SOSL_EXECUTOR')
    THEN
      -- could not check or grant role to database user or function owner
      sosl_log.minimal_error_log( l_self_caller
                                , l_self_log_category
                                , '-20012 Error granting necessary roles to db user (SOSL_USER) or function owner (SOSL_EXECUTOR). Check setup and roles. Probably grant the roles manually before trying update again.'
                                , 'Failed granting necessary roles for SOSL_EXECUTOR table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                )
      ;
      RAISE_APPLICATION_ERROR(-20011, 'Error granting necessary roles to db user (SOSL_USER) or function owner (SOSL_EXECUTOR). Check setup and roles. Probably grant the roles manually before trying update again.');
    END IF;
  END IF;
  -- log the update
  sosl_log.minimal_info_log( l_self_caller
                           , l_self_log_category
                           , 'The configuration for executor ID: ' || :OLD.executor_id || ' named ' || :OLD.executor_name || ' has been updated.'
                           )
  ;
EXCEPTION
  WHEN OTHERS THEN
    -- catch and log all undefined exceptions
    IF SQLCODE NOT IN (-20005, -20006, -20007, -20008, -20009, -20010, -20011)
    THEN
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
    END IF;
    -- raise all errors
    RAISE;
END;
/
