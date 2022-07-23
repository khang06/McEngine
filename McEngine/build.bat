@echo off
setlocal enableextensions enabledelayedexpansion

set NAME=McEngine
set BUILD=Windows Release

set SRC=src
set LIB=libraries

set CXX=g++
set CC=gcc
set LD=g++

set CXXFLAGS=-std=c++11 -O3 -Wall -c -fmessage-length=0 -Wno-sign-compare -Wno-unused-local-typedefs -Wno-reorder -Wno-switch
set CFLAGS=-O3 -Wall -c -fmessage-length=0

set PFLAGS=-D__GXX_EXPERIMENTAL_CXX0X__ -D__cplusplus=201103L

set LDFLAGS=-s
set LDLIBS=-logg -lADLMIDI -lmad -lmodplug -lsmpeg -lgme -lvorbis -lopus -lvorbisfile -ldiscord-rpc -lsteam_api -lSDL2_mixer_ext.dll -lSDL2 -ld3dcompiler_47 -ld3d11 -ldxgi -lopenvr_api -llibcurl -llibxinput9_1_0 -llibBulletSoftBody -llibBulletDynamics -llibBulletCollision -llibLinearMath -lfreetype -lopengl32 -lOpenCL -lvulkan-1 -lglew32 -lglu32 -lgdi32 -lbass -lbass_fx -lcomctl32 -lDwmapi -lComdlg32 -lpsapi -lenet -lws2_32 -lwinmm -lpthread -llibjpeg



set STARTTIME=%time%

set FULLPATH=%~dp0
echo FULLPATH =%FULLPATH%

