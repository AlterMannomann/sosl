# UNDER CONSTRUCTION
Current state: Define repository structure

# SOSL - Simple Oracle Script Loader
This is a very simple solution for loading and executing scripts from anywhere that has an Oracle Client and sqlplus installed. It will come in the flavors CMD, PowerShell and Bash.
Basic components are database packages and OS script files. Basically an OS script acts as a server and loops over a list of files, that is given by package functions and configuration tables.
## Requirements
- working Oracle Client including SQLPlus installed on the preferred OS
- Access to shell or command console (may require admin rights)
- Sufficient rights on the schema of the database, for which scripts should run
  - Rights to install packages, tables, views and other database objects (complete list will be available if project has state published)
## Design
The project is designed for running directly from the repository. Directories for temporary and log files can be configured and will be, be default using the upper directory of the repository.
The Oracle part can be configured to use a pure table based solution or a queue solution, using Oracle AQ for triggering new script file executions.
