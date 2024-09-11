-- main package of the Simple Oracle Script Loader
CREATE OR REPLACE PACKAGE sosl
AS
  /**
  * This package contains the main functions and procedures used by the Simple Oracle Script Loader.
  */

  /** Function SOSL.HAS_SCRIPTS
  * Determines if scripts are available to be executed.
  *
  * @return The number of scripts waiting for execution.
  */
  FUNCTION has_scripts
    RETURN INTEGER
  ;

  /** Function SOSL.NEXT_SCRIPT
  * Determines the next script to execute.
  *
  * @return The name of the script with relative or full path.
  */
  FUNCTION next_script
    RETURN VARCHAR2
  ;

END;
/