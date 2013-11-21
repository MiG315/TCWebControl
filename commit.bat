@echo off
cd C:\PChart\TCWebControl
:param1Prompt
set /p "m=Enter comit message: "
:param1Check
if "%m%"=="" goto :param1Prompt
git add .
git commit -m "%m%"
git push origin master