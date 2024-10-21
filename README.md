# UNDER CONSTRUCTION
Current state: Work on CMD solution

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
This is an interface application that can be integrated into your projects to load scripts from a defined location triggered by the database. It can be used to run for example test scripts by database triggers or maintenance check scripts on events. The integration framework cannot be covered by this project, you will have to create it on your own depending on your system and application.
## Requirements
- A working Oracle Client including SQLPlus installed on the preferred OS.
- An Oracle version >= 12c, DDLs using IDENTITY column syntax.
- Access to shell or command console (may require admin rights).
- Sufficient rights to create the SOSL schema or sufficient rights to install the SOSL components in an own schema.
- Sufficient rights to prepare the API (GRANT to SOSL) on the schemas that will run scripts.
- Ability to orchestrate the script run, especially if running scripts for more than one schema.
## Limits
As the Simple Oracle Script Loader under optimal conditions can read and execute a job within 3 seconds, the daily limit for scripts to be chained for execution is between 25.000 and 30.000 script execution. If too much executors with too much scripts for one day are registered, the script execution time gets unpredictable. There are options to prioritize executors, but this in the end leads to unpredictable execution times for lower priorities. If this happens, split SOSL using different execution servers and schemas or PDBs.

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

Given this structure it is possible to reference scripts relative to the SOSL repository directory by

    ../../your_repo/relative_path_to_script

SOSL can handle relative repository paths to start scripts relative to the given repository directory. Otherwise you can use a script filename using the full path.

The configuration path for SOSL will hold the sosl_login.cfg as well as login files for the different user with which the scripts will get started.

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
The basic interface consist of views, packages and the table SOSLERRORLOG. You may define to whom to grant the interface using the table SOSL_EXECUTORS. If defining PUBLIC, consider that only one login config file for every executor is possible. It is recommended that you use defined executors.
## API
To use this application, interfaces exist, that must be configured in SOSL_CONFIG. Only one set of API can be generated, which means that script queueing and handling from different schemas must be handled behind the screen of SOSL.

Error logging apart from noticing the error are out of scope for SOSL, the provided API function must manage this on its own. All configured functions must be granted as executable to SOSL, and afterwards configured in SOSL_CONFIG. Functions must be visible for SOSL in ALL_OBJECTS and ALL_TAB_PRIVS.

    GRANT EXECUTE ON your_api_function TO SOSL;

The basic API consist of wrapper functions.
### has_scripts
Task: Return the number of scripts waiting.

The defined function is used by has_scripts and must return the number of scripts waiting or -1 on error. The wrapper will always return a number >= 0. Errors and exceptions will be logged and lead to 0 scripts available. Package functions are also supported. No parameters supported. The name needs not to be equal, but return a NUMBER value and no mandatory parameter must match. Results or exceptions get logged to SOSL_SERVER_LOG. Access right EXECUTE has to be granted to SOSL by the owner. The default is a function from SOSL, that uses a limited basic script management.

    Wrapper: FUNCTION has_scripts RETURN NUMBER;

### get_next_script
Task: Return the next waiting script with the object type SOSL_PAYLOAD. The function has to ensure, that this script is not delivered twice. It may return NULL if no script is available or the SOSL_APISOSL_PAYLOAD to distinguish errors from no script available. Errors must be handled by the function owner. Error type

The defined function is used by get_next_script and must return a valid id to access script details.

    Wrapper: FUNCTION get_next_script RETURN VARCHAR2;

### Send Mail
The default SOSL function is SOSL.SEND_MAIL. It uses simple mail relay function on port 25 for an available mail server. You may integrate your mailing into the set script state function and avoid direct mail integration.
### Scripts
The API requires an ID as VARCHAR2 that is referenced for identifying, getting and setting the relevant informations for script execution.

SOSL does not take care about the order, scripts are delivered for execution, this is within the responsibility of the API function provider. The basic SOSL system, if no other executor is used, provides only a simple order mechanic, where scripts with the same order number are processed randomly in parallel and no higher order number is executed until all scripts with the same order number have been executed successfully.

A setup API script is provided to create dynamically the necessary objects in SOSL with SOSL. The SOSL server understands three commands: RUN, STOP, API. On API it will create the necessary implementations as configured. (tbd)
#### Check IDs waiting for processing
The wrapper function is the function HAS_IDS which, on default, will use sosl.has_ids package function.
## Security
On database level several roles are available: SOSL_ADMIN, SOSL_EXECUTOR, SOSL_REVIEWER, SOSL_USER, SOSL_GUEST.

First, it is difficult to obtain a minimum of security as Oracle, on the command line, requires username and password unless you are an authenticated system user like oracle on the db server, where you can login with slash (/) or a wallet is configured.

If you want to use wallets the SOSL server is limited to the OS user under which it runs. Thus, whenever you connect with / you will get the wallet of the OS user. You may mitigate this by running different instances with different OS users and wallets. This will put more workload on the server used.

The basic solution will read a login file as input for sqlplus using the following format to guarantee that Oracle ends the session on invalid logins with a proper exit code.

    username/password@db_name_or_tns_name
    --/--
    --/--

This ensures, if used as an input (sqlplus < sosl_login.cfg) for SQLPlus, that the login data are neither visible on screen nor in any log.

The script call then will use basically (CMD example)

    (TYPE %SOSL_PATH_CFG%sosl_login.cfg && ECHO @@script_to_call.sql "Parameter") | sqlplus

If you want to inject a programm, you have to replace the TYPE with a DOS program that results in the output of the three needed lines for the login. Calling a CMD at this point doesn't work well at least with Windows 11.

However, if there is still some sort of file, the content is visible to those, who have the necessary rights. Thus anyone with this rights, also if hacked, can see the password and user. The default version will use files and can't be declared as secure therefore.

Database security, regarding executed srcipts, can be improved, if SOSL is installed in a separate schema and has sufficient rights to other schemas, that are accessed by scripts. In this case, the used database objects in the scripts should be qualified (schema.object).

Nevertheless, running any script from any source system is a high risk and only applicable in very rare cases, like testing.

**DO NOT USE SOSL FOR PRODUCTION SYSTEMS**

Find a better solution. If you know what scripts to execute, put them in the database. You should not quick fix production systems as they have an reliable and accepted state. Use a hotfix for those issues and avoid those issues before going to production due to proper testing.

## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt)

For further questions on copyleft and usage see [contact](CONTACT.md).

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt).