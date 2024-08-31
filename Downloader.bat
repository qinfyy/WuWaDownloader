@echo off
chcp 936
title Wuthering Waves Downloader
cd /d %~dp0
rem 1.0.0
rem 0x2f649342688 https://prod-volcdn-gamestarter.kurogame.net/pcstarter/prod/game/G153/50004_obOHXFrFanqsaIEOmuKroCcbZkQRBC7c/index.json
rem 0x2f649342358 https://prod-alicdn-gamestarter.kurogame.com/pcstarter/prod/game/G153/50004_obOHXFrFanqsaIEOmuKroCcbZkQRBC7c/index.json
rem 0x25319014f28 https://prod-cn-alicdn-gamestarter.kurogame.com/pcstarter/prod/game/G152/10003_Y8xXrXk65DqFHEDgApn3cpK5lfczpFx5/index.json
rem 0x25319044948 https://prod-volcdn-gamestarter.kurogame.com/pcstarter/prod/game/G152/10003_Y8xXrXk65DqFHEDgApn3cpK5lfczpFx5/index.json

REM 1.2.0
REM 0x24a65203138 (244): https://prod-cn-alicdn-gamestarter.kurogame.com/pcstarter/prod/game/G152/10003_Y8xXrXk65DqFHEDgApn3cpK5lfczpFx5/index.json
REM 0x24a651f50e8 (238): https://prod-volcdn-gamestarter.kurogame.com/pcstarter/prod/game/G152/10003_Y8xXrXk65DqFHEDgApn3cpK5lfczpFx5/index.json

set IndexURL=https://prod-cn-alicdn-gamestarter.kurogame.com/pcstarter/prod/game/G152/10003_Y8xXrXk65DqFHEDgApn3cpK5lfczpFx5/index.json
set OUTPATH=Wuthering Waves Game
set selectCDN=1
call :DelCache
setlocal ENABLEDELAYEDEXPANSION

REM ��ȡAPI��Ϣ
echo ���� index.json
set GET_INDEX_ERROR=0
:GET_INDEX
set /a GET_INDEX_ERROR+=1
if !GET_INDEX_ERROR! GTR 5 (
	echo ���� index.json �ļ�ʧ��
    pause
	exit
)

