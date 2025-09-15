@echo off
echo Checking current AWS resources and estimated costs...
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'weather-bot')].LoadBalancerName" 2>nul || echo No load balancers found
aws ecs describe-clusters --clusters weather-bot --query "clusters[0].status" 2>nul || echo ECS cluster not found
pause
