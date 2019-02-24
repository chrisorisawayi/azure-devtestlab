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

Write-Output "Installing Visual Studio $version $sku"
$logFolder = Join-path -path $env:ProgramData -childPath "DTLArt_VS"

$argumentList = "--add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.Azure --add Microsoft.VisualStudio.Workload.VisualStudioExtension --add microsoft.net.componentgroup.targetingpacks.common --add microsoft.visualstudio.component.entityframework --add microsoft.net.componentgroup.4.7.developertools --add microsoft.net.componentgroup.4.7.1.developertools --add microsoft.net.componentgroup.4.7.2.developertools --add microsoft.visualstudio.component.wcf.tooling --add microsoft.visualstudio.component.appinsights.tools --add microsoft.visualstudio.component.aspnet45 --add microsoft.visualstudio.component.webdeploy --add microsoft.visualstudio.componentgroup.iisdevelopment --add microsoft.visualstudio.web.mvc4.componentgroup --add microsoft.netcore.componentgroup.web --add microsoft.netcore.1x.componentgroup.web --add microsoft.component.azure.datalake.tools --add microsoft.visualstudio.componentgroup.azure.resourcemanager.tools --add microsoft.visualstudio.componentgroup.azure.cloudservices --add microsoft.visualstudio.component.azure.mobileappssdk --add microsoft.visualstudio.component.azure.servicefabric.tools --add microsoft.component.codeanalysis.sdk --quiet --norestart --wait"
$downloadUrl = 'https://download.visualstudio.microsoft.com/download/pr/100196700/14dd70405e8244481b35017b9a562edd/vs_Professional.exe'


$localFile = Join-Path $logFolder 'vsinstaller.exe'
DownloadToFilePath $downloadUrl $localFile

if(![String]::IsNullOrWhiteSpace($installerArgs))
{
    Write-Output "InstallerArgs value: $installerArgs"
    $argumentList = "$installerArgs $argumentList"
}

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
    Write-Output "Visual Studio install succeeded. Rebooting..."
}