DEL /F /Q index.json >nul 2>nul
(.\aria2c.exe -o "index.json" --connect-timeout=3 --file-allocation=prealloc --check-certificate=false --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0" "%IndexURL%")||(timeout /T 3 /NOBREAK >nul& goto :GET_INDEX)

call :GzipDecompression index.json
REM ��ȡCDN��Ϣ
for /f "delims=*" %%a in ('jq.exe -r ".default.cdnList[%selectCDN%].url" "index.json"') do (set CDN=%%a)
echo CDN��%CDN%

REM ��ȡ��ԴJson·����Ϣ
for /f "delims=*" %%a in ('jq.exe -r ".default.resources" "index.json"') do (
	set resources=%%a
)
echo resources��%resources%

echo ���� resources.json �ļ�...
:GET_RESOURCES
set /a GET_RESOURCES_ERROR+=1
if !GET_RESOURCES_ERROR! GTR 5 (
	echo ���� resources.json �ļ�ʧ��
	pause
	exit
)

DEL /F /Q resources.json >nul 2>nul
(.\aria2c.exe -o "resources.json" --connect-timeout=3 --file-allocation=prealloc --check-certificate=false --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0" "%CDN%%resources%")||(timeout /T 3 /NOBREAK >nul& goto :GET_RESOURCES)

call :GzipDecompression resources.json
REM ��ȡ��Դ·����Ϣ
for /f "delims=*" %%a in ('jq.exe -r ".default.resourcesBasePath" "index.json"') do (
    set resourcesBase=%%a
)
echo resourcesBasePath��%resourcesBase%

REM ��ȡ�ļ�����
for /f "delims=*" %%a in ('jq.exe -r ".resource | length" "resources.json"') do (
    set amount=%%a
)
echo �ļ�������%amount%
echo ��ʼ�����ļ�
pause

REM ��ȡ�ļ��б�
rmdir /S /Q "%OUTPATH%"
DEL /F /Q DownloadList.txt >nul 2>nul
set /a index=amount-1
for /l %%i in (0,1,%index%) do (
    echo ������%%i
    set /a jsonindex 
    for /F "tokens=* delims=*" %%b in ('jq.exe -r ".resource[%%i].dest" "resources.json"') do (
        set curFile=%%b
        echo �ļ���!curFile!
        echo %CDN%%resourcesBase%!curFile! >> DownloadList.txt
        echo    out=%OUTPATH%!curFile! >> DownloadList.txt
    )
)

.\aria2c --input-file=DownloadList.txt --continue=true --max-concurrent-downloads=20 --split=32 --file-allocation=prealloc --remote-time=true --check-certificate=false --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
echo �ļ��������
echo ��ʼУ���ļ�
pause

REM �ļ�У�鲿��
:MD5DEBUG
DEL /F /Q �����ļ�.txt >nul 2>nul
set ErrorCount=0
for /f "tokens=*" %%i in ('jq.exe -r ".resource[] | .dest + \" \" + (.size | tostring) + \" \" + .md5" resources.json') do (
    set "line=%%i"

    REM ��ȡĿ��·�����ļ���С�� MD5 ֵ
    for /f "tokens=1,2,3" %%a in ("!line!") do (
        set dest=%OUTPATH%%%a
        set expected_size=%%b
        set expected_md5=%%c

        REM �� JSON �е� dest ת��Ϊ Windows ��ʽ·��
        set "dest=!dest:/=\!"

        if exist "!dest!" (
            echo [OK] �ļ�����: !dest!

            for /f "delims=" %%d in ('powershell.exe -command "(Get-Item '!dest!').length"') do (
                set "actual_size=%%d"
            )

            if "!actual_size!"=="!expected_size!" (
                echo [OK] �ļ���С��ȷ: !dest!
            ) else (
                echo [ERROR] �ļ���С����ȷ: !dest! Ԥ��: !expected_size!, ʵ��: !actual_size!
				set /a ErrorCount=%ErrorCount%+1
            )

            REM �����ļ��� MD5
            for /f "delims=" %%e in ('powershell.exe -command "(Get-FileHash '!dest!' -Algorithm MD5).Hash"') do (
                set "actual_md5=%%e"
            )

            set "actual_md5=!actual_md5: =!"
            if /i "!actual_md5!"=="!expected_md5!" (
                echo [OK] MD5 ��ȷ: !dest!
            ) else (
                echo [ERROR] MD5 ����ȷ: !dest! Ԥ��: !expected_md5!, ʵ��: !actual_md5!
				set /a ErrorCount=%ErrorCount%+1
            )
        ) else (
            echo [ERROR] �ļ�������: !dest!
			set /a ErrorCount=%ErrorCount%+1
        )
    )
)
echo �ļ�У�����
if %ErrorCount%==0 (
    echo û�д���
    call :DelCache
) else (
    echo �� %ErrorCount% ���ļ�У��δͨ��
)
endlocal
pause
exit

:DelCache
DEL /F /Q index.json >nul 2>nul
DEL /F /Q resources.json >nul 2>nul
DEL /F /Q DownLoadList.txt >nul 2>nul
goto :eof

:GzipDecompression
set file=%1
REM ����ļ��Ƿ�ΪGzip (0x1F 0x8B)
for /f %%i in ('powershell.exe -command "if ((Get-Content -Path '%file%' -Raw -Encoding Byte)[0] -eq 0x1F -and (Get-Content -Path '%file%' -Raw -Encoding Byte)[1] -eq 0x8B) { 'true' } else { 'false' }"') do (
    set "fileType=%%i"
)

REM �����Gzip�����ѹ
if "%fileType%"=="true" (
    powershell.exe -command "Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.CompressionMode]::Decompress; [IO.Compression.GzipStream]::new([IO.File]::OpenRead('%file%'), [IO.Compression.CompressionMode]::Decompress).CopyTo([IO.File]::Create('%file%_decompressed.json'));"
    DEL /F /Q %file% >nul 2>nul
    ren %file%_decompressed.json %file%
)
goto :eof
