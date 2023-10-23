    ## Call the Exit-Script function to perform final cleanup operations

    ##*Remove an install marker reg key for custom detections: Remove-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Applications\$installName" -ContinueOnError:$True

                      ##*Make an install marker reg key for custom detections: Set-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Applications\$installName" -Name "InstallStatus" -Value '1' -Type String -ContinueOnError:$True

                          Switch($DeploymentType){

    "Install"{

                          Set-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Applications\$installName" -Name "InstallStatus" -Value '1' -Type String -ContinueOnError:$True

                          Exit-Script -ExitCode $mainExitCode

        }

    "Uninstall"{

        Remove-RegistryKey -Key "HKLM:\SOFTWARE\Cygate\Applications\$installName" -ContinueOnError:$True

        Exit-Script -ExitCode $mainExitCode

                                            }

                      }

}

Catch {

    [Int32]$mainExitCode = 60001

    [String]$mainErrorMessage = "$(Resolve-Error)"

    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName

    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'

    Exit-Script -ExitCode $mainExitCode

}

 
