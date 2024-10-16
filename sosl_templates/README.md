This folder contains templates of configuration files the Simple Oracle Script Loader.

The term configuration file is used only for files that contain sensitive data, credentials and secrets.

## Rule of the thumb
- copy the file to the configured SOSL_PATH_CFG or the configured batch group batch_cfg_path.
- do not change the file name
- change only credentials or login strings, do not change other parts

### Using sosl_login.cfg
This file contains the basic login and is piped as input to sqlplus. There should not be any additional comment in this file. Change only the login string in the first line. The two additional lines are needed to end the sqlplus session if login failed. Otherwise they are treated as comments. There must be an empty line at the end.

This config file type is used by the default version of the Simple Oracle Script Loader. You may adjust sosl_login.cmd to inject your own program that produces this three lines of output without saving login credentials to files.

### Created by DBA setup
The file [sosl_dba_setup.sql](../setup/sosl_dba_setup.sql) will create a default template assuming an instance named soslinstance is prepared and available through TNS. If such an instance exists, just move the created file to the defined configuration folder (default ../../cfg from run directory, which is a directory outside the repository). Otherwise copy the file to the configuration directory and adjust it as needed.

### Testing the configuration file
You can simply use

    sqlplus < path_to_file/sosl_login.cfg
    -- e.g. with absolute path
    sqlplus < C:\my_secrets\sosl_login.cfg
    sqlplus < /my_secrets/sosl_login.cfg

to test if the connect is working.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt)