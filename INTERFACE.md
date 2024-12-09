# Interface
The basic interface consist of mainly views and packages where access is managed by the SOSL role granted. You may define to whom to grant the interface using the available roles. Executors must have at least the SOSL_EXECUTOR role granted. You must use a defined function owner for every defined executor. If you don't define a script schema, the scripts executed are running under the privileges and schema of the login config file used.
## API
To use this application, interfaces exist, that must be configured in SOSL_EXECUTOR_DEFINITION. Only one set of API can be generated per executor. Executors may share the same function owner and function. In this case the interface API functions must handle by themselves the internal script states for the different executors running.

Error logging apart from noticing the error are out of scope for SOSL, the provided API function must manage this on its own. All configured functions must be granted as executable to the role SOSL_EXECUTOR, and afterwards configured in SOSL_EXECUTOR_DEFINITION. Functions must be visible for SOSL in ALL_OBJECTS and ALL_TAB_PRIVS. Package functions must be visible in ALL_ATTRIBUTES for SOSL.

    GRANT EXECUTE ON your_api_function TO SOSL_EXECUTOR;

The basic SOSL API consist of wrapper functions that will call the configured interface functions.
The role SOSL_EXECUTOR has access to the packages SOSL_CONSTANTS, SOSL_LOG, SOSL_API and SOSL_SERVER which can be used in the interface functions.
### has_scripts
Task: Return the number of scripts waiting.

The defined function is used by sosl_sys.has_scripts and must return the number of scripts waiting or -1 on error. The wrapper will ignore functions in error, but deactivate any executor that uses a function with errors. Errors and exceptions will be logged and lead to <= 0 scripts available. Package functions are also supported. No parameters supported. The name needs not to be equal, but to return a NUMBER value and not requiring mandatory parameters must match. Results or exceptions get logged to SOSL_SERVER_LOG. The function or package must be granted with EXECUTE rights to the SOSL_EXECUTOR role.

    Interface Definition: FUNCTION your_has_scripts RETURN NUMBER;

### get_next_script
Task: Return the next waiting script with the object type SOSL_PAYLOAD. The function has to ensure, that this script is not delivered twice. It may return NULL if no script is available or is in error. This function is only called if has_scripts reports waiting scripts. Errors must be handled by the function owner. SOSL_PAYLOAD contains the EXECUTOR_ID, the external script ID as CHAR and the script filename including relative or full path.

The defined function is used by sosl_sys.get_next_script and must return a valid SOSL_PAYLOAD object to access the script details. The wrapper will ignore functions in error, but deactivate any executor that uses a function with errors. Errors and exceptions will be logged. If SOSL is not using the default database user, the schema prefix of the example has to be adjusted to the schema used. The function or package must be granted with EXECUTE rights to the SOSL_EXECUTOR role.

    Interface Definition: FUNCTION get_next_script RETURN SOSL.SOSL_PAYLOAD;

### set_script_status
Task: Provide status details to the interface provider and SOSL about the current script status. On success should return 0 otherwise -1.

The defined function is used by sosl_sys.set_script_status and must return 0 or -1 on errors. The wrapper will ignore functions in error, but deactivate any executor that uses a function with errors. Errors and exceptions will be logged. The run id is managed internally by the wrapper function. Will set the state for SOSL in table SOSL_RUN_QUEUE and provide the interface function with RUN_ID and script status to manage the script status internally. Current state handling is up to the function provider.

    Interface Definition: FUNCTION set_script_status( p_run_id  IN NUMBER
                                                    , p_status  IN NUMBER
                                                    )
                            RETURN NUMBER;

### send_db_mail
Task: Provide details as mail to the interface provider about the current script status.

On success should return 0 otherwise -1. Building and sending the mail is up to the interface function. The wrapper will ignore functions in error, but deactivate any executor that uses a function with errors. Errors and exceptions will be logged. If mail is activated, the defined function is called on every state change. The function will get the intended state set by set_script_status interface function. The current state in SOSL_RUN_QUEUE may differ, if errors happened.

    Interface Definition: FUNCTION send_db_mail( p_run_id  IN NUMBER
                                               , p_status  IN NUMBER
                                               )
                            RETURN NUMBER;

This is just an option to enable and disable mail on demand. You might as well integrate your mail function in the set_script_status interface function and leave mail deactivated.
## Scripts
The interface API requires a set of information to handle things correctly: executor id, external script id as VARCHAR2 and the script filename including relative or absolute path. The SOSL type SOSL_PAYLOAD offers the possibility to transfer this information within one object and is the required output for getting the next script. All other interface API functions should return NUMBER.

SOSL does not take care about the order, scripts are delivered for execution, this is within the responsibility of the API function provider. The basic SOSL system, if no other executor is used, provides only a simple order mechanic, where scripts are processed by order number. Same order number just means the scripts get executed in an undefined order.
