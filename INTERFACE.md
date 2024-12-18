# Interface
There are two types of interfaces, the **SOSL API** which provides functions, procedures and views for an executor to implement the **Executor API**, where the executor provides the defined functions called by SOSL.

- [SOSL API](#sosl-api)
- [Executor API](#executor-api)
  - [has_scripts functionality](#executor-api-has_scripts-functionality)
  - [get_next_script functionality](#executor-api-get_next_script-functionality)
  - [set_script_status functionality](#executor-api-set_script_status-functionality)
  - [optional mail functionality](#executor-api-optional-send_db_mail-functionality)
- [SOSL_PAYLOAD](#sosl_payload)
- [Script processing](#script-processing)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](README.md)
## SOSL API
To access the SOSL API you must at least have the role SOSL_USER. Some parts of the API require a higher role, like SOSL_REVIEWER, SOSL_EXECUTOR or SOSL_ADMIN. Roles are checked by provided functionality.

The main package for the API is the [sosl_api](sosl_ddl/packages/sosl_api.pks) package. A helpful package with [sosl_constants](sosl_ddl/packages/sosl_constants.pks) can be used as well.

All [views](sosl_ddl/views/README.md) provided are part of the management interface and as well used in the SQL Developer user-defined [reports](sosl_templates/reports/README.md). Views without *admin* in the name are accessible to any user with the SOSL_USER role.

For an example implementation see package [sosl_if](sosl_ddl/packages/sosl_if.pks) and package body [sosl_if body](sosl_ddl/packages/sosl_if.pkb). You may use this package and structure as a starting point for your implementation.

Basic interface functions in SOSL_API are prefixed with IF_:
- SOSL_API.IF_GET_PAYLOAD
- SOSL_API.IF_HAS_RUN_ID
- SOSL_API.IF_DUMMY_MAIL
- SOSL_API.IF_EXCEPTION_LOG
- SOSL_API.IF_GENERIC_LOG
- SOSL_API.IF_DISPLAY_LOG

See [header](sosl_ddl/packages/sosl_api.pks) and [body](sosl_ddl/packages/sosl_api.pkb) of SOSL_API for details. As well as SOSL_IF package for implementation usage.

Main maintenance functions are:
- SOSL_API.CREATE_EXECUTOR
  - users with role SOSL_USER can create an executor, but to review and set active the roles SOSL_REVIEWER and SOSL_EXECUTOR are required
- SOSL_API.SET_EXECUTOR_REVIEWED
  - requires SOSL_REVIEWER role
- SOSL_API.REVOKE_EXECUTOR_REVIEWED
  - requires SOSL_REVIEWER role
- SOSL_API.ACTIVATE_EXECUTOR
  - requires SOSL_EXECUTOR role
- SOSL_API.DEACTIVATE_EXECUTOR
  - requires SOSL_EXECUTOR role
- SOSL_API.SET_RUNMODE
  - requires SOSL_ADMIN role
- SOSL_API.SET_TIMEFRAME
  - requires SOSL_ADMIN role
## Executor API
Executors must have at least the SOSL_EXECUTOR role granted. You must use a defined function owner for every defined executor. If you don't define a script schema, the scripts executed are running under the privileges and schema of the login config file used.

To use this application, the executor interface functions must exist and must be configured in SOSL_EXECUTOR_DEFINITION. Executors may share the same function owner and function. In this case the provided interface API functions must handle by themselves the internal script states for the different executors running.

Error logging apart from noticing the error are out of scope for SOSL, the provided API function must manage this on its own but may use the SOSL API functions. All configured functions must be granted as executable to the role SOSL_EXECUTOR, and afterwards configured in SOSL_EXECUTOR_DEFINITION. Functions must be visible for SOSL in ALL_OBJECTS and ALL_TAB_PRIVS. Package functions must be visible in ALL_ATTRIBUTES for SOSL.

    GRANT EXECUTE ON your_api_function TO SOSL_EXECUTOR;

The basic SOSL server will call all configured interface functions for active and reviewed executors. The role SOSL_EXECUTOR has access to the packages SOSL_CONSTANTS and SOSL_API which can be used in the interface functions. You can name the functions as you want, no name constraints exist. They can be a function or a package function. Only constraints are return value and type, as well as parameters, if needed. Results or exceptions get logged to SOSL_SERVER_LOG. Functions with errors or exceptions will cause SOSL to deactivate the executors that use the function in error.

The configured functions have to be given fully qualified, like {user}.{function} or {user}.{package}.{function}, e.g. MYUSER.MYPACKAGE.MYFUNCTION. Only use the qualified name, do not use brackets or parameter definitions.

### Executor API has_scripts functionality
- **Parameter**: None.
- **Task**: Return the number of scripts waiting.
- **Configuration column**: SOSL_EXECUTOR_DEFINITION.FN_HAS_SCRIPTS

The defined function must return the number of scripts waiting or -1 on error. Errors and exceptions will lead to <= 0 scripts available for the impacted executor.

    Interface Definition: FUNCTION your_has_scripts RETURN NUMBER;

### Executor API get_next_script functionality
- **Parameter**: None.
- **Task**: Return the next waiting script with the object type [SOSL_PAYLOAD](sosl_ddl/types/README.md).
- **Configuration column**: SOSL_EXECUTOR_DEFINITION.FN_GET_NEXT_SCRIPT

The function has to ensure, that a script is not delivered twice. It may return NULL if no script is available or is in error. This function is only called if the corresponding configured has_scripts function reports waiting scripts. Errors must be handled by the function owner. SOSL_PAYLOAD contains the EXECUTOR_ID, the external script ID as CHAR and the script filename including relative or full path.

The defined function must return a valid SOSL_PAYLOAD object to provide SOSL with access to the script details.

    Interface Definition: FUNCTION get_next_script RETURN SOSL.SOSL_PAYLOAD;

### Executor API set_script_status functionality
- **Parameter**: RUN_ID, STATUS
- **Task**: Update the executors internal script status for scripts running under SOSL.
- **Configuration column**: SOSL_EXECUTOR_DEFINITION.FN_SET_SCRIPT_STATUS

The defined function must return 0 or -1 on errors. The run id is managed internally by SOSL and can be used to get a SOSL_PAYLOAD object with the executors script id. SOSL will update the internal script state and then call the defined function of the impacted executor to inform the executor about the status change. SOSL run states are numerical and defined in [SOSL_CONSTANTS.RUN_](sosl_ddl/packages/sosl_constants.pks) package variables (-1, 0, 1, 2, 3, 4).

    Interface Definition: FUNCTION set_script_status( p_run_id  IN NUMBER
                                                    , p_status  IN NUMBER
                                                    )
                            RETURN NUMBER;

### Executor API optional send_db_mail functionality
- **Parameter**: RUN_ID, STATUS
- **Task**: Send a mail on status updates.
- **Configuration column**: SOSL_EXECUTOR_DEFINITION.FN_SEND_DB_MAIL

On success should return 0 otherwise -1. Building and sending the mail is up to the interface function. If mail is activated (SOSL_EXECUTOR_DEFINITION.USE_MAIL), the defined function is called on every state change. The function will get the intended state set by set_script_status interface function. The current state in SOSL_RUN_QUEUE may differ, if errors happened.

    Interface Definition: FUNCTION send_db_mail( p_run_id  IN NUMBER
                                               , p_status  IN NUMBER
                                               )
                            RETURN NUMBER;

This is just an option to enable and disable mail on demand. You might as well integrate your mail function in the set_script_status interface function and leave mail deactivated.
## SOSL_PAYLOAD
The interface API requires a set of information to handle things correctly: executor id, external script id as VARCHAR2 and the script filename including relative or absolute path. The SOSL type [SOSL_PAYLOAD](sosl_ddl/types/README.md) offers the possibility to transfer this information within one object and is the required output for getting the next script. All other interface API functions should return NUMBER.

## Script processing
SOSL does not take care about the order, scripts are delivered for execution, this is within the responsibility of the executor API function provider. The basic SOSL system, if no other executor is used, provides only a simple order mechanic, where scripts are processed by order number. Same order number just means the scripts get executed in an undefined order.
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).