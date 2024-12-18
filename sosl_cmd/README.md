#  Simple Oracle Script Loader - CMD solution
This folder contains the CMD script components of the Simple Oracle Script Loader.

- [Requirements](#requirements)
- [Limitations](#limitations)
- [Preparation](#preparation)
- [Configuration](#configuration)
- [Install the SOSL schema](#install-the-sosl-schema)
- [Configure the SOSL schema](#configure-the-sosl-schema)
- [Start the server](#start-the-server)
- [Testing](#testing)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../README.md)

## Requirements
- Windows (tested with Windows 11 Pro).
- Access to Oracle via SQLPlus from your server/machine.
- DBA Setup done and valid login config file available on your server/machine.
- SOSL repository available on your server/machine.
- Access to command console (may require admin rights).
- CMD command extension usable and available (SETLOCAL ENABLEEXTENSIONS must work).
  - WMIC available
  - BITSADMIN available
- The user running SOSL must have sufficient access rights on the configured directories.
  - READ on configured SOSL_PATH_CFG, place where the login config file of SOSL is stored.
  - READ on any other login configuration path that is configured for executors.
  - READ WRITE on configured SOSL_PATH_TMP and SOSL_PATH_LOG.
  - READ on SOSL repository, WRITE if log or temp path are part of the repository structure.
- Scripts to be executed should be pure UTF-8, not UTF-8 with BOM, this causes errors with SQLPlus.
## Limitations
- Currently does not work as expected if started via Windows Task Scheduler.
  - seems the same issue as with PowerShell, background processes handle pipe wrong
- If you want to run SOSL as a background process on a server you should use the [SOSL bash server](../sosl_sh/README.md).
## Preparation
1. Choose server and OS user to use.
2. Check the requirements with that user and machine.
3. Test your database access and TNS setup with SQLPlus.
4. Define the local paths to use for log and temporary files
5. Define the local path and filename for the login config file.
6. Define the timeframe when SOSL should run and the PAUSE wait time.
  1. The PAUSE wait time is related to the timeframe.
  2. Explanation: If SOSL starts the PAUSE wait time of 1 hour at 18:00 and wakes up a little bit to early, let's say 07:59, then SOSL will only notice at 08:59 that it should have started at 08:00.
  3. Plan a little adjustment on the start time to get an overlapping that ensures close wake up time. If the server should be up and running at 08:00, a good time frame would be 07:55 - 18:00.
7. Define the maximum parallel script runs
  1. Check the memory that one CMD window with an open SQLPlus connection consumes
  2. Depending on the server and other users, the amount of memory for SOSL maybe limited. Make sure that the server has at least 20% or more free memory when SOSL is executed with maximum parallel scripts active.
  3. SOSL uses one CMD window for the server and one additional CMD window per script limited to SOSL_MAX_PARALLEL scripts/windows running.
  4. SOSL_MAX_PARALLEL should be adjusted on database level. No need to change CMD configuration.
8. Define the users and executors as well as the role grants.

DBA setup should have created a valid sosl_login.cfg file. If the DBA setup was on a different machine, the TNS or server name probably has to be adjusted. If administration already defined a path for this login config files, the corresponding login file must exist in this path. The name of this file is not constrained. It can be any valid filename that you or your organization defines.

This file and path is the heart of SOSL access to the database and needed for the configuration. It is also a security risk, especially if not managed well.
## Configuration
Use and adjust the file [sosl_config.cmd](sosl_config.cmd) to adjust local server parameters. The rest is configured in the database.

You can adjust the path for temporary and log directory, the login config file name, the path to this file, the log file name and file name extensions.
## Install the SOSL schema
If the schema is already installed you can skip this section.

Before you install the schema, the configuration file [sosl_config.cmd](sosl_config.cmd) must have been setup correctly and the login configuration file must match with configured name and path.

If all requirements fulfilled, simply start [sosl_install.cmd](sosl_install.cmd) on the command line, either with correct path or directly from this directory. The logfile of the install will be stored inside this repository under [setup\logs](../setup/logs/README.md).
## Configure the SOSL schema
Setup configuration and executors as desired. Grant necessary SOSL roles to users, executors, reviewers and admins.
## Start the server
To start the server simply run [start_sosl_server.cmd](start_sosl_server.cmd) from the command line.

This will open an extra minimized DOS window with the server running. Every script executed gets its own DOS window. With the default configuration, 9 DOS windows (server and 8 scripts) will be the maximum during parallel script runs.
## Testing
The directory [examples\cmd](../examples/cmd/README.md) contains scripts to install and uninstall test data using an internal executor with minimal functionality. For the CMD server it is important, that a script path given has the correct DOS notation using backslash \ and drive names if path is not relative.

## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).