@setlocal
@pushd %~dp0

@set _C=Debug
@set _L=%~dp0..\build\logs
@set _T=

:parse_args
@if /i "%1"=="release" set _C=Release
@if not "%1"=="" set _T=%1
@if not "%1"=="" shift & goto parse_args

@echo Building web %_C%

:: Build and test tools

dotnet build FeedGenerator -c %_C% -nologo
dotnet build XmlDocToMarkdown\XmlDocToMarkdown.csproj -c %_C% -nologo -m -warnaserror -bl:%_L%\buildxmldoc.binlog || exit /b
dotnet test test\XsdToMarkdownTests\XsdToMarkdownTests.csproj -c %_C% -nologo -m -warnaserror -bl:%_L%\build.binlog || exit /b

:: Build bundle update feed

..\build\%_C%\FeedGenerator.exe WixAdditionalTools 4.0 feeds\wix-additional-tools-4-0.template Docusaurus\static\releases\feeds\ "%_T%" || exit /b

:: Build schema and API reference markdown

dotnet build mkdoc\mkdoc.proj -c %_C% -nologo -m -warnaserror -bl:%_L%\mkdoc.binlog || exit /b

:: Publish dynamic web site

dotnet publish Web\Web.csproj -c %_C% --output ..\build\deploy -nologo -m -warnaserror -bl:%_L%\publish.binlog || exit /b

:: Build static web site

call npm --prefix Docusaurus run build -- --out-dir ..\..\build\deploy\wwwroot || exit /b

@popd
@endlocal
