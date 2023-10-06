#install-packageprovider -name nuget -minimumversion 2.8.5.201 -force -Verbose

#Install-Module PowerBGInfo -Force -Verbose -SkipPublisherCheck


New-BGInfo -MonitorIndex 0 {
    # Lets add computer name, but lets use builtin values for that
    New-BGInfoValue -BuiltinValue HostName -Name "Systemname:" -Color white -FontSize 80 -FontFamilyName 'Arial'
    # Lets add user name, but lets use builtin values for that
    New-BGInfoValue -BuiltinValue FullUserName -Name "Loggedonuser:" -Color White -FontSize 40 -FontFamilyName 'Arial'
    New-BGInfoValue -Name "Last reboot:" -Value "TTTT" -Color White -FontSize 40 -FontFamilyName 'Arial'
    


} -FilePath $PSScriptRoot\files\Background.jpg -ConfigurationDirectory $PSScriptRoot\Output -PositionX 300 -PositionY 600 -WallpaperFit Fill