:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: 特别说明：因exiftool标签限制，请勿随意转换本脚本大小写。
:: 会生成的临时文件：待处理目录下有$、脚本目录下有%listfile%和%countfile%。
::		Script\by\aceckt\lonyii$foxmail.com\lastbuild\20151122
::		更新：优化生成列表速度，由原来1分07秒（2700+）文件提升到现在的2秒左右
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@echo off
mode con:cols=80 lines=5&color f1

set auther=aceckt
set version=v15.11.22
set version.build.number=22
set contact=lonyii$foxmail.com
title=name by exif %version% - %auther%

set exiftool=exiftool.exe
:: 本腳本需要第三方文件:exiftool.exe，與本腳本一起放在待整理的媒體文件夾下

:: 媒体文件比對等級，數值0~5，越高執行效率越低
:: 0=爲只比對文件大小
:: 1~5=按下列EXIF數據比對，只有全部相同時才判定爲重複
set compare_level_media=0
set "advance_compare_Parameter=$Flash $ImageSize $Software $GPSPosition $BrightnessValue"

:: 其它文件类型比对等级（1~3）：文件大小>修改时间>文件名称
set compare_level_other=2

:: 设置命名格式%%Y-%%R-%%d_%%H%%M%%S，注意d为小写，暂不支持空格及特殊符号，比如.<>/?|\
set date_format=%%Y-%%R-%%d_%%H%%M%%S

:: 搜索子目录：1（是）或0（否）
set bool_dir_current=1
if %bool_dir_current%==1 (set "dir_parameter=/a-d /b /od /ta /s"&set "findstr_parameter=\\") else (set "dir_parameter=/a-d /b /od /ta"&set "findstr_parameter=^^")

:: 已确认支持的格式（图片和视频）
set Supporting_format_photo=.jpg$ .png$ .nef$ .psd$
set Supporting_format_movie=.mov$ .mp4$ .avi$
set Supporting_format_other=

:: 脚本初始化
set "deleted_files_recover_bat=%~dp0恢复脚本\%date:/=-%.%random%.bat"
for %%i in (%deleted_files_recover_bat%) do if not exist "%%~dpi" md "%%~dpi">nul 2>nul
set "listfile=%~dp0@list.log"
set "countfile=%~dp0@count.log"
del /f /q "%countfile%">nul 2>nul
del /f /q "%listfile%">nul 2>nul
set rename_count=0
set Duplicate_count=0

:menu_start
cls&echo.
set start_path=
if "%~1"=="" (
	set /p "start_path=*请将要整理的文件夹拖入本窗："
) else (
	set "start_path=%~1"
	shift /1
)
if not defined start_path exit /b
set start_path=%start_path:"=%
if "%start_path:~4,1%"=="" goto :menu_start
if not "%start_path%"=="" if exist "%start_path%" goto :mod_start
goto :menu_start

:mod_start
call :mod_rename_by_datetimeoriginal "%start_path%"
if exist "%~1" goto :menu_start

:: 结束
set total_renamed=0
set total_deleted=0
for /f "tokens=1,2 delims=," %%i in (%countfile%) do set /a total_renamed+=%%i,total_deleted+=%%j
del /f /q "%countfile%">nul 2>nul

title=Name By Exif %version% - %auther%
cls&echo.&echo.		整理完毕，重命名文件 %total_renamed% 项，删除重複文件 %total_deleted% 项！

ping -n 6 127.1 >nul 2>nul
exit /b

:mod_rename_by_datetimeoriginal
set "s1=%~1"
if exist "%~1\" (
	if "%s1:~4,1%"=="" goto :eof
	cd /d "%~1"
	set isFile=0
	:: 如果%1是文件，则只dir该文件，否则dir所有文件
	set "dir_files=*.*"
) else (
	cd /d "%~dp1"
	set only_media_files=2
	set isFile=1
	:: 如果%1是文件，则只dir该文件，否则dir所有文件
	set "dir_files=%~1"&set "tmp_name=%~1"
)

