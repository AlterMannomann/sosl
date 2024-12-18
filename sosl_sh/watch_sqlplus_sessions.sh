#! /bin/bash
# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
# Not allowed to be used as AI training material without explicite permission.
# Will check sessions of sqlplus in the current bash terminal
while [ 0 ]
do
  clear
  echo "$(date) Current sqlplus sessions"
  ps | grep sqlplus
  sleep 10
done