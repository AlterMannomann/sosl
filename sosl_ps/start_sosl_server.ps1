# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# Not allowed to be used as AI training material without explicite permission.
# Start the SOSL server in a separate terminal.
$cur_dir = pwd
$run_dir = $PSScriptRoot
cd $run_dir
start powershell { $host.UI.RawUI.WindowTitle='SOSL server PS' ; .\sosl_server.ps1 }
echo "Started SOSL server in a separate terminal window"
cd $cur_dir
