# enter your own subscription id and resource group name
$SubscriptionId = 'Subscription Id'
$ResourceGroupName = 'azure-webapp-custom-code'
# get this from the Function App
$azureFunctionUrl = 'https://...'
# the name of the Function App (or an App Service, in which case you will have to check the environment variable elsewhere)
$appServiceName = 'awcc-fa'

# No need to change below this line
$TemplateFile = "$PSScriptRoot\azuredeploy.json"
$TemplateParameterFile = "$PSScriptRoot\azuredeploy.parameters.json"
$VerbosePreference = 'Continue'

try
{
    Get-AzureRmContext | Out-Null
}
catch [System.Exception]
{
    Login-AzureRmAccount -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
}

<# Copy the output to run.ps1, replacing the lines 41-45, see README for details
# gets the appsettings from specified app service
$resource = Invoke-AzureRmResourceAction -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/config -ResourceName "$appServiceName/appsettings" -Action list -ApiVersion 2015-08-01 -Force
$resource.Properties | ConvertTo-Json
return
#>

$DeploymentName = "Deployment_$(Get-Date -Format "yyyy-MM-dd_hh.mm.ss")"

$DeploymentParameters = @{
    ResourceGroupName     = $ResourceGroupName
    Mode                  = 'Incremental'
    TemplateFile          = $TemplateFile
    TemplateParameterFile = $TemplateParameterFile
    ErrorAction           = 'Stop'
    Name                  = $DeploymentName
    azureFunctionUrl      = $azureFunctionUrl
    appServiceName        = $appServiceName
}

# deploy the template
New-AzureRmResourceGroupDeployment @DeploymentParameters

# echo the environment variable
$Response = Invoke-WebRequest -Uri "$azureFunctionUrl&EchoEnvVar=true" -Method Get -ContentType "application/json" -UseBasicParsing

Write-Verbose "The meaning of life is '$($Response.Content.TrimEnd())'"