# Installation
The setup folder contains the SQL install/remove scripts for the Simple Oracle Script Loader.

To setup the SOSL user, use the [sosl_dba_setup.sql](sosl_dba_setup.sql) script. You must have DBA rights on the database or PDB you are using.

Connect to the desired instance and run the script from this directory via SQLPlus, e.g.

    sqlplus sys/passwd@your_instance AS SYSDBA @sosl_dba_setup.sql

You will be asked for
- SOSL db user name (default SOSL)
- SOSL db user password (mandatory, no default)
- SOSL tablespace name (default SOSL_TABLESPACE)
- SOSL tablespace data file name (default sosl.dbf)
- SOSL default configuration file and path (default ../sosl_templates/sosl_login.cfg)
- SOSL db instance or tns name (default SOSLINSTANCE)

You may stop the script before execution on showing the install message with CTRL-C.

The tablespace and the tablespace data file will be created when the script is running and the tablespace does not exist. Otherwise the existing tablespace is used. No special data file will be created.

The user as given is created and granted quota unlimited on the given tablespace. Roles are created, if they do not exist and granted hierarchically.
The SOSL db user will get the admin option on the SOSL roles to be able to grant and revoke roles dynamically from executors activated or deactivated.

The path for default configuration file with the login credentials must exist, if not the default is used. It is recommended to use the default and move after install the sosl_login.cfg to the desired configuration directory, that can be configured in sosl_config.(cmd|sh).

# Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).