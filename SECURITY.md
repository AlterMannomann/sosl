# Security
- [Basic thoughts](#basic-thoughts)
- [Roles](#roles)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](README.md)
## Basic thoughts
First, it is difficult to obtain a minimum of security as Oracle, on the command line, requires username and password unless you are an authenticated system user like oracle on the db server, where you can login with slash (/) or a wallet is configured.

If you want to use wallets the SOSL server is limited to the OS user under which it runs. Thus, whenever you connect with / you will get the wallet of the OS user. You may mitigate this by running different instances with different OS users and wallets. This will put more workload on the server used.

The basic solution will read a login file as input for sqlplus using the following format to guarantee that Oracle ends the session on invalid logins with a proper exit code.

    username/password@db_name_or_tns_name
    --/--
    --/--

This ensures, if used as an input (sqlplus < sosl_login.cfg) for SQLPlus, that the login data are neither visible on screen nor in any log. You may replace this by an OS function that returns this string in the same manner as TYPE does. But this will involve a handful of changes to the SOSL system, depending on the used solution (cmd/ps/sh) where the explicite calls have to be adjusted to use your function instead of type. The relevant functions are called sosl_sql... that have to be adjusted.

The script call then will use basically (CMD example)

    (TYPE %SOSL_PATH_CFG%sosl_login.cfg && ECHO @@script_to_call.sql "Parameter") | sqlplus

If you want to inject a programm for the CMD solution, you have to replace the TYPE with a DOS program that results in the output of the three needed lines for the login. Calling a CMD at this point doesn't work well at least with Windows 11, so it should be an EXE to call.

However, if there is still some sort of file, the content is visible to those, who have the necessary rights. Thus anyone with this rights, also if hacked, can see the password and user. The default version will use files and can't be declared as secure therefore.

Database security, regarding executed srcipts, can be improved, if SOSL is installed in a separate schema and has sufficient rights to other schemas, that are accessed by scripts. In this case, the used database objects in the scripts should be qualified (schema.object). You may revoke the CREATE ROLE privilege after installing from SOSL.

Nevertheless, running any script from any source system is a high risk and only applicable in very rare cases, like testing.

To enhance security you may limit access to SOSL schema and check the compile dates of database objects. Those should be stable if the system is setup and running. Additionally you may audit all or specific schema objects. Use SOSL_UTIL.OBJECT_DATE to retrieve last DDL dates of SOSL objects.

**DO NOT USE SOSL FOR PRODUCTION SYSTEMS**

Find a better solution. If you know what scripts to execute, put them in the database. You should not quick fix production systems as they have an reliable and accepted state. Use a hotfix for those issues and avoid those issues before going to production due to proper testing. If you, nevertheless, use SOSL for production systems, please remember: **This is your decision and you have to deal with all consequences**.
## Roles
On database level several cascading roles are available: SOSL_ADMIN, SOSL_EXECUTOR, SOSL_REVIEWER, SOSL_USER.

    SOSL_ADMIN
    |- additional delete and execute rights
    |_ SOSL_EXECUTOR
      |- additional insert and execute rights
      |_ SOSL_REVIEWER
        |- additional update and execute rights
        |_ SOSL_USER
          |- basic select and execute rights

The application manages necessary role grants for configured function owners. Only reviewed executors will get the role SOSL_EXECUTOR granted, otherwise this role, if it exists for an invalid executor, gets revoked. Roles higher or equal to SOSL_USER can use the SQL Developer reports.

Roles are owned and created by the DBA user during basic install and granted with ADMIN option to SOSL. Use SOSL schema owner or DBA to grant the roles to database users. The SOSL_EXECUTOR grants are managed for defined executors. SOSL will grant or revoke SOSL_EXECUTOR to a defined executor function owner automatically. Other roles have to be granted manually, as well as EXECUTE grants for SOSL_EXECUTOR on the defined executor API functions.

It is not recommended to grant object rights to SOSL directly. Use a role instead. If SOSL can't access the objects to grant to a specific role use a DBA account.
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).