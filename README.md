# UNDER CONSTRUCTION
Current state: Define repository structure

# SOSL - Simple Oracle Script Loader
This is a very simple solution for loading and executing scripts from anywhere that has an Oracle Client and sqlplus installed. It will come in the flavors CMD, PowerShell and Bash.
Basic components are database packages and OS script files. Basically an OS script acts as a server and loops over a list of files, that is given by package functions and configuration tables.
## What it is not
This project is not a click here and there, fire and forget application. You will have to setup your environment and server or need a working connection to a server with SQLPlus from your machine. You may need to setup TNSNAMES.ORA. You have to setup the login (file based or own solution) and your schema. You may need to integrate this into another application.

**Remember, this is not an out-of-the-box application**
## What it is
This is an interface application that can be integrated into your projects to load scripts from a defined location triggered by the database. It can be used to run for example test scripts by database triggers or maintenance check scripts on events. The integration framework cannot be covered by this project, you will have to create it on your own depending on your system and application.
## Requirements
- A working Oracle Client including SQLPlus installed on the preferred OS
- Access to shell or command console (may require admin rights)
- Sufficient rights on the schema of the database, for which scripts should run
  - Rights to install packages, tables, views and other database objects (complete list will be available if project has state published)
  - Sufficient rights that SQLPlus can install and use the table SOSLERRORLOG with the provided login
## Design
The project is designed for running directly from the repository. Directories for temporary and log files can be configured and will be, by default using the upper directory of the repository.
The Oracle part can be configured to use a pure table based solution or a queue solution, using Oracle AQ for triggering new script file executions.
## Security
First, it is difficult to obtain a minimum of security as Oracle, on the command line, requires username and password unless you are an authenticated system user like oracle on the db server, where you can login with slash (/).

The basic solution will read a login file as input for sqlplus using the following format to guarantee that Oracle ends the session on invalid logins with a proper exit code.

    username/password@db_name_or_tns_name
    --/--
    --/--

The script call then will use basically

    (TYPE %SOSL_PATH_CFG%sosl_login.cfg && ECHO @@script_to_call.sql "Parameter") | sqlplus

This will at least avoid that the user and password can be seen in the executed command line or in the oracle session. If want to inject a programm, you have to replace the TYPE with a DOS program that results in the output of the three needed lines for the login.

However, if there is still some sort of file, the content is visible to those, who have the necessary rights. Thus anyone with this rights, also if hacked, can see the password and user. The default version will use files and can't be declared as secure therefore.

Database security, regarding executed srcipts, can be improved, if SOSL is installed in a separate schema and has sufficient rights to other schemas, that are accessed by scripts. In this case, the used database objects in the scripts should be qualified (schema.object).

Nevertheless, running any script from any source system is a high risk and only applicable in very rare cases, like testing.

**DO NOT USE SOSL FOR PRODUCTION SYSTEMS**

Find a better solution. If you know what scripts to execute, put them in the database. You should not quick fix production systems as they have an reliable and accepted state. Use a hotfix for those issues and avoid those issues before going to production due to proper testing.

## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.