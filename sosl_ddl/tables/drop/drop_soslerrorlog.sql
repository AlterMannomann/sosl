-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
REVOKE SELECT ON soslerrorlog FROM sosl_reviewer;
REVOKE DELETE ON soslerrorlog FROM sosl_admin;
DROP TABLE soslerrorlog PURGE;