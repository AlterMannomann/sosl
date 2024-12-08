# UNDER CONSTRUCTION
Current state: beta version of CMD and shell server. Basically working with a bunch of files and defined executors. Path format is important depending on the system SOSL is running. For Windows \ notation is mandatory, for bash /. Shell version tested with git bash on Windows.

Stopped working on Powershell, not stable enough, problems with pipe to sqlplus and environment not inherited correctly using Powershell 5.1.

**Important note:** SQL Developer in versions 23.x is not at all stable. It doesn't recognize database changes and delivers wrong result until restarted. SQL Plus is still reliable.

# SOSL - Simple Oracle Script Loader
This is a very simple solution for loading and executing scripts from anywhere that has an Oracle Client and sqlplus installed. It will come in the flavors CMD, PowerShell and Bash.
Basic components are database packages and OS script files. Basically an OS script acts as a server and loops over a list of files, that is given by package functions and configuration tables.
## What it is not
This project is **not** a click here and there, fire and forget application.

- You will have to setup your environment and server or need a working connection to a server with SQLPlus from your machine.
- You may need to setup TNSNAMES.ORA.
- You will have to setup the logins for the schemas to run.
- You will have to setup the API.

**Remember, this is not an out-of-the-box application.**
## What it is
This is an interface application that can be integrated into your projects to load scripts from a defined location triggered by the database. It can be used to run for example test scripts by database triggers or maintenance check scripts on events. The integration framework cannot be covered by this project, you will have to create it on your own depending on your system and application. See [sosl_if package](./sosl_ddl/packages/sosl_if.pks) for examples. This is the SOSL internal interface for simple script execution using SOSL.
## Requirements
- A working Oracle Client including SQLPlus installed on the preferred OS.
- An Oracle version >= 12c, DDLs using IDENTITY column syntax.
- Access to shell or command console (may require admin rights).
- Sufficient rights to create the SOSL schema or sufficient rights to install the SOSL components in an own schema.
- Sufficient rights to prepare the API (GRANT to SOSL) on the schemas that will run scripts.
- Ability to orchestrate the script run, especially if running scripts for more than one schema.
## Limits
As the Simple Oracle Script Loader under optimal conditions can read and execute a job within 3 seconds, the daily limit for scripts to be chained for execution is between 25.000 and 30.000 script execution under optimal conditions. If too much executors with too much scripts for one day are registered, the script execution time gets unpredictable. There are options to prioritize executors, but this in the end leads to unpredictable execution times for lower priorities. If this happens, split SOSL using different execution servers and schemas or PDBs.

Memory is another limiting factor. If there are many parallel running longrunner scripts, every SQLPlus session will reserve some memory. If memory gets to its limits it is most probably that scripts are not started correctly or hang. Check out your system configuration and the amount of maximum possible SQLPlus sessions. Limit maximum parallel running scripts to this value.
## Design
The project is designed for running directly from the repository. Directories for temporary and log files can be configured and will be, by default using the upper directory of the repository.

    directory structure:
    - repo directory
    -- sosl repository
    --- sosl content
    --- sosl run directory (always on the 2nd level, so ../../any_path leads to directories in the upper repo directory)
    ---- sosl_server.(cmd/ps/sh)
    -- other repositories
    -- sosl_log (the default SOSL logging directory)
    -- sosl_tmp (the default SOSL temporary directory)
    -- sosl_cfg (the default SOSL directory for SQLPlus login secrets)
    -- your_repo

Given this structure it is possible to reference scripts relative to the SOSL repository directory by

    ../../your_repo/relative_path_to_script

SOSL can handle relative repository paths to start scripts relative to the given repository directory. Otherwise you can use a script filename using the full path. This path must exist on the server SOSL is running locally.

The configuration path for SOSL will hold the sosl_login.cfg and might as well contain login files for the different users with which the scripts will get started. Executors can defined the path and name of the login config file.

    sosl_cfg (the default SOSL directory for SQLPlus login secrets)
    - sosl_login.cfg (the login secrets for sosl)
    - repo1_login.cfg (example name for login secrets, for scripts executed in repo1)
    - repo2_login.cfg (example name for login secrets, for scripts executed in repo2)

The basic server design is

    sosl_server
      - load configuration
      - run loop
        - exit on stop signal
        - check for available scripts
        - run available scripts
        - wait as defined

## Interface
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
### Scripts
The interface API requires a set of information to handle things correctly: executor id, external script id as VARCHAR2 and the script filename including relative or absolute path. The SOSL type SOSL_PAYLOAD offers the possibility to transfer this information within one object and is the required output for getting the next script. All other interface API functions should return NUMBER.

SOSL does not take care about the order, scripts are delivered for execution, this is within the responsibility of the API function provider. The basic SOSL system, if no other executor is used, provides only a simple order mechanic, where scripts are processed by order number. Same order number just means the scripts get executed in an undefined order.
### SQL Developer reports
A small set of reports to check and control the server state, the run queue and the logs. Users with role SOSL_USER should set the session to SOSL before using this user defined reports in SQL Developer. Just open [sosl_reports.xml](./sosl_templates/reports/sosl_reports.xml) under user defined reports as a report.

    ALTER SESSION SET CURRENT_SCHEMA = SOSL;
    
