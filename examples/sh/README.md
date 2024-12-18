# SOSL bash server examples
The shell file [./install_test_scripts.sh](install_test_scripts.sh) will, when executed, install a basic executor using the internal minimalistic script run functionality. It installs some scripts which do nothing else than wait, apart from one script that provokes an error. Includes a longrunner script that waits for an hour.

After installation, executor is active and reviewed, defined scripts in SOSL_IF_SCRIPT are active and wait for the server to be running, which will start to execute the scripts and log the result.

To uninstall the example scripts use [./uninstall_test_scripts.sh](uninstall_test_scripts.sh).

The unix path notation with slash / is important for the SOSL bash server. Scripts may not run correct, if using Windows path notation with backslash \\.

[Back to main](../../README.md)
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).