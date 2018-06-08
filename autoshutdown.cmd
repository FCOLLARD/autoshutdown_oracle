echo OFF
REM 
REM Example of use: 
REM   autoshutdown oracle:thin:@mancswgtb0012:1521:fbti    TIZONE14   TIZONE14 
REM     autoshutdown  oracle	 mancswgtb0012 				fbti    		TIZONE14   TIZONE14
REM             [TYPE oracle]   [SERVER mancswgtb0012]  [DBNAME fbti]       [USER TIZONE14]     [PASSWD TIZONE14]
REM COMMAND to build :
REM   java -jar dist\autoshutdown.jar    oracle:thin:@mancswgtb0012:1521:fbti    TIZONE14   TIZONE14
REM java...    %TYPE%:thin:@%SERVER%:1521:%DBNAME% %USER%   %PASSWD%

if @%1 == @   ( echo Syntax: %0% [oracle|db2] Server Timetest [default:60] ; exit /b)

SET URL=%1
SET USER=%2 
SET PASSWD=%3
SET NBLOOPS=60


if %URL:~0,6% == oracle ( set TYPE=ORACLE & SET SRVx=%URL:~13% )
if %URL:~0,3% == db2    ( set TYPE=DB2    & SET SRVx=%URL:~6% )

echo db type is %TYPE%
for /F "tokens=1 delims=:@" %%a in ("%SRVx%") ; do ( SET SERVER=%%a )
 echo SERVER=%SERVER%
 

echo Splitting  URL=%URL%
IF %TYPE% == ORACLE for /F "tokens=1,2,3,4,5 delims=:@" %%a in ("%URL%") ; do ( SET TYPE=%%a &	SET SEPAR=%%b &	SET SERVER2=%%c & 	SET PORT=%%d &	SET DBNAME=%%e )
IF %TYPE% == DB2    for /F "tokens=1,2,3,4 delims=:/" %%a in ("%URL%") ; do ( SET TYPE=%%a &	SET SERVER2=%%b & 	SET PORT=%%c &	SET DBNAME=%%d )

echo 	TYPE=%TYPE%  SEPAR=%SEPAR% SERVER2=%SERVER2% PORT=%PORT%  DBNAME=%DBNAME%


REM   autoshutdown   db2 C1WC1WC1229	TIPLUS2 	TIZONE28 T!Z0N3123
REM   autoshutdown db2://C1WC1WC1229:50000/TIPLUS2         TIZONE28   T!Z0N3123
REM   java -jar dist\autoshutdown.jar    db2://C1WC1WC1229:50000/TIPLUS2         TIZONE28   T!Z0N3123
REM  [TYPE=db2]      [SERVER=C1WC1WC1229]      [DBNAME=TIPLUS2]    [USER=TIZONE28]     [PASSWD=T!Z0N3123]
REM COMMAND to build :
REM java...    %TYPE%://%SERVER%:50000/%DBNAME%     %USER%  %PASSWD%


for /F %%i IN ('hostname' ); DO set LOCALHOST=%%i
cd %~dp0

echo %0 running on %LOCALHOST% ... Args: %* 

if %1 == /? ( echo Syntax: %0% Server Timetest [default:60] ; exit /b )
 
REM ******************************************
REM  

ping -n 1 %SERVER%

IF NOT %ERRORLEVEL% == 0 GOTO :ENDING_PING_FAIL 

REM ******************************************

echo %DATE% %TIME%: Running on server: %SERVER% %SERVER2%

REM ******************************************
REM set URL=50000/TIPLUS2
REM SET USER=TIZONE28 
REM SET PASSWD=T!Z0N3123

ping -n 1 %SERVER% || ( set /P ERR="echo Cannnot yet ping %SERVER% .Press return to quit." ; goto :ENDING_PING_FAIL)

REM IF QUERY.exe exist here or is installed (rarely) 
echo.
echo   Querying the Active Remote Desktop Connections: 
QUERY.exe user /server %SERVER% | findstr "Active"  && set /P W="Warning Active connections are present on %SERVER%. Press return to continue..."
 
echo About to run java -jar dist\autoshutdown.jar %* %NBLOOPS%
set /P xx="Press return to continue..."

echo %TIME% : Idle detection started...
java -jar dist\autoshutdown.jar %* %NBLOOPS%

goto ENDING_%ERRORLEVEL%
goto :END

:ENDING_PING_FAIL
echo  %TIME% : Exit status: %ERRORLEVEL%
set /P ERR="echo cannnot ping this host: %SERVER%.  Press return to quit."  
GOTO END

:ENDING_0
echo Good status but no actions yet.
GOTO END

:ENDING_999
echo Exit status: %ERRORLEVEL%

echo.
echo OK Shutdown is valid ! 
echo.
echo to abort the shutdown that will occur in 30 seconds, you could try :
echo shutdown -a -m \\%SERVER% 
timeout 30 
echo Shutdown starting...
SHUTDOWN  -s -m \\%SERVER% -t 60 
REM net stop   DB2
REM NET STOP  
echo .
GOTO END

:ENDING_992
GOTO END

:ENDING_993
echo ERROR 993: SQLException, no way to decide what to do. 
echo Hit this if you are sure: 

echo SHUTDOWN  -s -m -i \\%SERVER% -c "Normal shutdown after SQL inactivity detected." 
echo SHUTDOWN  /s /m \\%SERVER%GOTO END
echo Syntax to stop a running shutdown: SHUTDOWN  -a -m -i \\%SERVER% 
:ENDING_994
GOTO END
:ENDING_130
echo Exit status: %ERRORLEVEL%
echo Error startus 130 . aborted due to syntax

GOTO END

:ENDING_1
echo  Exit status: %ERRORLEVEL%
Echo Not managed.
GOTO END

:END
echo %TIME% . exiting from  %0% ...
timeout 10
exit /B
