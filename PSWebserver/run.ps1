#region functions

function Print-Response
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
        [PSObject]$Out
    )

    Out-File -Encoding Ascii -FilePath $res -inputObject $Out -Append
}

#endregion

if($REQ_QUERY_ECHOENVVAR)
{
    Print-Response -Out "$env:TheMeaningOfLife"
}
elseif($REQ_QUERY_TEMPLATE)
{
    $Out = @"
    {
    "`$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "TheMeaningOfLife": {
        "type": "int"
        },        
    },
    "variables": {},
    "resources": [
        {
        "apiVersion": "2015-08-01",
        "type": "Microsoft.Web/sites/config",
        "name": "[concat('$REQ_QUERY_SITENAME', '/appsettings')]",
        "location": "West Europe",
        "properties": {
            "AzureWebJobsDashboard":  "DefaultEndpointsProtocol=https;AccountName=function2e0828ab8e18;AccountKey=b0KRwRJhJTT3F+1XY8BgWyMG1USEZd/cMkVle+gG1PrrSDWjMSNjifoEca1NTf+QQrbwNObKUVk2YQh5vU2prw==",
            "AzureWebJobsStorage":  "DefaultEndpointsProtocol=https;AccountName=function2e0828ab8e18;AccountKey=b0KRwRJhJTT3F+1XY8BgWyMG1USEZd/cMkVle+gG1PrrSDWjMSNjifoEca1NTf+QQrbwNObKUVk2YQh5vU2prw==",
            "FUNCTIONS_EXTENSION_VERSION":  "~0.9",
            "AZUREJOBS_EXTENSION_VERSION":  "beta",
            "WEBSITE_NODE_DEFAULT_VERSION":  "6.5.0",
            "TheMeaningOfLife": "[parameters('TheMeaningOfLife')]"
        }
        }
    ],
    "outputs": {}
    }      
"@

    Print-Response -Out $Out
}
elseif($REQ_QUERY_PARAMETERS)
{
    $Out = @"
{
    "`$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "TheMeaningOfLife": {
            "value": 42
        }
    }
}    
"@

    Print-Response -Out $Out    
}
else
{
    Print-Response -Out "Ready to serve..."    
}