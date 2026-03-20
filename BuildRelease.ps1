Import-Module "$PSScriptRoot\tm-plugin-builder\powershell\TmPluginBuilder.psm1" -Force

Invoke-TmPluginBuilderRelease -ProjectDir $PSScriptRoot
