# Security
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
On database level several cascading roles are available: SOSL_ADMIN, SOSL_EXECUTOR, SOSL_REVIEWER, SOSL_USER, SOSL_GUEST.

    SOSL_ADMIN
    |- DELETE rights
    |_ SOSL_EXECUTOR
      |- select, insert and update rights, execute rights
      |_ SOSL_REVIEWER
        |- select rights, limited update rights
        |_ SOSL_USER
          |- select rights
          |_ SOSL_GUEST
            |- limited select rights

The application manages necessary role grants for configured function owners. Only reviewed executors will get the role SOSL_EXECUTOR granted, otherwise this role, if it exists for an invalid executor, gets revoked. Roles higher or equal to SOSL_USER can use the SQL Developer reports.

Grant any privilege needed to the role SOSL_EXECUTOR instead of granting it directly to SOSL schema. You should not grant SOSL objects to SOSL roles. Grant a SOSL role to database users according to their tasks. For database users that differ from the function owner, it is quite enough to grant the SOSL_USER role. The roles SOSL_EXECUTOR and SOSL_ADMIN should be used very limited. For creating a new executor you need at least SOSL_EXECUTOR rights. It is recommended that you use the function owner, granted SOSL_EXECUTOR role, to create the executor. Or you define a database user with SOSL_EXECUTOR role that creates the executors.