setlocal enabledelayedexpansion
set "date_format_for_findstr=!date_format:%%Y=....!"
set "date_format_for_findstr=!date_format_for_findstr:%%R=..!"
set "date_format_for_findstr=!date_format_for_findstr:%%d=..!"
set "date_format_for_findstr=!date_format_for_findstr:%%H=..!"
set "date_format_for_findstr=!date_format_for_findstr:%%M=..!"
set "date_format_for_findstr=!date_format_for_findstr:%%S=..!"
set "date_format_for_exiftool=!date_format:%%R=%%m!"

:: 生成待處理列表
cls&echo.&echo.	正在生成处理清单,请稍候

:: 生成文件列表并区分文件类型
set bool_other_files_insided=0
dir %dir_parameter% "%dir_files%">"%listfile%"
if %errorlevel%==1 del /f /q "%listfile%">nul 2>nul&goto :eof

:: 统计比对文件总数
set total_comparefiles=0
for /f "delims=" %%i in (%listfile%) do set /a total_comparefiles+=1

:: 检查有无其它文件
for /f "delims=" %%i in ('findstr /i /v "%Supporting_format_photo% %Supporting_format_movie%" "%listfile%"') do (if %%~zi gtr 0 (set "bool_other_files_insided=1"&goto :jumpfor5324523))
:jumpfor5324523
:: 筛选出未格式化文件名的文件
findstr /v /i "%findstr_parameter%!date_format_for_findstr!_[1-9]*\." "%listfile%">$
(for /f "delims=" %%i in ('findstr /i "%Supporting_format_photo%" $') do echo %%i^|FLAG_PHOTO)>"%listfile%"
(for /f "delims=" %%i in ('findstr /i "%Supporting_format_movie%" $') do echo %%i^|FLAG_VIDEO)>>"%listfile%"
del $

:: 若是单文件，则默认处理任意文件，2为任意文件
set only_media_files=2
:: 是目录、且有其它文件包含在内，则选择是否仅处理媒体文件
if %isFile%==0 if "%bool_other_files_insided%"=="1" (
		set "only_media_files=1"
		cls&echo.	请选择：1、只处理媒体文件[默认]&echo.	        2、处理所有文件
		set /p "only_media_files=.................."
		if not defined only_media_files (set "only_media_files=1")
		if not "!only_media_files!"=="2" (set "only_media_files=1")
)

cls&echo.&echo.	正在获取文件总数
set scan_count=0
for /f "tokens=1 delims=: " %%i in ('findstr /n ".*" "%listfile%"') do set total_count=%%i

cls&echo.&echo.	读取文件并重命名
(for /f "tokens=1,2 delims=|" %%i in (%listfile%) do (
	set /a scan_count+=1
	set "rs=%%~nxsi"
	title 讀取exif信息並重命名「進度:!scan_count!/%total_count%」 - %auther%
	cls&echo.	"***%~nx1***"&echo.		current:	"%%~nxi"

	set Exiftool_Parameter=$datetimeoriginal
	if "%%j"=="FLAG_VIDEO" set Exiftool_Parameter=$CreateDate
	set exif_tool_error=1
	for /f "tokens=1-7 delims=/" %%a in ('%exiftool% -d "!date_format_for_exiftool!/%%Y/%%m/%%d/%%H/%%M/%%S" -p !Exiftool_Parameter! "%%~i"') do (
		set dt=%%a
		if "!dt:~0,4!"=="0000" (
			set "Exiftool_Parameter=$FileCreationDateTime"
			for /f "tokens=4 delims=: " %%m in ('%exiftool% -d "!date_format_for_exiftool!" "%%~i"^|findstr /i /c:"File Modification Date/Time"') do set "dt=%%m"
		)
		
		:: 计算时差UST+8:00
		if !Exiftool_Parameter!==$CreateDate (
			call :DateCalc "%%b-%%c-%%d %%e:%%f:%%g" 28800
			set dt=!TimeEnd!
		)
		call :Rename_File "%%~i" tmp_name
		set exif_tool_error=0
	)

	if !exif_tool_error!==1 (
		for /f "tokens=4 delims=: " %%m in ('%exiftool% -d "!date_format_for_exiftool!" "%%~i"^|findstr /i /c:"File Modification Date/Time"') do set "dt=%%m"
		call :Rename_File "%%~i" tmp_name
	)
))2>nul
cls
del /q /f "%listfile%" >nul 2>nul

