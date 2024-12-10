-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- Sets a schema for a current session. No error checking.
-- parameter 1: The db schema to use
ALTER SESSION SET CURRENT_SCHEMA=&1;
