Set App_Path=%~dp0

"%App_Path%Deploy-Application.EXE" -DeploymentType uninstall -Deploymode NonInteractive
"%App_Path%Deploy-Application.EXE" -DeploymentType install -Deploymode NonInteractive
