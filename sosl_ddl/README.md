# SOSL data model definition
This folder contains the DDL scripts to setup the Simple Oracle Script Loader.

- [Basics](#basics)
- [Tables](#tables)
- [Packages](#packages)
- [Trigger](#trigger)
- [Types](#types)
- [Views](#views)
- [Application exceptions](#application-exceptions)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../README.md)

## Basics
It is organized in packages, tables, trigger, types and views. Every folder has a subfolder drop that contains the related drop scripts.

The main tables are SOSL_EXECUTOR_DEFINITION and SOSL_RUN_QUEUE. The other tables are for configuration and logging. A special table SOSL_IF_SCRIPT is used for a minimalistic job queue demonstrating how to build a SOSL interface.

Functionality is realized by packages and table triggers. Views represent the GUI API for SOSL without interactive functionality (only reports or views directly used) which can be accessed by any user with the role SOSL_USER.

Roles are defined on DBA level and only granted with admin option to the SOSL user.
## Tables
SOSL needs only a few tables. For details see [tables](tables/README.md).
## Packages
The heart of the application functionality. For details see [packages](packages/README.md).
## Trigger
Control insert, update and delete. For details see [trigger](trigger/README.md).
## Types
Currently SOSL needs only one special type SOSL_PAYLOAD. For details see [types](types/README.md).
## Views
The user interface to SOSL. For details see [views](views/README.md).
## Application exceptions
The application itself is designed to use as less as possible exceptions. The usual behavior is to report the error but not fail the application. Nevertheless some table triggers are in use to avoid misuse and incorrect or incomplete data.
### SOSL_SERVER_LOG 20000-20009
- **-20000** No updates allowed on a log table.
- **-20001** Delete records from a log table is not allowed. This is an admin job which needs sufficient rights.
  - you need at least role SOSL_ADMIN to delete records from the log table or the schema owner
### SOSL_CONFIG 20010-20019
- **-20010** The config_value exceeds the defined config_max_length.
- **-20011** The given config_value could not be converted successfully to a number.
- **-20012** The given system config_name cannot be changed.
- **-20013** The given system config_name cannot be deleted.
- **-20014** The SOSL_SCHEMA value cannot be changed.
- **-20015** The given runmode is not supported, only RUN, PAUSE or STOP accepted.
- **-20016** The given server state is not supported, only ACTIVE or INACTIVE accepted.
- **-20017** The given time frame for start and stop times is not supported. Format is HH24:MI with leading zeros, e.g. 05:04 and must be a valid time.
### SOSL_EXECUTOR_DEFINITION 20020-20029
- **-20020** The given database user is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.
- **-20021** The given function owner database user is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.
- **-20022** The given function for has_scripts is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.
- **-20023** The given function for get_next_script is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype OBJECT or is not granted with EXECUTE rights to SOSL.
- **-20024** The given function for set_script_status is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.
- **-20025** The given function for send_db_mail is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL.
- **-20026** Error granting necessary roles to db user (SOSL_USER) or function owner (SOSL_EXECUTOR). Check setup and roles. Probably grant the roles manually before trying update again.

## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).