:mod_delete_duplicate_file
title 查找並刪除重複的媒體「比對級別:%compare_level_media%.%compare_level_other%」- %auther%

:: 过滤，只对已重命名的文件进行重复比对
set "date_format_for_dir=!date_format:%%Y=????!"
set "date_format_for_dir=!date_format_for_dir:%%R=??!"
set "date_format_for_dir=!date_format_for_dir:%%d=??!"
set "date_format_for_dir=!date_format_for_dir:%%H=??!"
set "date_format_for_dir=!date_format_for_dir:%%M=??!"
set "date_format_for_dir=!date_format_for_dir:%%S=??!"
call :strlen !date_format_for_dir! len_date_format_for_dir

:: 如果%1是文件，则只对该文件进行去重操作
:: %1是目录且仅处理媒体文件，则只过滤格式化了的文件，否则过滤全部文件
if %isFile%==1 (for %%i in ("%tmp_name%") do (set "dir_files=%tmp_name%"&set "filter=*%%~xi")) else (
	if %only_media_files%==1 (
		set "dir_files=!date_format_for_dir!_*.*"
	) else (set "dir_files=")
)
:: 开始比对
set current_comparefile=0
for /f "delims=" %%i in ('dir %dir_parameter% "%dir_files%"') do (
	set /a current_comparefile+=1
	title 重复文件删除「阈值:%compare_level_media%.%compare_level_other% 重複:!Duplicate_count! 进度:!current_comparefile!/%total_comparefiles%」 - %auther%
	if exist "%%i" (
		:: 判断文件类型:MEDIA or OTHER
		set FLAG_FILETYPE=FLAG_MEDIA
		if %only_media_files%==2 (echo %Supporting_format_photo% %Supporting_format_movie%|findstr /i "%%~xi">nul 2>nul||set "FLAG_FILETYPE=FLAG_OTHER")

		(echo.&echo { "%%~i" })>>"%listfile%"
		if "!FLAG_FILETYPE!"=="FLAG_MEDIA" (
			:: 媒体文件比对
			set "fn_main=%%~nxi"
			set "fn_main=!fn_main:~0,%len_date_format_for_dir%!"
			cls&echo.	"***%%~nxi***"&echo.		current:	!fn_main!*

			if %isFile%==0 (set "filter=!fn_main!_*.*")
			for /f "delims=" %%a in ('dir %dir_parameter% "!filter!"') do (
				if not "%%~i"=="%%~a" (
					if %%~zi equ %%~za (
						if %compare_level_media%==0 (
							call :del_duplicate_file "%%~i" "%%a" "%deleted_files_recover_bat%" Duplicate_count 
						) else (
							call :Calculate_similarity_marks "%%~i" "%%~a"
							if !similarity_marks!==%compare_level_media% (call :del_duplicate_file "%%~i" "%%a" "%deleted_files_recover_bat%" Duplicate_count)
						)
					)
				)
			)
		) else if %only_media_files%==2 (
			:: 其它类型文件比对
			for /f "delims=" %%a in ('dir %dir_parameter% "*%%~xi"') do (
				cls&echo.	"***%%~nxi***"&echo.		current:	%%~na
				if not "%%~i"=="%%~a" (
					:: 文件大小>修改日期>文件名称
					set similarity_marks=0
					if %%~zi equ %%~za set /a similarity_marks+=1
					if %compare_level_other% geq 2 if "%%~ti"=="%%~ta" set /a similarity_marks+=1
					if %compare_level_other% geq 3 if "%%~nxi"=="%%~nxa" set /a similarity_marks+=1
					if !similarity_marks! geq %compare_level_other% (call :del_duplicate_file "%%~i" "%%a" "%deleted_files_recover_bat%" Duplicate_count)
				)
			)
		)
	)
)
cls&echo !rename_count!,!Duplicate_count!>>"%countfile%"

