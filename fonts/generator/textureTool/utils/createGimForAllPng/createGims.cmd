@ECHO off

SET "startDir=%cd%"

IF NOT EXIST template.gim (
    ECHO Error: missing 'template.gim'
    PAUSE
    EXIT
)

SET /p workingDir="Enter directory:"

CD /d %workingDir%

ECHO creating gim for all png files...

FOR %%i IN (*.png) DO (
    IF NOT EXIST %%~ni.gim (
        ECHO Found png '%%i' without gim, copying template
        COPY "%startDir%\template.gim" "%%~ni.gim"
    ) ELSE (
        ECHO .gim for '%%i' already exists, skipping
    )
)

CD /d %startDir%

PAUSE