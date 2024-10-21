@ECHO OFF
REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
VERIFY OTHER 2>NUL
SETLOCAL ENABLEEXTENSIONS
IF ERRORLEVEL 0 (
  ECHO CMD expansion possible
) ELSE (
  ECHO No CMD expansion possible
)
