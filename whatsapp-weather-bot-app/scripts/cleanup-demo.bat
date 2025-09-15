@echo off
echo WARNING: This will destroy all AWS infrastructure and stop charges.
set /p confirm="Are you sure? (y/N): "
if /i "%confirm%"=="y" goto destroy
echo Cancelled.
goto end

:destroy
echo Destroying infrastructure...
cd terraform/environments/dev
terraform init -input=false
terraform destroy -auto-approve
echo Infrastructure destroyed. AWS charges stopped.

:end
pause
