-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Must be executed before the view sosl_install_v is dropped. Cleans the SOSL setup
-- entries, if any.
DELETE FROM sperrorlog WHERE username = (SELECT sosl_schema FROM sosl_install_v);
COMMIT;