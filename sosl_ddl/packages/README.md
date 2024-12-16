# Packages
This folder contains the packages for the Simple Oracle Script Loader.

- [SOSL_CONSTANTS](#sosl_constants)
- [SOSL_LOG](#sosl_log)
- [SOSL_SERVER](#sosl_server)
- [SOSL_API](#sosl_api)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../../README.md)
## SOSL_CONSTANTS
This package defines constants that can be used with SOSL implementation interfaces. **This package is not intended for user modifications.** Many internal routines, especially in error situations, provide hardcoded values to avoid that someone tweaks the constants.

You may use either the package variables in PL/SQL or the associated get functions in SQL statements.

Package description [sosl_constants.pks](sosl_constants.pks).
## SOSL_LOG
This package contains the logging functions that are used by SOSL and can be used by implementation interfaces.

Package description [sosl_log.pks](sosl_log.pks).
## SOSL_SERVER
Main SOSL server and implementation interface package.

Main implementation interface functions are:
- get_payload
- has_run_id

You may want to use dummy_mail to create a log entry with the formatting of provided mails.

See examples in [sosl_if.pkb](sosl_if.pkb) for typical usage.

## SOSL_API
Utility functions for SOSL user.

## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).