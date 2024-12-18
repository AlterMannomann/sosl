# SQL Developer user-defined reports
This folder contains SQL Developer user defined report definitions of the Simple Oracle Script Loader.

Reports can be imported into SQL Developer by opening them as reports. Imported reports require a correct SOSL role. SOSL users must set the current schema to SOSL before using the reports.

- [sosl_reports.xml](#sosl_reportsxml)
  - [SOSL executors report](#sosl-executors-report)
  - [SOSL logs report](#sosl-logs-report)
  - [SOSL run queue report](#sosl-run-queue-report)
  - [SOSL server report](#sosl-server-report)
  - [SOSL sessions report](#sosl-sessions-report)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../../README.md)

## sosl_reports.xml
The reports in the [report definition](sosl_reports.xml) require the role SOSL_USER and provide a set of reports under the report folder SOSL to watch the state of SOSL.

All reports have sub-reports that in most cases depend on the selected row in the main report. Reports can be sorted and filtered by provided columns.
### SOSL executors report
This report shows the current defined executors and selected information and details about them.
### SOSL logs report
This report shows the entries from SOSL_SERVER_LOG as well as error details of SOSLERRORLOG.
### SOSL run queue report
This report shows the entries and details from SOSL_RUN_QUEUE.
### SOSL server report
This report shows state and configuration information of the SOSL server.
### SOSL sessions report
This report shows limited information on current Oracle sessions and executed SQL from GV$SESSION and GV$SQL. It filters machine and users to known SOSL machine and users. It still may contain sessions that are not directly related to SOSL, e.g. using the same machine but without SOSL context or defined as user or function owner and doing things not related to SOSL.

Currently there is no way to uniquely identify only SOSL sessions. If you think this imposes a security risk, delete this report or adjust it to show data only if the current user has SOSL_ADMIN role.

Users with SOSL_ADMIN role can always access GV$SESSION and GV$SQL and also use the prepared _ADMIN views.
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).