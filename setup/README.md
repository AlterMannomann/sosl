# Installation
The setup folder contains the SQL install/remove scripts for the Simple Oracle Script Loader.
## Database user
To setup the SOSL user, use the [sosl_dba_setup.sql](sosl_dba_setup.sql) script. You must have DBA rights on the database or PDB you are using. The script will create a login configuration file with the given username, password and instance, that works with SOSL. You may use this file as template for your executor definitions. See example file [sosl_login.cfg](../sosl_templates/sosl_login.cfg). If the given user already exists, the script will create a file [illegal_login_overwrite.cfg](../sosl_templates/illegal_login_overwrite.cfg) instead to avoid overwrites of existing login configuration files.

The rights assigned to the SOSL user are limited to the rights needed. Review the script to check if it is compliant to your situation. You may assign more rights to the SOSL database user but not less as defined.

Connect to the desired instance and run the script from this directory via SQLPlus, e.g.

    sqlplus sys/passwd@your_instance AS SYSDBA @sosl_dba_setup.sql

You will be asked for
- SOSL db user name (default SOSL)
- SOSL db user password (mandatory, no default)
- SOSL tablespace name (default SOSL_TABLESPACE)
- SOSL tablespace data file name (default sosl.dbf)
- SOSL default configuration file and path (default ../sosl_templates/sosl_login.cfg)
- SOSL db instance or tns name (default SOSLINSTANCE)

You may stop the script before execution when paused and showing the install message with CTRL-C.

The tablespace and the tablespace data file will be created when the script is running and the tablespace does not exist. Otherwise the existing tablespace is used. No special data file will be created.

The user as given is created and granted quota unlimited on the given tablespace. Roles are created, if they do not exist and granted hierarchically.
The SOSL db user will get the admin option on the SOSL roles to be able to grant and revoke roles dynamically from executors activated or deactivated.

The path for default configuration file with the login credentials must exist, if not the default is used. It is recommended to use the default and move after install the sosl_login.cfg to the desired configuration directory, that can be configured in sosl_config.(cmd|sh).

To uninstall the SOSL database user, use the script [sosl_dba_cleanup.sql](sosl_dba_cleanup.sql).
## Schema objects
To install or uninstall the schema objects use the description and scripts in [sosl_cmd](../sosl_cmd/README.md) or [sosl_sh](../sosl_sh/README.md), depending on the server version you want to run. This scripts will use the configured SOSL login configuration file and do not need any input. The configuration file of the server flavor ([sosl_config.cmd](../sosl_cmd/sosl_config.cmd) or [sosl_config.sh](../sosl_sh/sosl_config.sh)) must be configured before if not using the defaults.

Scripts available are
- SOSL CMD server
  - [sosl_install.cmd](../sosl_cmd/sosl_install.cmd)
  - [sosl_uninstall.cmd](../sosl_cmd/sosl_uninstall.cmd)
- SOSL bash server
  - [./sosl_install.sh](../sosl_sh/sosl_install.sh)
  - [./sosl_uninstall.sh](../sosl_sh/sosl_uninstall.sh)

Or call the scripts directly with the correct SOSL login:
- install SOSL schema objects [sosl_setup.sql](sosl_setup.sql)
- uninstall SOSL schema objects [sosl_cleanup.sql](sosl_cleanup.sql)
## Example data
To install example test data it is important to use the version for the intended SOSL server flavor (cmd or shell). You find them in the related example folder. See [examples/cmd](../examples/cmd/README.md) and [examples/sh](../examples/sh/README.md) for more details.
## SQL Developer reports
After installing the schema objects you may install the user-defined reports for SQL Developer.

Use the context menu of user defined reports and choose *Open report ...* to open [sosl_reports.xml](../sosl_templates/reports/sosl_reports.xml). You will find all reports under the folder SOSL. The role SOSL_USER is required to successfully execute the reports.

## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).