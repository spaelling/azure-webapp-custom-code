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

function New-Guid
{
    [guid]::NewGuid().Guid.ToUpper()
}

#endregion

$requestBody = Get-Content $req -Raw | ConvertFrom-Json

<# echo
Print-Response -Out $requestBody
#Print-Response -Out $(Get-Content $req -Raw )
#>

$Out = @"
    {
      "apiVersion": "2015-08-01",
      "type": "Microsoft.Web/sites/config",
      "name": "[concat(variables('webApp').backend.name, '/connectionstrings')]",
      "dependsOn": [
        "[concat('Microsoft.Web/Sites/', variables('webApp').backend.name)]",
        "[concat('Microsoft.Sql/servers/', variables('sqlServer').name, '/databases/', variables('sqlServer').database.name)]"
      ],
      "properties": {
        "[variables('sqlServer').database.name]": {
          "value": "[concat('Data Source=tcp:', reference(concat('Microsoft.Sql/servers/', variables('sqlServer').name), '2014-04-01-preview').fullyQualifiedDomainName, ',1433;Initial Catalog=', variables('sqlServer').database.name, ';User Id=', variables('sqlServer').administratorLogin, '@', variables('sqlServer').name, ';Password=', variables('sqlServer').administratorLoginPassword, ';')]",
          "type": "SQLServer"
        }
      }
    }
"@

Print-Response -Out $Out