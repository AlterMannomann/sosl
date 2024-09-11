# UNDER CONSTRUCTION
Current state: Define repository structure

# SOSL - Simple Oracle Script Loader
This is a very simple solution for loading and executing scripts from anywhere that has an Oracle Client and sqlplus installed. It will come in the flavors CMD, PowerShell and Bash.
Basic components are database packages and OS script files. Basically an OS script acts as a server and loops over a list of files, that is given by package functions and configuration tables.
## Requirements
- A working Oracle Client including SQLPlus installed on the preferred OS
- Access to shell or command console (may require admin rights)
- Sufficient rights on the schema of the database, for which scripts should run
  - Rights to install packages, tables, views and other database objects (complete list will be available if project has state published)
## Design
The project is designed for running directly from the repository. Directories for temporary and log files can be configured and will be, by default using the upper directory of the repository.
The Oracle part can be configured to use a pure table based solution or a queue solution, using Oracle AQ for triggering new script file executions.
## Security
First, it is difficult to obtain a minimum of security as Oracle on the command line requires username and password unless you are an authenticated system user like oracle on the db server, where you can login with slash (/).
The basic solution will read a login file using the format

    username/password@db_name_or_tns_name
    --/--
    --/--

The script call then will use basically

    (sosl_login.cmd && TYPE @@script_to_call.sql "Parameter") | sqlplus

This will at least avoid that the user and password can be seen in the executed command line or in the oracle session. The sosl_login.cmd will just execute a TYPE on the defined login file and can be used to inject there any programm that results in the output of the three needed lines for the login.

However, if there is still some sort of file, the content is visible to those, who have the necessary rights. Thus anyone with this rights, also if hacked, can see the password and user. The default version will use files and can't be declared as secure therefore.
