# SQL server scripts
This folder contains the SQLPlus scripts used and needed by the server of the Simple Oracle Script Loader.

All scripts call functions that are only available to the SOSL schema owner. The login with the schema owner is mandatory for SOSL.

Furthermore all scripts depend on the pipe mechanism of parameters and login (see [CMD Server limitations](../../sosl_cmd/README.md) and [PowerShell issues](../../sosl_ps/README.md)) which is defined in the CMD and bash functions that call sqlplus and the given script.

If results have to be transferred to the SOSL server, the scripts save them in the temporary file that is provided as parameter. SOSL server afterwards reads this file into a variable.

- [sosl_execute.sql](#sosl_executesql)
- [sosl_get_cfg.sql](#sosl_get_cfgsql)
- [sosl_get_config.sql](#sosl_get_configsql)
- [sosl_get_next_run_id.sql](#sosl_get_next_run_idsql)
- [sosl_get_schema.sql](#sosl_get_schemasql)
- [sosl_get_script.sql](#sosl_get_scriptsql)
- [sosl_has_scripts.sql](#sosl_has_scriptssql)
- [sosl_set_config.sql](#sosl_set_configsql)
- [sosl_start.sql](#sosl_startsql)
- [sosl_stop.sql](#sosl_stopsql)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../../README.md)

## sosl_execute.sql
The core of the SOSL functionality. The [sosl_execute.sql](sosl_execute.sql) script prepares the environment, switches the session to the function owner, defined in SOSL_EXECUTOR_DEFINITION and executes the given script, writes local and database log and detects errors. Will set the script run state first to running and after the script run to finished or error.
## sosl_get_cfg.sql
The [sosl_get_cfg.sql](sosl_get_cfg.sql) script fetches the login configuration filename and path for the current run id and executor.
## sosl_get_config.sql
The [sosl_get_config.sql](sosl_get_config.sql) script fetches a configuration value for a given configuration name.
## sosl_get_next_run_id.sql
The [sosl_get_next_run_id.sql](sosl_get_next_run_id.sql) script fetches the run if for the next available script. Sets the script run state to started.
## sosl_get_schema.sql
The [sosl_get_schema.sql](sosl_get_schema.sql) script fetches the defined schema for the current run id that should be used for script execution with ALTER SESSION SET CURRENT_SCHEMA.
## sosl_get_script.sql
The [sosl_get_script.sql](sosl_get_script.sql) script fetches the defined script filename and path for the current run id.
## sosl_has_scripts.sql
The [sosl_has_scripts.sql](sosl_has_scripts.sql) script checks if scripts are available for execution and fetches the count of available scripts.
## sosl_set_config.sql
The [sosl_set_config.sql](sosl_set_config.sql) script sets configuration values that are managed by the SOSL server.
## sosl_start.sql
The [sosl_start.sql](sosl_start.sql) script is used to log the start of the SOSL server in database and locally.
## sosl_stop.sql
The [sosl_stop.sql](sosl_stop.sql) script is used to log the stop of the SOSL server in database and locally.
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).