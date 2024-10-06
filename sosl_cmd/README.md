#  Simple Oracle Script Loader - CMD solution
This folder contains the CMD script components of the Simple Oracle Script Loader.
## Additional requirements
- CMD command extension available (SETLOCAL ENABLEEXTENSIONS)
## Configuration
Use and adjust the file [sosl_config.cmd](sosl_config.cmd) to adjust local server parameters. The rest is configured in the database.

**Do not touch other CMD files** unless you know what you're doing and your changes and improvements are well tested.
## Usage
To use the CMD solution, you have to start the CMD for the sosl server. You might use on command line after changing to the repository directory sosl_cmd:

    sosl_server.cmd
    REM or in an own window
    START sosl_server.cmd
    REM or with path from any location, where SOSLPATH reflects the local path where the SOSL repository root is located
    START /D %SOSLPATH%\sosl_cmd sosl_server.cmd
## Testing
The directory [sosl_tests\sosl_cmd](..\sosl_tests\sosl_cmd\README.md) contains some basic functional CMD testing scripts.
## Dev Notes:
- rework to use CALL on labels, labels set SOSL_EXITCODE and SOSL_ERRMSG, will make file more readable
  - so the following should work
  - CALL :LABEL
  - IF %SOSL_EXITCODE%==-1 GOTO :error_label
  - :LABEL should have an GOTO :EOF after statements to return to caller correctly
- Use SOSL_FILE_CFG with full path to the configuration file used for login instead of path

(C) 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt)