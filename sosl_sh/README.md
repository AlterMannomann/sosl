#  Simple Oracle Script Loader - bash solution
This folder contains the bash script components which work also with reduced git bash for the Simple Oracle Script Loader.

- [Requirements](#requirements)
- [Preparation](#preparation)
- [Configuration](#configuration)
- [Install the SOSL schema](#install-the-sosl-schema)
- [Configure the SOSL schema](#configure-the-sosl-schema)
- [Start the server](#start-the-server)
- [Running SOSL bash server under Windows](#running-sosl-bash-server-under-windows)
- [Testing](#testing)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../README.md)

## Requirements
- Bash environment, either unix or Windows git-bash.
- Access to Oracle via SQLPlus from your server/machine.
- DBA Setup done and valid login config file available on your server/machine.
- SOSL repository available on your server/machine.
- Access to command console (may require admin rights).
- The user running SOSL must have sufficient access rights on the configured directories.
  - READ on configured SOSL_PATH_CFG, place where the login config file of SOSL is stored.
  - READ on any other login configuration path that is configured for executors.
  - READ WRITE on configured SOSL_PATH_TMP and SOSL_PATH_LOG.
  - READ on SOSL repository, WRITE if log or temp path are part of the repository structure.
- Scripts to be executed should be pure UTF-8, not UTF-8 with BOM, this most likely causes errors with SQLPlus.
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
  1. Check the memory that the running server consumes
  2. Depending on the server and other users, the amount of memory for SOSL maybe limited. Make sure that the server has at least 20% or more free memory when SOSL is executed with maximum parallel scripts active.
  3. SOSL_MAX_PARALLEL should be adjusted on database level. No need to change bash configuration.
8. Define the users and executors as well as the role grants.

DBA setup should have created a valid sosl_login.cfg file. If the DBA setup was on a different machine, the TNS or server name probably has to be adjusted. If administration already defined a path for this login config files, the corresponding login file must exist in this path. The name of this file is not constrained. It can be any valid filename that you or your organization defines.

This file and path is the heart of SOSL access to the database and needed for the configuration. It is also a security risk, especially if not managed well.
## Configuration
Use and adjust the file [sosl_config.sh](sosl_config.sh) to adjust local server parameters. The rest is configured in the database.

You can adjust the path for temporary and log directory, the login config file name, the path to this file, the log file name and file name extensions.
## Install the SOSL schema
If the schema is already installed you can skip this section.

Before you install the schema, the configuration file [sosl_config.sh](sosl_config.sh) must have been setup correctly and the login configuration file must match with configured name and path.

If all requirements fulfilled, simply start [./sosl_install.sh](sosl_install.sh) on the command line, either with correct path or directly from this directory. The logfile of the install will be stored inside this repository under [setup/logs](../setup/logs/README.md).
## Configure the SOSL schema
Setup configuration and executors as desired. Grant necessary SOSL roles to users, executors, reviewers and admins.
## Start the server
To start the server simply run [./start_sosl_server.sh](start_sosl_server.sh) from the command line.

Without parameter the server runs directly in your session window.

If you add 0 as parameter (./start_sosl_server.sh 0) the server will run in background, list current jobs and then constantly tail output the current server logfile.

If you add 1 as parameter (./start_sosl_server.sh 1) the server will run in background, list jobs and the script returns to your session prompt.

It is recommended to use

    ./start_sosl_server.sh 1

and use the scripts [./watch_sosl_server.sh](watch_sosl_server.sh) to get a tail of the current log and [./watch_sqlplus_sessions.sh](watch_sqlplus_sessions.sh) for controlling the current running SQLPlus sessions on the server. If using git-bash the SQLPlus session watcher only works, if executed in the same git-bash window that started the server.
## Running SOSL bash server under Windows
With git-bash you have the option to run the SOSL bash server as a background command using the Windows Task Scheduler.
To do so, define in actions of Windows Task Scheduler the program to execute. If you're not having a standard installation adjust the path.

    "C:\Program Files\Git\git-bash.exe"

Define the arguments vor git-bash.exe:

    -c "./start_sosl_server.sh"

Define the path to run in (adjust the example):

    C:\your_repo_path\sosl\sosl_sh

With this action you can define triggers or start the task manually. You may use local SYSTEM, if allowed by policy, to run this task.

You can also setup a stop task using -c "./stop_sosl_locally.sh". Or you define the stop job in the database by setting the run mode to stop.

If you expect constant flow of scripts to run it is better to use the database to stop, as this will set the scripts waiting for execution immediately to 0. So the server will run until all current scripts are finished and stop then. Locally stopping waits for the moment where no further scripts have to be processed to stop and no scripts are running.
## Testing
The directory [examples\sh](../examples/sh/README.md) contains scripts to install and uninstall test data using an internal executor with minimal functionality. For the bash server it is important, that a script path given has the correct unix notation using slash /.

## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).