(if exist "%deleted_files_recover_bat%" echo echo.^&echo 成功恢复%%recover_count%%个文件。^&pause^>nul&echo rem 脚本生成时间：%date% %time%&echo rem Script:name by exif %version%.%version.build.number% - %auther%)>>"%deleted_files_recover_bat%"

(echo.&echo 删除重複文件:!Duplicate_count!项&echo.&echo 恢复被删除文件可执行批处理:&echo %deleted_files_recover_bat%)>>"%listfile%"

if !Duplicate_count! gtr 0 echo.&echo.	查看比对记录。&start /wait notepad "%listfile%"
del /f /q "%listfile%">nul 2>nul

endlocal
goto :eof

:Calculate_similarity_marks
set /a similarity_marks=0
for /F "tokens=1-%compare_level_media% delims= " %%a in ('echo %advance_compare_Parameter%') do (
	(for /f "delims=" %%i in ('%exiftool% -p %%a "%~1"') do set Parameter_1=%%i) 2>nul
	(for /f "delims=" %%i in ('%exiftool% -p %%a "%~2"') do set Parameter_2=%%i) 2>nul

	if "!Parameter_1!"=="!Parameter_2!" set /a similarity_marks+=1
	if %compare_level_media%==1 goto :eof
	
	(for /f "delims=" %%i in ('%exiftool% -p %%b "%~1"') do set Parameter_1=%%i) 2>nul
	(for /f "delims=" %%i in ('%exiftool% -p %%b "%~2"') do set Parameter_2=%%i) 2>nul
	if "!Parameter_1!"=="!Parameter_2!" set /a similarity_marks+=1
	if %compare_level_media%==2 goto :eof
	
	(for /f "delims=" %%i in ('%exiftool% -p %%c "%~1"') do set Parameter_1=%%i) 2>nul
	(for /f "delims=" %%i in ('%exiftool% -p %%c "%~2"') do set Parameter_2=%%i) 2>nul
	if "!Parameter_1!"=="!Parameter_2!" set /a similarity_marks+=1
	if %compare_level_media%==3 goto :eof
	
	(for /f "delims=" %%i in ('%exiftool% -p %%d "%~1"') do set Parameter_1=%%i) 2>nul
	(for /f "delims=" %%i in ('%exiftool% -p %%d "%~2"') do set Parameter_2=%%i) 2>nul
	if "!Parameter_1!"=="!Parameter_2!" set /a similarity_marks+=1
	if %compare_level_media%==4 goto :eof
	
	(for /f "delims=" %%i in ('%exiftool% -p %%e "%~1"') do set Parameter_1=%%i) 2>nul
	(for /f "delims=" %%i in ('%exiftool% -p %%e "%~2"') do set Parameter_2=%%i) 2>nul
	if "!Parameter_1!"=="!Parameter_2!" set /a similarity_marks+=1
	goto :eof
)
goto :eof

:Rename_File recourcefile tmp_name
	rem 检查文件是否存在
	call :Check_duplicate_file_name "%~dp1!dt!_" "%~x1"
	set %2=%~dp1!dt!_!n!%~x1
	ren "%~s1" !dt!_!n!%~x1
	set /a rename_count+=1
goto :eof

:Check_duplicate_file_name
	set /a n=1
	:j1
	if exist "%~1!n!%~2" set /a n+=1&goto j1
goto :eof

