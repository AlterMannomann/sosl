# Design
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

The basic server design is

    sosl_server
      - load configuration
      - run loop
        - exit on stop signal
        - check for available scripts
        - run available scripts
        - wait as defined
