@setlocal
@set TMPEXE=F:\Projects\tidy-html5\build\win64\Release\tidy.exe
@if NOT EXIST %TMPEXE% goto NOEXE
@call dirmin %TMPEXE%
@%TMPEXE% -v

@REM ===========================================
%TMPEXE% %*
@REM ===========================================

@goto END

:NOEXE
@echo Can NOT locate %TMPEXE%
@goto END

:END

 
