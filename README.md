# UNDER CONSTRUCTION
Current state: beta version of CMD and shell server. Basically working with a bunch of files and defined executors. Path format is important depending on the system SOSL is running. For Windows \ notation is mandatory, for bash /. Shell version tested with git bash on Windows.

Stopped working on Powershell, not stable enough, problems with pipe to sqlplus and environment not inherited correctly using Powershell 5.1.

**Important note:** SQL Developer in versions 23.x is not at all stable. It doesn't recognize database changes and delivers wrong result until restarted. SQL Plus is still reliable.

# SOSL - Simple Oracle Script Loader
This is a very simple solution for loading and executing scripts from anywhere that has an Oracle Client and sqlplus installed. It will come in the flavors CMD and Bash.
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
## SQL Developer reports (minimal GUI)
A small set of reports to check and control the server state, the run queue and the logs. Users with role SOSL_USER should set the session to SOSL before using this user defined reports in SQL Developer. Just open [sosl_reports.xml](./sosl_templates/reports/sosl_reports.xml) under user defined reports as a report.

    ALTER SESSION SET CURRENT_SCHEMA = SOSL;

### SOSL server report
![SoslServer](https://github.com/user-attachments/assets/8789a361-edc0-4748-a74d-5838f92b22ee)
![SoslServerError](https://github.com/user-attachments/assets/e1390d6b-3f09-4691-8f92-f29ec5878f00)
### SOSL run queue report
![SoslRunQueue](https://github.com/user-attachments/assets/177d9ccb-6e4e-4b51-9594-3e354e6e1535)
### SOSL logs report
![SoslLogs](https://github.com/user-attachments/assets/e266bd76-9a1d-4455-9eb1-dda2aa1c5455)
![SoslLogsError](https://github.com/user-attachments/assets/ef6ad3d3-35e7-4c9f-addd-c2b360814415)
![SoslLogsErrorDetails](https://github.com/user-attachments/assets/175c2171-51a2-4e5e-99ca-7765303b7876)
### SOSL executors report
![SoslExecutors](https://github.com/user-attachments/assets/cbc155ca-4811-471a-b42e-4e2abfa3ea93)
![SoslExecutorsError](https://github.com/user-attachments/assets/8819454c-553c-4f5f-836b-3586bfad298c)
### SOSL sessions report
![SoslSessions](https://github.com/user-attachments/assets/950da49d-e1c3-4002-b2e3-4dd18d78c5b6)

## Installation
See [SOSL Installation](setup/README.md).
## Design
See [SOSL Design](DESIGN.md).
## Interface
See [SOSL Interface](INTERFACE.md).
## Security
See [SOSL Security](SECURITY.md).
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

For further questions on copyleft and usage see [contact](CONTACT.md).

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).
