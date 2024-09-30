This folder contains templates of configuration files the Simple Oracle Script Loader.

The term configuration file is used only for files that contain sensitive data, credentials and secrets.

## Rule of the thumb
- copy the file to the configured SOSL_PATH_CFG or the configured batch group batch_cfg_path.
- do not change the file name
- change only credentials or login strings, do not change other parts

### Using sosl_login.cfg
This file contains the basic login and is piped as input to sqlplus. There should not be any additional comment in this file. Change only the login string in the first line. The two additional lines are needed to end the sqlplus session if login failed. Otherwise they are treated as comments. There must be an empty line at the end.

This config file type is used by the default version of the Simple Oracle Script Loader. You may adjust sosl_login.cmd to inject your own program that produces this three lines of output without saving login credentials to files.