:DateCalc %TimeBegin% %SecondInter%
	rem 出处http://www.bathome.net/thread-14413-1-1.html
	set TimeEnd=
	set TimeBegin=%~1
	set SecondInter=%~2
	call :DateToSecs %TimeBegin:~0,4% %TimeBegin:~5,2% %TimeBegin:~8,2% %TimeBegin:~11,2% %TimeBegin:~14,2% %TimeBegin:~17,2% SecondsBegin
	set /a SecondsEnd=SecondsBegin+SecondInter
	call :SecsToDate %SecondsEnd% YearEnd MonthEnd DayEnd HourEnd MinuteEnd SecondEnd
	set "TimeEnd=!date_format:%%Y=%YearEnd%!"
	set "TimeEnd=!TimeEnd:%%R=%MonthEnd%!"
	set "TimeEnd=!TimeEnd:%%d=%DayEnd%!"
	set "TimeEnd=!TimeEnd:%%H=%HourEnd%!"
	set "TimeEnd=!TimeEnd:%%M=%MinuteEnd%!"
	set "TimeEnd=!TimeEnd:%%S=%SecondEnd%!"
goto :eof

:DateToSecs %yy% %mm% %dd% %hh% %nn% %ss% secs
	set yy=%1&set mm=%2&set dd=%3&set hh=%4&set nn=%5&set ss=%6
	if 1%yy% LSS 200 if 1%yy% LSS 170 (set yy=20%yy%) else (set yy=19%yy%)
	set /a dd=100%dd%%%100,mm=100%mm%%%100
	set /a z=14-mm,z/=12,y=yy+4800-z,m=mm+12*z-3,j=153*m+2
	set /a j=j/5+dd+y*365+y/4-y/100+y/400-2472633
	if 1%hh% LSS 20 set hh=0%hh%
	if {%nn:~2,1%} EQU {p} if "%hh%" NEQ "12" set hh=1%hh%&set/a hh-=88
	if {%nn:~2,1%} EQU {a} if "%hh%" EQU "12" set hh=00
	if {%nn:~2,1%} GEQ {a} set nn=%nn:~0,2%
	set /a hh=100%hh%%%100,nn=100%nn%%%100,ss=100%ss%%%100
	set /a j=j*86400+hh*3600+nn*60+ss
	set %7=%j%
goto :eof

:SecsToDate %secs% yy mm dd hh nn ss
	set /a i=%1,ss=i%%60,i/=60,nn=i%%60,i/=60,hh=i%%24,dd=i/24,i/=24
	set /a a=i+2472632,b=4*a+3,b/=146097,c=-b*146097,c/=4,c+=a
	set /a d=4*c+3,d/=1461,e=-1461*d,e/=4,e+=c,m=5*e+2,m/=153,dd=153*m+2,dd/=5
	set /a dd=-dd+e+1,mm=-m/10,mm*=12,mm+=m+3,yy=b*100+d-4800+m/10
	(if %mm% LSS 10 set mm=0%mm%)&(if %dd% LSS 10 set dd=0%dd%)
	(if %hh% LSS 10 set hh=0%hh%)&(if %nn% LSS 10 set nn=0%nn%)
	if %ss% LSS 10 set ss=0%ss%
	set %7=%ss%&set %6=%nn%&set %5=%hh%
	set %4=%dd%&set %3=%mm%&set %2=%yy%
goto :eof

:: 获取字符串长度
:strlen
	set strs=%1
	set n=0
	:yyq
	set u=!strs:~%n%,1!
	if not "!u!"=="" (
		set/a n+=1
		goto yyq
	) else set %2=!n!
goto :eof

:del_duplicate_file 1.源文件 2.重复文件 3.恢复脚本 4.计数器
	if !%4!==0 echo @echo off^&color f1^&title 已删除文件恢复脚本 - by.%auther%>"%~3"
	del /q /f "%~2">nul 2>nul
	:: 生成待删除文件列表
	set /a %4+=1
	echo.	DEL.!%4!-^>"%~2">>"%listfile%"
	:: 生成恢复脚本
	(echo echo 正在恢复：^&echo.	"%~2"^&echo.^&copy "%~1" "%~2"^>nul 2^>nul^&^&set /a recover_count+=1)>>"%~3"
	:: 计数
goto :eof