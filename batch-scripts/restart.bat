:: RESTARTS CONTAINER
@echo off
setlocal
set imageVersion=24.08.1
set imageName=ubuntu-dev-vm

echo Stopping %imageName%...
docker container stop %imageName% > nul 2>&1

echo Removing %imageName%...
docker container rm %imageName% > nul 2>&1

echo Starting %imageName%...
docker container run --privileged --gpus all -d ^
	--name %imageName% ^
	--hostname %imageName% ^
	-p 8080:8080 -p 8443:8443 ^
	--mount source=projects,target=/home/dev/projects ^
	--mount source=maven,target=/home/dev/.m2/repository ^
	--mount source=home,target=/home/dev ^
	--mount source=docker,target=/var/lib/docker ^
	--mount type=bind,source=%USERPROFILE%,target=/mnt/shared ^
	javowiec/%imageName%:%imageVersion% > nul

echo DONE!
pause
endlocal
