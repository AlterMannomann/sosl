# Packages
This folder contains the packages for the Simple Oracle Script Loader.

- [SOSL_CONSTANTS](#sosl_constants)
- [SOSL_API](#sosl_api)
- [SOSL_LOG](#sosl_log)
- [SOSL_SERVER](#sosl_server)
- [SOSL_SYS](#sosl_sys)
- [SOSL_UTIL](#sosl_util)
- [SOSL_IF](#sosl_if)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../../README.md)
## SOSL_CONSTANTS
This package defines constants that can be used with SOSL implementation interfaces. **This package is not intended for user modifications**. Nevertheless some internal routines, especially in error situations, provide hardcoded values to avoid that someone tweaks the constants.

You may use either the package variables in PL/SQL or the associated get functions in SQL statements.

The package is available to all that have the SOSL_USER role.

Package description [sosl_constants.pks](sosl_constants.pks).
## SOSL_API
Main interface package for executors. Accessible with role SOSL_USER but functions will check the role of the current user and allow or deny execution (error result, no exception).

It contains
- utility and maintenance functions for SOSL_USER
- maintenance functions for SOSL_REVIEWER
- maintenance and interface functions (prefixed with IF_) for SOSL_EXECUTOR
- maintenance functions for SOSL_ADMIN

See examples in [sosl_if.pkb](sosl_if.pkb) for typical usage.

Package description [sosl_api.pks](sosl_api.pks).
## SOSL_LOG
This package contains the logging functions that are used by SOSL. The SOSL_API package provides an interface to the logging.

Package description [sosl_log.pks](sosl_log.pks).
## SOSL_SERVER
Main SOSL server and implementation package. The SOSL_API package provides an interface to some functions.

Package description [sosl_server.pks](sosl_server.pks).
## SOSL_SYS
Basic SOSL system function package.

Package description [sosl_sys.pks](sosl_sys.pks).
## SOSL_UTIL
Basic SOSL utility function package.

Package description [sosl_util.pks](sosl_util.pks).
## SOSL_IF
This package is not part of the SOSL core functionality. It is an example implementation of an executor where the objects are also in the SOSL schema. It only uses SOSL_API and SOSL_CONSTANTS to build the required interfaces and manage the scripts provided. The package can be used as a starting template for own executor implementations.

Package description [sosl_if.pks](sosl_if.pks).
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).