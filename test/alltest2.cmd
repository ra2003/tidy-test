@setlocal
@echo off

@if "%1." == "." goto USE
@if "%2." == "." goto USE
@if "%TMPTEST%x" == "x" goto USE

REM check for input file
@if NOT EXIST testcases.txt goto Err0
@if NOT EXIST onetest.cmd goto Err3
@if NOT EXIST input\nul goto Err4

REM set the runtime exe file
set TIDY=%1
@if NOT EXIST %TIDY% goto ERR1

REM set the OUTPUT folder
set TIDYOUT=%2
@if EXIST %TIDYOUT%\nul goto GOTDIR
@echo Folder '%TIDYOUT%' does not exist ... it will be created? ... Ctrl+C to EXIT!
@pause
@md %TIDYOUT%
@if NOT EXIST %TIDYOUT%\nul goto Err2
:GOTDIR

@set TMPCNT=0
@for /F "tokens=1*" %%i in (testcases.txt) do @set /A TMPCNT+=1
@echo =============================== >> %TMPTEST%
@echo Date %DATE% %TIME% >> %TMPTEST%
@echo Tidy EXE %TIDY%, version >> %TMPTEST%
@%TIDY% -v >> %TMPTEST%
@echo Input list of %TMPCNT% tests from 'testcases.txt' file >> %TMPTEST%
@echo Outut will be to the '%TIDYOUT%' folder >> %TMPTEST%
@echo =============================== >> %TMPTEST%

@echo Doing %TMPCNT% tests from 'testcases.txt' file...
@set ERRTESTS=
@for /F "tokens=1*" %%i in (testcases.txt) do @call onetest2.cmd %%i %%j
@echo =============================== >> %TMPTEST%
@if "%ERRTESTS%." == "." goto DONE
@echo ERROR TESTS [%ERRTESTS%] ...
@echo ERROR TESTS [%ERRTESTS%] ... >> %TMPTEST%
:DONE
@echo End %DATE% %TIME% >> %TMPTEST%
@echo =============================== >> %TMPTEST%
@echo.
@echo See %TMPTEST% file for list of tests done...
@echo And compare folders 'diff -ua testbase-new %TIDYOUT% ^> temp.diff'
@echo and check any differences carefully... If acceptable update 'testbase' accordingly...
@echo.
goto END

:ERR0
echo	ERROR: Can not locate 'testcases.txt' ... check name, and location ...
goto END
:ERR1
echo	ERROR: Can not locate %TIDY% ... check name, and location ...
goto END
:ERR2
echo	ERROR: Can not create %TIDYOUT% folder ... check name, and location ...
goto END
:ERR3
echo	ERROR: Can not locate 'onetest.cmd' ... check name, and location ...
goto END
:ERR4
echo	ERROR: Can not locate 'input' folder ... check name, and location ...
goto END

:USE
@echo	Usage of ALLTEST1.CMD .........................................
@echo   Env TMPTEST must be set to a log file name.
@echo	AllTest1 tidy.exe Out_Folder
@echo	tidy.exe - This is the Tidy.exe you want to use for the test.
@echo	Out_Folder  - This is the FOLDER where you want the results put.
@echo	This folder will be created if it does not already exist.
@echo	==================================
@echo	ALLTEST1.CMD will run a battery of test files in the input folder
@echo	Each test name, has an expected result, given in testcases.txt
@echo	There will be a warning if any test file fails to give this result.
@echo	==================================
@echo	But the main purpose is to compare the 'results' of two version of
@echo	any two Tidy runtime exe's. Thus after you have two sets of results,
@echo	in separate folders, the idea is to compare these two folders.
@echo	Any directory compare utility will do, or you can download, and use
@echo	a WIN32 port of GNU diff.exe from http://unxutils.sourceforge.net/
@echo	................................................................
@goto END

:END
