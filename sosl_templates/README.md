# SOSL templates
This folder contains templates of login configuration files the Simple Oracle Script Loader and SQL Developer reports.

- [Login configuration file](#login-configuration-file)
  - [Rule of thumb](#rule-of-thumb)
  - [Using sosl_login.cfg](#using-sosl_logincfg)
  - [Created by DBA setup](#created-by-dba-setup)
  - [Testing the configuration file](#testing-the-configuration-file)
- [SQL Developer reports](#sql-developer-reports)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../README.md)

## Login configuration file
The term login configuration file is used only for files that contain sensitive data, credentials and secrets.
### Rule of thumb
- copy the sosl_login.cfg file to the configured SOSL_PATH_CFG
  - if you change the file name, adjust the sosl_config file of the server to use
  - do not add more lines (3 content lines, empty line at the end of the file)
  - change only login string in the first line, do not change other parts
- copy the sosl_login.cfg to the configured CFG_FILE in SOSL_EXECUTOR_DEFINITION
  - adjust the first line to the login of the function owner, defined in SOSL_EXECUTOR_DEFINITION
  - adjust the name of the file to the used filename configured in CFG_FILE of SOSL_EXECUTOR_DEFINITION
- verify that you can access the file with the OS user under which SOSL runs
### Using sosl_login.cfg
This file contains the basic login and is piped as input to sqlplus. There should not be any additional comment in this file. Change only the login string in the first line. The two additional lines are needed to end the sqlplus session if login failed. Otherwise they are treated as comments. There must be an empty line at the end.

This config file type is used by the default version of the Simple Oracle Script Loader. You may adjust sosl_login.cmd to inject your own program that produces this three lines of output without saving login credentials to files.
### Created by DBA setup
The file [sosl_dba_setup.sql](../setup/sosl_dba_setup.sql) will create a default template with the given data during install. Just move the created file to the defined configuration folder (default ../../cfg from run directory, which is a directory outside the repository). Otherwise copy the file to the configuration directory and adjust it as needed.
### Testing the configuration file
You can simply use

    sqlplus < path_to_file/sosl_login.cfg
    -- e.g. with absolute path
    sqlplus < C:\my_secrets\sosl_login.cfg
    sqlplus < /my_secrets/sosl_login.cfg

to test if the connect is working.
## SQL Developer reports
The [folder reports](reports/README.md) contains report files that can be used as user-defined reports in SQL Developer.
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).