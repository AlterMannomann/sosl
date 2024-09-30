CREATE OR REPLACE PACKAGE BODY sosl
AS
  -- see package header for documentation
  FUNCTION has_run_ids
    RETURN NUMBER
  IS
  BEGIN
    RETURN NULL;
  END has_run_ids;

  FUNCTION next_run_id
    RETURN NUMBER
  IS
  BEGIN
    RETURN NULL;
  END next_run_id;

  FUNCTION base_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END base_path;

  FUNCTION cfg_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END cfg_path;

  FUNCTION tmp_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END tmp_path;

  FUNCTION log_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END log_path;

END;
/