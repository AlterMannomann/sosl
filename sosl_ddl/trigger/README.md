# Trigger
This folder contains the trigger definitions for the Simple Oracle Script Loader.

Trigger are separated to have full package support for triggers. No drop scripts for table triggers as they are expected to get dropped together with the table. Trigger SQL files contain all trigger types needed (insert, update, delete) for the specified table.

**DO NOT disable or drop any SOSL trigger**, they are important for integrity and functionality of SOSL.

- [SOSL_CONFIG trigger](#sosl_config-trigger)
  - [sosl_config_ins_trg](#sosl_config_ins_trg)
  - [sosl_config_upd_trg](#sosl_config_upd_trg)
- [SOSL_EXECUTOR_DEFINITION trigger](#sosl_executor_definition-trigger)
  - [sosl_executor_definition_ins_trg](#sosl_executor_definition_ins_trg)
  - [sosl_executor_definition_upd_trg](#sosl_executor_definition_upd_trg)
- [SOSL_RUN_QUEUE trigger](#sosl_run_queue-trigger)
  - [sosl_run_queue_ins_trg](#sosl_run_queue_ins_trg)
  - [sosl_run_queue_upd_trg](#sosl_run_queue_upd_trg)
- [SOSL_SERVER_LOG trigger](#sosl_server_log-trigger)
  - [sosl_server_log_ins_trg](#sosl_server_log_ins_trg)
  - [sosl_server_log_upd_trg](#sosl_server_log_upd_trg)
  - [sosl_server_log_del_trg](#sosl_server_log_del_trg)
- [SOSL_IF_SCRIPT trigger](#sosl_if_script-trigger)
  - [sosl_if_script_ins_trg](#sosl_if_script_ins_trg)
  - [sosl_if_script_upd_trg](#sosl_if_script_upd_trg)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../../README.md)
## SOSL_CONFIG trigger
All trigger will raise exceptions on errors, for details see [Application exceptions](../README.md). Or consult the [code](sosl_config_trg.sql).
### sosl_config_ins_trg
Tasks:
- set the defaults for created-columns
- check max length if given
- check NUMBER if NUMBER type is given
### sosl_config_upd_trg
Tasks:
- ensure that certain column values cannot be overwritten
- check max length if given
- check NUMBER if NUMBER type is given
- validates typical server relevant config values
### sosl_config_del_trg
- ensure that SOSL config names can't be deleted
## SOSL_EXECUTOR_DEFINITION trigger
All trigger will raise exceptions on errors, for details see [Application exceptions](../README.md). Or consult the [code](sosl_executor_definition_trg.sql).
### sosl_executor_definition_ins_trg
Tasks:
- set the defaults for created, updated, active and reviewed columns
- check user, function owner and defined functions if they are visible to SOSL
### sosl_executor_definition_upd_trg
Tasks:
- ensure that certain column values cannot be overwritten
- log changes in columns
- check user, function owner and defined functions if they are visible to SOSL
- applies missing grants for user and function owner if executor is active and reviewed
## SOSL_RUN_QUEUE trigger
All trigger will raise exceptions on errors, for details see [Application exceptions](../README.md). Or consult the [code](sosl_run_queue_trg.sql).
### sosl_run_queue_ins_trg
Tasks:
- set the defaults for certain column values
- validates the executor and sets record to error if the executor is not valid
### sosl_run_queue_upd_trg
Tasks:
- ensure that certain column values cannot be overwritten
- verifies given run state and order in which the run state is applied
  - only error can be applied at any state, otherwise the state must progress step by step until finished
- validates the executor and sets record to error if the executor is not valid
## SOSL_SERVER_LOG trigger
All trigger will raise exceptions on errors, for details see [Application exceptions](../README.md). Or consult the [code](sosl_server_log_trg.sql).
### sosl_server_log_ins_trg
Tasks:
- set the defaults for certain column values
- validate log type

Will not throw exceptions, log should be written.
### sosl_server_log_upd_trg
Tasks:
- disable update, throw exception
### sosl_server_log_del_trg
Tasks:
- restrict delete to SOSL_ADMIN role
## SOSL_IF_SCRIPT trigger
This table trigger can be seen as "external" because it is only an integrated example implementation of a possible executor. It is not related to the SOSL core functionality. It acts as an executor having its objects in the SOSL schema.
### sosl_if_script_ins_trg
Tasks:
- set the defaults for certain column values
### sosl_if_script_upd_trg
Tasks:
- set the defaults for certain column values
- ensure that certain column values cannot be overwritten
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).