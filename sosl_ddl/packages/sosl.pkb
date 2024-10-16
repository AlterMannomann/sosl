-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE OR REPLACE PACKAGE BODY sosl
AS
  -- see package header for documentation
  FUNCTION set_config( p_config_name  IN VARCHAR2
                     , p_config_value IN VARCHAR2
                     )
    RETURN NUMBER
  IS
  BEGIN
    RETURN NULL;
  END set_config;

  FUNCTION get_config(p_config_name IN VARCHAR2)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END get_config;

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