-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- create sosl roles
CREATE ROLE sosl_admin;
CREATE ROLE sosl_executor;
CREATE ROLE sosl_reviewer;
CREATE ROLE sosl_user;
CREATE ROLE sosl_guest;
-- hierarchical grants
GRANT sosl_guest TO sosl_user;
GRANT sosl_user TO sosl_reviewer;
GRANT sosl_reviewer TO sosl_executor;
GRANT sosl_executor TO sosl_admin;
