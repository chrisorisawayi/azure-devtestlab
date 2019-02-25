function DownloadToFilePath ($downloadUrl, $targetFile)
{
    Write-Output ("Downloading installation files from URL: $downloadUrl to $targetFile")
    $targetFolder = Split-Path $targetFile

    if((Test-Path -path $targetFile))
    {
        Write-Output "Deleting old target file $targetFile"
        Remove-Item $targetFile -Force | Out-Null
    }

    if(-not (Test-Path -path $targetFolder))
    {
        Write-Output "Creating folder $targetFolder"
        New-Item -ItemType Directory -Force -Path $targetFolder | Out-Null
    }

    #Download the file
    $downloadAttempts = 0
    do
    {
        $downloadAttempts++

        try
        {
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($downloadUrl,$targetFile)
            break
        }
        catch
        {
            Write-Output "Caught exception during download..."
            if ($_.Exception.InnerException){
                Write-Output "InnerException: $($_.InnerException.Message)"
            }
            else {
                Write-Output "Exception: $($_.Exception.Message)"
            }
        }

    } while ($downloadAttempts -lt 5)

    if($downloadAttempts -eq 5)
    {
        Write-Error "Download of $downloadUrl failed repeatedly. Giving up."
    }
}

Write-Output "Installing SQL Server 2017 Developer"
$logFolder = Join-path -path $env:ProgramData -childPath "DTLArt_SQLDev"

$argumentList = " /Q /IAcceptSQLServerLicenseTerms=True /ACTION=Install /SUPPRESSPRIVACYSTATEMENTNOTICE=True /ENU=True /FEATURES=SQLENGINE,FULLTEXT,CONN,IS,BC,SDK /INSTANCENAME=LRSDEV /INSTALLSHAREDDIR=`"C:\Program Files\Microsoft SQL Server`" /INSTANCEID=LRSDEV /INSTANCEDIR=`"C:\Program Files\Microsoft SQL Server`" /AGTSVCSTARTUPTYPE=Automatic /ISSVCSTARTUPTYPE=Automatic /SQLSVCSTARTUPTYPE=Automatic /SQLCOLLATION=SQL_Latin1_General_CP1_CI_AS /SQLSYSADMINACCOUNTS=BUILTIN\Administrators /SQLTEMPDBFILECOUNT=4 /SQLTEMPDBFILESIZE=1024 /SQLTEMPDBFILEGROWTH=64 /SQLTEMPDBLOGFILESIZE=8 /SQLTEMPDBLOGFILEGROWTH=64 /BROWSERSVCSTARTUPTYPE=Disabled"
$downloadUrl = 'https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-x64-ENU-Dev.iso'

$localFile = Join-Path $logFolder 'SQLServer2017-x64-ENU-Dev.iso'
DownloadToFilePath $downloadUrl $localFile

if(![String]::IsNullOrWhiteSpace($installerArgs))
{
    Write-Output "InstallerArgs value: $installerArgs"
    $argumentList = "$installerArgs $argumentList"
}

#Mount installation ISO and change to mount path.
$mountVolume = Mount-DiskImage -ImagePath $localFile -PassThru
$driveLetter = ($mountVolume | Get-Volume).DriveLetter
$drivePath = $driveLetter + ":"
push-location -path "$drivePath"
$localFile = $drivePath + "\Setup.exe"

Write-Output "Running install with the following arguments: $argumentList"
$retCode = Start-Process -FilePath $localFile -ArgumentList $argumentList -Wait -PassThru

if ($retCode.ExitCode -ne 0 -and $retCode.ExitCode -ne 3010)
{
    $targetLogs = 'c:\VS2017Logs'
    New-Item -ItemType Directory -Force -Path $targetLogs | Out-Null
    Write-Output ('Temp location is ' + $env:TEMP)
    Copy-Item -path $env:TEMP\dd* -Destination $targetLogs
    Write-Error "Product installation of $localFile failed with exit code: $($retCode.ExitCode.ToString())"    
}
else
{
    #Dismount the installation ISO
    pop-location
    Dismount-DiskImage -ImagePath $localFile
    Write-Output "SQL Server 2017 Developer install succeeded. Rebooting..."
}
