-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE OR REPLACE PACKAGE BODY sosl
AS
  -- see package header for documentation
  FUNCTION has_scripts
    RETURN NUMBER
  IS
  BEGIN
    RETURN -1;
  END has_scripts;

  FUNCTION get_next_script
    RETURN SOSL_PAYLOAD
  IS
  BEGIN
    RETURN NULL;
  END get_next_script;

  FUNCTION set_script_status( p_reference   IN SOSL_PAYLOAD
                            , p_status      IN NUMBER
                            , p_status_msg  IN VARCHAR2 DEFAULT NULL
                            )
    RETURN NUMBER
  IS
  BEGIN
    RETURN -1;
  END set_script_status;

END;
/