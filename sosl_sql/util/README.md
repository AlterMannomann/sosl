# SQL utility scripts
This folder contains utility scripts used and needed by the Simple Oracle Script Loader.

- [log_defaults.sql](#log_defaultssql)
- [log_silent.sql](#log_silentsql)
- [log_visible.sql](#log_visiblesql)
- [os_detect.sql](#os_detectsql)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../../README.md)

## log_defaults.sql
The [log_defaults.sql](log_defaults.sql) scripts sets the SQLPlus default variables like TRIMSPOOL, SERVEROUTPUT and others.
## log_silent.sql
The [log_silent.sql](log_silent.sql) script sets the defaults and then the variables to avoid unwanted output. Only the result of a SELECT statement is shown, but not the header, the statement or how many rows have been affected.
## log_visible.sql
The [log_visible.sql](log_visible.sql) script sets the defaults and enables full display of everything executed by SQLPlus.
## os_detect.sql
The [os_detect.sql](os_detect.sql) script requires access rights to V$SESSION and makes a simple check of the own process to find out if it runs under Windows or Unix. Only used by DBA setup scripts.
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).