# Design
- [Project structure](#project-structure)
- [Basic server design](#basic-server-design)
- [Data model](#data-model)
- [SOSL CMD server](#sosl-cmd-server)
- [SOSL bash server](#sosl-bash-server)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](README.md)
## Project structure
The project is designed for running directly from the repository. Directories for temporary and log files can be configured and will be, by default using the upper directory of the repository.

    directory structure:
    - repo directory
    -- sosl repository
    --- sosl content
    --- sosl run directory (always on the 2nd level, so ../../any_path leads to directories in the upper repo directory)
    ---- sosl_server.(cmd/sh)
    -- other repositories
    -- sosl_log (the default SOSL logging directory)
    -- sosl_tmp (the default SOSL temporary directory)
    -- sosl_cfg (the default SOSL directory for SQLPlus login secrets)
    -- your_repo

Given this structure it is possible to reference scripts relative to the SOSL repository directory by

    ../../your_repo/relative_path_to_script

SOSL can handle relative repository paths to start scripts relative to the given repository directory. Otherwise you can use a script filename using the full path. This path must exist on the server SOSL is running locally.

The configuration path for SOSL will hold the sosl_login.cfg and might as well contain login files for the different users with which the scripts will get started. Executors can defined the path and name of the login config file.

    sosl_cfg (the default SOSL directory for SQLPlus login secrets)
    - sosl_login.cfg (the login secrets for sosl)
    - repo1_login.cfg (example name for login secrets, for scripts executed in repo1)
    - repo2_login.cfg (example name for login secrets, for scripts executed in repo2)
## Basic server design
The basic server design is

    sosl_server
      - load configuration
      - run loop
        - exit on stop signal
        - check for available scripts
        - run available scripts
        - wait as defined
## Data model
See [SOSL DDL](sosl_ddl/README.md).
## SOSL CMD server
See [SOSL CMD server](sosl_cmd/README.md).
## SOSL bash server
See [SOSL bash server](sosl_sh/README.md).
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).