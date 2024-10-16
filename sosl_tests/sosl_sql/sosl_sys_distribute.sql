SET SERVEROUTPUT ON SIZE UNLIMITED
DECLARE
  l_clob    CLOB;
  l_string  VARCHAR2(32000);
  l_result  BOOLEAN;
BEGIN
  DBMS_OUTPUT.PUT_LINE('---------CASE 1 both NULL');
  l_string := '';
  l_clob := NULL;
  DBMS_OUTPUT.PUT_LINE('init string length: ' || NVL(LENGTH(l_string), 0));
  DBMS_OUTPUT.PUT_LINE( 'init clob length: ' || NVL(LENGTH(l_clob), 0));
  l_result := sosl_sys.distribute(l_string, l_clob);
  DBMS_OUTPUT.PUT_LINE('distribute string length: ' || NVL(LENGTH(l_string), 0));
  DBMS_OUTPUT.PUT_LINE('distribute clob length: ' || NVL(LENGTH(l_clob), 0));
  DBMS_OUTPUT.PUT_LINE('result: ' || CASE WHEN l_result THEN 'TRUE' ELSE 'FALSE' END);
  DBMS_OUTPUT.PUT_LINE('---------CASE 2 both filled');
  l_string := TRIM(LPAD(' ', 32000, 'string12345'));
  DBMS_OUTPUT.PUT_LINE('init string length: ' || NVL(LENGTH(l_string), 0));
  l_clob := ' ';
  -- build clob0
  FOR i IN 1..40000
  LOOP
    l_clob := TRIM(l_clob || 'clob123456');
  END LOOP;
  DBMS_OUTPUT.PUT_LINE( 'init clob length: ' || NVL(LENGTH(l_clob), 0));
  l_result := sosl_sys.distribute(l_string, l_clob);
  DBMS_OUTPUT.PUT_LINE('distribute string length: ' || NVL(LENGTH(l_string), 0));
  DBMS_OUTPUT.PUT_LINE('distribute clob length: ' || NVL(LENGTH(l_clob), 0));
  DBMS_OUTPUT.PUT_LINE('distribute string begin: ' || SUBSTR(l_string, 1, 20));
  DBMS_OUTPUT.PUT_LINE('distribute string end: ' || SUBSTR(l_string, -20));
  DBMS_OUTPUT.PUT_LINE('distribute clob begin: ' || SUBSTR(l_clob, 1, 20));
  DBMS_OUTPUT.PUT_LINE('distribute clob middle: ' || SUBSTR(l_clob, 27990, 40));
  DBMS_OUTPUT.PUT_LINE('distribute clob end: ' || SUBSTR(l_clob, -20));
  DBMS_OUTPUT.PUT_LINE('result: ' || CASE WHEN l_result THEN 'TRUE' ELSE 'FALSE' END);
  DBMS_OUTPUT.PUT_LINE('---------CASE 3 CLOB filled');
  l_string := '';
  l_clob := '';
  -- build clob
  FOR i IN 1..40000
  LOOP
    l_clob := TRIM(l_clob || 'clob123456');
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('init string length: ' || NVL(LENGTH(l_string), 0));
  DBMS_OUTPUT.PUT_LINE( 'init clob length: ' || NVL(LENGTH(l_clob), 0));
  l_result := sosl_sys.distribute(l_string, l_clob);
  DBMS_OUTPUT.PUT_LINE('distribute string length: ' || NVL(LENGTH(l_string), 0));
  DBMS_OUTPUT.PUT_LINE('distribute clob length: ' || NVL(LENGTH(l_clob), 0));
  DBMS_OUTPUT.PUT_LINE('distribute string begin: ' || SUBSTR(l_string, 1, 20));
  DBMS_OUTPUT.PUT_LINE('distribute string end: ' || SUBSTR(l_string, -20));
  DBMS_OUTPUT.PUT_LINE('distribute clob begin: ' || SUBSTR(l_clob, 1, 20));
  DBMS_OUTPUT.PUT_LINE('result: ' || CASE WHEN l_result THEN 'TRUE' ELSE 'FALSE' END);
  DBMS_OUTPUT.PUT_LINE('---------CASE 4 String filled');
  l_clob := '';
  l_string := TRIM(LPAD(' ', 32000, 'string12345'));
  DBMS_OUTPUT.PUT_LINE('init string length: ' || NVL(LENGTH(l_string), 0));
  DBMS_OUTPUT.PUT_LINE( 'init clob length: ' || NVL(LENGTH(l_clob), 0));
  l_result := sosl_sys.distribute(l_string, l_clob);
  DBMS_OUTPUT.PUT_LINE('distribute string length: ' || NVL(LENGTH(l_string), 0));
  DBMS_OUTPUT.PUT_LINE('distribute clob length: ' || NVL(LENGTH(l_clob), 0));
  DBMS_OUTPUT.PUT_LINE('distribute string begin: ' || SUBSTR(l_string, 1, 20));
  DBMS_OUTPUT.PUT_LINE('distribute string end: ' || SUBSTR(l_string, -20));
  DBMS_OUTPUT.PUT_LINE('distribute clob begin: ' || SUBSTR(l_clob, 1, 20));
  DBMS_OUTPUT.PUT_LINE('distribute clob end: ' || SUBSTR(l_clob, -20));
  DBMS_OUTPUT.PUT_LINE('result: ' || CASE WHEN l_result THEN 'TRUE' ELSE 'FALSE' END);
  DBMS_OUTPUT.PUT_LINE('---------CASE 5 both filled no distribute');
  l_clob := 'clob123456';
  l_string := 'string12345';
  DBMS_OUTPUT.PUT_LINE('init string length: ' || NVL(LENGTH(l_string), 0));
  DBMS_OUTPUT.PUT_LINE( 'init clob length: ' || NVL(LENGTH(l_clob), 0));
  l_result := sosl_sys.distribute(l_string, l_clob);
  DBMS_OUTPUT.PUT_LINE('distribute string length: ' || NVL(LENGTH(l_string), 0));
  DBMS_OUTPUT.PUT_LINE('distribute clob length: ' || NVL(LENGTH(l_clob), 0));
  DBMS_OUTPUT.PUT_LINE('distribute string begin: ' || SUBSTR(l_string, 1, 20));
  DBMS_OUTPUT.PUT_LINE('distribute clob begin: ' || SUBSTR(l_clob, 1, 20));
  DBMS_OUTPUT.PUT_LINE('result: ' || CASE WHEN l_result THEN 'TRUE' ELSE 'FALSE' END);
END;
/