![SoslServer](https://github.com/user-attachments/assets/8789a361-edc0-4748-a74d-5838f92b22ee)
![SoslServerError](https://github.com/user-attachments/assets/e1390d6b-3f09-4691-8f92-f29ec5878f00)
![SoslRunQueue](https://github.com/user-attachments/assets/177d9ccb-6e4e-4b51-9594-3e354e6e1535)
![SoslLogs](https://github.com/user-attachments/assets/e266bd76-9a1d-4455-9eb1-dda2aa1c5455)
![SoslLogsError](https://github.com/user-attachments/assets/ef6ad3d3-35e7-4c9f-addd-c2b360814415)
![SoslLogsErrorDetails](https://github.com/user-attachments/assets/175c2171-51a2-4e5e-99ca-7765303b7876)
![SoslExecutors](https://github.com/user-attachments/assets/cbc155ca-4811-471a-b42e-4e2abfa3ea93)
![SoslExecutorsError](https://github.com/user-attachments/assets/8819454c-553c-4f5f-836b-3586bfad298c)
![SoslSessions](https://github.com/user-attachments/assets/950da49d-e1c3-4002-b2e3-4dd18d78c5b6)

## Security
First, it is difficult to obtain a minimum of security as Oracle, on the command line, requires username and password unless you are an authenticated system user like oracle on the db server, where you can login with slash (/) or a wallet is configured.

If you want to use wallets the SOSL server is limited to the OS user under which it runs. Thus, whenever you connect with / you will get the wallet of the OS user. You may mitigate this by running different instances with different OS users and wallets. This will put more workload on the server used.

The basic solution will read a login file as input for sqlplus using the following format to guarantee that Oracle ends the session on invalid logins with a proper exit code.

    username/password@db_name_or_tns_name
    --/--
    --/--

This ensures, if used as an input (sqlplus < sosl_login.cfg) for SQLPlus, that the login data are neither visible on screen nor in any log. You may replace this by an OS function that returns this string in the same manner as TYPE does. But this will involve a handful of changes to the SOSL system, depending on the used solution (cmd/ps/sh) where the explicite calls have to be adjusted to use your function instead of type. The relevant functions are called sosl_sql... that have to be adjusted.

The script call then will use basically (CMD example)

    (TYPE %SOSL_PATH_CFG%sosl_login.cfg && ECHO @@script_to_call.sql "Parameter") | sqlplus

If you want to inject a programm for the CMD solution, you have to replace the TYPE with a DOS program that results in the output of the three needed lines for the login. Calling a CMD at this point doesn't work well at least with Windows 11, so it should be an EXE to call.

However, if there is still some sort of file, the content is visible to those, who have the necessary rights. Thus anyone with this rights, also if hacked, can see the password and user. The default version will use files and can't be declared as secure therefore.

Database security, regarding executed srcipts, can be improved, if SOSL is installed in a separate schema and has sufficient rights to other schemas, that are accessed by scripts. In this case, the used database objects in the scripts should be qualified (schema.object). You may revoke the CREATE ROLE privilege after installing from SOSL.

Nevertheless, running any script from any source system is a high risk and only applicable in very rare cases, like testing.

To enhance security you may limit access to SOSL schema and check the compile dates of database objects. Those should be stable if the system is setup and running. Additionally you may audit all or specific schema objects. Use SOSL_UTIL.OBJECT_DATE to retrieve last DDL dates of SOSL objects.

**DO NOT USE SOSL FOR PRODUCTION SYSTEMS**

Find a better solution. If you know what scripts to execute, put them in the database. You should not quick fix production systems as they have an reliable and accepted state. Use a hotfix for those issues and avoid those issues before going to production due to proper testing. If you, nevertheless, use SOSL for production systems, please remember: **This is your decision and you have to deal with all consequences**.
### Roles
On database level several cascading roles are available: SOSL_ADMIN, SOSL_EXECUTOR, SOSL_REVIEWER, SOSL_USER, SOSL_GUEST.

    SOSL_ADMIN
    |- DELETE rights
    |_ SOSL_EXECUTOR
      |- select, insert and update rights, execute rights
      |_ SOSL_REVIEWER
        |- select rights, limited update rights
        |_ SOSL_USER
          |- select rights
          |_ SOSL_GUEST
            |- limited select rights

The application manages necessary role grants for configured function owners. Only reviewed executors will get the role SOSL_EXECUTOR granted, otherwise this role, if it exists for an invalid executor, gets revoked.

Grant any privilege needed to the role SOSL_EXECUTOR instead of granting it directly to SOSL schema. You should not grant SOSL objects to SOSL roles. Grant a SOSL role to database users according to their tasks. For database users that differ from the function owner, it is quite enough to grant the SOSL_USER role. The roles SOSL_EXECUTOR and SOSL_ADMIN should be used very limited. For creating a new executor you need at least SOSL_EXECUTOR rights. It is recommended that you use the function owner, granted SOSL_EXECUTOR role, to create the executor. Or you define a database user with SOSL_EXECUTOR role that creates the executors.
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt)

For further questions on copyleft and usage see [contact](CONTACT.md).

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the (usually buyed) company has to pay for the usage. See [Generic AI Disclosure License](AI_DISCLOSURE_LICENSE)