echo [0mCreating %FULLPATH%%BUILD%\ directory ...
if exist "%FULLPATH%%BUILD%\" del /s/q "%FULLPATH%%BUILD%\"
if exist "%FULLPATH%%BUILD%\" rmdir /s/q "%FULLPATH%%BUILD%\"
if not exist "%FULLPATH%%BUILD%\NUL" mkdir "%FULLPATH%%BUILD%\"

set LDARGSFILE=%FULLPATH%._args_backslashes.txt
set LDARGSFILE2=%FULLPATH%._args.txt
if exist "%LDARGSFILE%" del /q "%LDARGSFILE%"
if exist "%LDARGSFILE2%" del /q "%LDARGSFILE2%"
echo LDARGSFILE2 = %LDARGSFILE2%

echo [0mCollecting C++ files ...
set /a NUMCPPFILES = 0
for /r "%FULLPATH%%SRC%" %%i in (*.cpp) do (
	echo %%i
	set CPPFILE!NUMCPPFILES!=%%i
	set /a NUMCPPFILES += 1
)

echo [0mCollecting C files ...
set /a NUMCFILES = 0
for /r "%FULLPATH%%SRC%" %%i in (*.c) do (
	echo %%i
	set CFILE!NUMCFILES!=%%i
	set /a NUMCFILES += 1
)

echo [0mCollecting %SRC% include paths ...
set /a NUMINCLUDEPATHS = 0
for /d /r "%FULLPATH%%SRC%" %%i in (*) do (
	echo %%i
	set INCLUDEPATH!NUMINCLUDEPATHS!=%%i
	set /a NUMINCLUDEPATHS += 1
)

echo [0mCollecting library include paths ...
for /d %%i in ("%FULLPATH%%LIB%"\*) do (
	if exist "%%i\include" (
		echo %%i\include
		set INCLUDEPATH!NUMINCLUDEPATHS!=%%i\include
		set /a NUMINCLUDEPATHS += 1
	)
)

echo [0mCompiling %NUMCPPFILES% C++ file(s) ...
for /l %%i in (0,1,%NUMCPPFILES%) do (
	if %%i lss %NUMCPPFILES% (
		set CPPFILEPATH=!CPPFILE%%i!
		for %%a in ("!CPPFILEPATH!") do set CPPFILENAME=%%~na
		
		set INCLUDEPATHS=
		for /l %%j in (0,1,%NUMINCLUDEPATHS%) do (
			if %%j lss %NUMINCLUDEPATHS% (
				set VAR=!INCLUDEPATHS!"-I!INCLUDEPATH%%j!" 
				set INCLUDEPATHS=!VAR!
			)
		)
		
		echo %CXX% %CXXFLAGS% %PFLAGS% !INCLUDEPATHS! -o "%FULLPATH%%BUILD%\%%i_cpp_!CPPFILENAME!.o" "!CPPFILEPATH!"
		%CXX% %CXXFLAGS% %PFLAGS% !INCLUDEPATHS! -o "%FULLPATH%%BUILD%\%%i_cpp_!CPPFILENAME!.o" "!CPPFILEPATH!"
		
		if !ERRORLEVEL! neq 0 (
			goto END
		)
	)
)

echo [0mCompiling %NUMCFILES% C file(s) ...
for /l %%i in (0,1,%NUMCFILES%) do (
	if %%i lss %NUMCFILES% (
		set CFILEPATH=!CFILE%%i!
		for %%a in ("!CFILEPATH!") do set CFILENAME=%%~na
		
		echo %CC% %CFLAGS% -o "%FULLPATH%%BUILD%\%%i_c_!CFILENAME!.o" "!CFILEPATH!"
		%CC% %CFLAGS% -o "%FULLPATH%%BUILD%\%%i_c_!CFILENAME!.o" "!CFILEPATH!"
		
		if !ERRORLEVEL! neq 0 (
			goto END
		)
	)
)

if not "%LDFLAGS%"=="" (
	echo LDFLAGS = %LDFLAGS%
	echo %LDFLAGS%>> "%LDARGSFILE%"
)

echo [0mCollecting library search paths ...
for /d %%i in ("%FULLPATH%%LIB%"\*) do (
	if exist "%%i/lib/windows" (
		echo %%i/lib/windows
		echo "-L%%i/lib/windows">> "%LDARGSFILE%"
	)
)

echo -o = "%FULLPATH%%BUILD%/%NAME%.exe"
echo -o "%FULLPATH%%BUILD%/%NAME%.exe">> "%LDARGSFILE%"

echo [0mCollecting object files ...
set /a NUMOFILES = 0
for /r "%FULLPATH%%BUILD%" %%i in (*.o) do (
	echo %%i
	echo "%%i">> "%LDARGSFILE%"
	set /a NUMOFILES += 1
)

echo LDLIBS = %LDLIBS%
echo %LDLIBS%>> "%LDARGSFILE%"

for /f "tokens=*" %%i in ('type "%LDARGSFILE%"') do (
	set line=%%i
	set linewithbackslashesconvertedtoforwardslashes=!line:\=/!
	echo !linewithbackslashesconvertedtoforwardslashes!>> "%LDARGSFILE2%"
)

if exist "%LDARGSFILE%" del /q "%LDARGSFILE%"

echo [0mLinking %NUMOFILES% object file(s) ...

echo [0m%LD% @"%LDARGSFILE2%"
%LD% @"%LDARGSFILE2%"

if exist "%LDARGSFILE2%" del /q "%LDARGSFILE2%"



:END
set ERRORLEVELBACKUP=%ERRORLEVEL%

set ENDTIME=%time%
set TIMEOPTIONS="tokens=1-4 delims=:.,"
for /f %TIMEOPTIONS% %%a in ("%STARTTIME%") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100&set /a start_ms=100%%d %% 100
for /f %TIMEOPTIONS% %%a in ("%ENDTIME%") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100&set /a end_ms=100%%d %% 100
set /a hours=%end_h%-%start_h%
set /a mins=%end_m%-%start_m%
set /a secs=%end_s%-%start_s%
set /a ms=%end_ms%-%start_ms%
if %ms% lss 0 set /a secs = %secs% - 1 & set /a ms = 100%ms%
if %secs% lss 0 set /a mins = %mins% - 1 & set /a secs = 60%secs%
if %mins% lss 0 set /a hours = %hours% - 1 & set /a mins = 60%mins%
if %hours% lss 0 set /a hours = 24%hours%
if 1%ms% lss 100 set ms=0%ms%

if %ERRORLEVELBACKUP% neq 0 goto BUILD_FAILED
goto BUILD_SUCCEEDED



:BUILD_FAILED
echo [91mBuild Failed. (took %secs% second(s))[0m
if /i "%comspec% /c ``%~0` `" equ "%cmdcmdline:"=`%" pause
exit /b %ERRORLEVEL%



:BUILD_SUCCEEDED
echo [92mBuild Finished. (took %secs% second(s))[0m
if /i "%comspec% /c ``%~0` `" equ "%cmdcmdline:"=`%" pause
exit /b 0