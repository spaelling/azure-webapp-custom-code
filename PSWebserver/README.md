# PSWebserver

Describes the PSWebserver code for an Azure Functions App function.

## function.json

Most of the content in this file is set in stone for this particular use. The `name` can be changed how you like and describes the name of the PowerShell variable for input and output. The input is written to a file, and output is also written to a file. The variable contains the path to that file.

## run.ps1

This code is automatically imported into an Azure Functions App function.

This is the code that is run when someone makes a *GET* to the webhook that is generated.

The webhook is called, ex.

``
$Response = Invoke-WebRequest -Uri "$azureFunctionUrl&EchoEnvVar=true" -Method Get -ContentType "application/json" -UseBasicParsing

Write-Verbose "The meaning of life is '$($Response.Content.TrimEnd())'"
``
