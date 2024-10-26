-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Basic package providing the API to the Simple Oracle Script Loader.
CREATE OR REPLACE PACKAGE sosl_api
AS
  /**
  * This package contains SOSL API functions and procedures to be used by executors.
  */

  FUNCTION dummy
    RETURN NUMBER
  ;
END;
/