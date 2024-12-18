# Types
This folder contains the type definitions for the Simple Oracle Script Loader.

- [SOSL_PAYLOAD](#sosl_payload)
  - [EXECUTOR_ID](#executor_id)
  - [EXT_SCRIPT_ID](#ext_script_id)
  - [SCRIPT_FILE](#script_file)
  - [Create SOSL_PAYLOAD](#create-a-sosl_payload-object)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../../README.md)

## SOSL_PAYLOAD
You need at least the role SOSL_EXECUTOR to access this object. It contains three items (executor id, external script id and script filename with path) that are mandatory if at least one item is set. It is used to transfer data between SOSL and executor.
### EXECUTOR_ID
Field type is NUMBER(38, 0) equal to the executor id definition in the table [SOSL_EXECUTOR_DEFINITION](../tables/sosl_executor_definition.sql).

It refers to an executor id configured in this table. The executor id is expected to exist, set to active and reviewed. Executors not in the desired state are not processed by SOSL.

It is recommended that you store your executor id with a foreign key constraint in your executor schema to be able to access it correctly.
### EXT_SCRIPT_ID
Field type is VARCHAR2(4000). If your internal script id is of any other type, you must convert it accordingly for set and get.

It refers to your internal script id that lets you identify your script reference as an executor. SOSL is using internally a run id and stores this information in the run queue.
### SCRIPT_FILE
Field type is VARCHAR2(4000).

It refers to the script filename to execute and must include a relative or absolute path accessible to SOSL on the machine running. The path delimiter notation is **important**, depending on the type of server used.

When using the SOSL CMD server, path delimiter is \ (e.g. C:\myrepo\myscript.sql), if using the SOSL bash server, path delimiter is / (e.g. ../../myrepo/myscript.sql).
### Create a SOSL_PAYLOAD object
If the SOSL user is not SOSL you have to adapt the script, qualifying it with the SOSL user in use. And you have to have SOSL_EXECUTOR role granted.

    SET SERVEROUTPUT ON SIZE UNLIMITED
    DECLARE
      l_payload SOSL.SOSL_PAYLOAD;
    BEGIN
      l_payload := sosl_payload(1, 'My script ID', '../../mydir/scriptfile.sql');
      DBMS_OUTPUT.PUT_LINE('executor id: ' || l_payload.executor_id);
      DBMS_OUTPUT.PUT_LINE('my script id: ' || l_payload.ext_script_id);
      DBMS_OUTPUT.PUT_LINE('script file: ' || l_payload.script_file);
    END;
    /

## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).