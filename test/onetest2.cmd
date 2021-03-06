@echo off

@if "%TIDY%." == "." goto Err1
@if NOT EXIST %TIDY% goto Err2
@if "%TIDYOUT%." == "." goto Err3
@if NOT EXIST %TIDYOUT%\nul goto Err4
@if NOT EXIST input\nul goto Err5
@if "%TMPTEST%x" == "x" goto Err10

@if "%1x" == "x" goto Err8
@if "%2x" == "x" goto Err9

set TESTNO=%1
set EXPECTED=%2

set INFILES=input\in_%1.*ml
set CFGFILE=input\cfg_%1.txt

set TIDYFILE=%TIDYOUT%\out_%1.html
set MSGFILE=%TIDYOUT%\msg_%1.txt

set HTML_TIDY=

@set TMPOPTS=%TMPOPTS% --tidy-mark no

REM If no test specific config file, use default.
if NOT exist %CFGFILE% set CFGFILE=input\cfg_default.txt

REM Get specific input file name
@set INFILE=
for %%F in ( %INFILES% ) do set INFILE=%%F 
@if "%INFILE%." == "." goto Err6
@if NOT EXIST %INFILE% goto Err7

REM Remove any pre-exising test outputs
if exist %MSGFILE%  del %MSGFILE%
if exist %TIDYFILE% del %TIDYFILE%

@REM Noisy output, or quiet
@REM echo Testing %1 input %INFILE% config %CFGFILE% ...
@echo Doing: '%TIDY% -f %MSGFILE% -config %CFGFILE% %TMPOPTS% -o %TIDYFILE% %INFILE% >> %TMPTEST%

@%TIDY% -f %MSGFILE% -config %CFGFILE% %TMPOPTS% -o %TIDYFILE% %INFILE%
@set STATUS=%ERRORLEVEL%
@echo Testing %1, expect %EXPECTED%, got %STATUS%, msg %MSGFILE%
@echo Testing %1, expect %EXPECTED%, got %STATUS%, msg %MSGFILE% >> %TMPTEST%

@if %STATUS% EQU %EXPECTED% goto done
@set ERRTESTS=%ERRTESTS% %TESTNO%
@echo *** Failed - got %STATUS%, expected %EXPECTED% ***
@type %MSGFILE%
@echo *** Failed - got %STATUS%, expected %EXPECTED% *** >> %TMPTEST%
@type %MSGFILE% >> %TMPTEST%
goto done

:Err1
@echo ==============================================================
@echo ERROR: runtime exe not set in TIDY environment variable ...
@echo ==============================================================
@goto TRYAT

:Err2
@echo ==============================================================
@echo ERROR: runtime exe %TIDY% not found ... check name, location ...
@echo ==============================================================
@goto TRYAT

:Err3
@echo ==============================================================
@echo ERROR: output folder TIDYOUT not set in environment ...
@echo ==============================================================
@goto TRYAT

:Err4
@echo ==============================================================
@echo ERROR: output folder %TIDYOUT% does not exist ...
@echo ==============================================================
@goto TRYAT

:Err5
@echo ==============================================================
@echo ERROR: input folder 'input' does not exist ... check name, location ..
@echo ==============================================================
@goto TRYAT

:TRYAT
@echo Try running alltest1.cmd ..\build\cmake\Release\Tidy5.exe tmp
@echo ==============================================================
@pause
@goto done

:Err6
@echo ==============================================================
@echo ERROR: Failed to find input matching '%INFILES%'!!!
@echo ==============================================================
@pause
@goto done

:Err7
@echo ==============================================================
@echo ERROR: Failed to find input file '%INFILE%'!!!
@echo ==============================================================
@pause
@goto done

:Err8
@echo.
@echo ERROR: No input test number given!
:Err9
@echo ERROR: No expected exit value given!
@echo.
@goto done

:Err10
@echo ERROR: TMPTEST not set in evironment!
@echo.
@goto done


:done
