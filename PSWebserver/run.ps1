#requires -Version 3.0

$VaultName = "AFWLKV"

# Specify the name of the record type that you'll be creating
# the resulting type will be called $LogType_CL (CL for Custom Log)
$LogType = "Webhook"

#region functions

# this function is not currently in use. It is written by (I believe) http://www.xipher.dk/WordPress/
# I am  instead expecting strict JSON in the payload
function ConvertHTTPPost
{
	[CmdletBinding()]
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[string]$HTTPPost
	)
	BEGIN
	{
		Add-Type -AssemblyName System.Web
	}
	PROCESS
	{
		$Obj = New-Object -TypeName PSCustomObject
		$HTTPPost -split '&' | ForEach-Object -Process {
			$Val = $_ -split '='
			
            $Name = [System.Web.HttpUtility]::UrlDecode($($Val[0]))
			if ($Name -match 'text')
			{
                $Value = [System.Web.HttpUtility]::UrlDecode($($Val[1] -replace '\+', ' '))
			}
			Else
			{
                $Value = [System.Web.HttpUtility]::UrlDecode($Val[1])				
			}
            $Obj | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
		}
		$Obj
	}
	END
	{
		
	}
}

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

# from https://azure.microsoft.com/en-us/documentation/articles/log-analytics-data-collector-api/

# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}


# Create the function to create and post the request
Function Post-OMSData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -fileName $fileName `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}

#endregion

# TODO: if content type is "application/json" then do convertfrom-json, otherwise use the convertHTTPPost
#$requestBody = ConvertHTTPPost -HTTPPost $(Get-Content $req -Raw ) 

$requestBody = Get-Content $req -Raw | ConvertFrom-Json

<# echo
Print-Response -Out $requestBody
#Print-Response -Out $(Get-Content $req -Raw )
#>

# will get secret values from Azure Key Vault (keep them out of source code) - first we need to login
try
{
    $tenantId = $requestBody.tenantId

    $appPrincipalId = $requestBody.appPrincipalId
    $appPrincipalKey = ConvertTo-SecureString -String $requestBody.appPrincipalKey -AsPlainText -Force

    $secureCredential = New-Object System.Management.Automation.PSCredential ($appPrincipalId, $appPrincipalKey)

    Login-AzureRmAccount -ServicePrincipal -Tenant $tenantId -Credential $secureCredential -ErrorAction Stop
}
catch [System.Exception]
{
    Print-Response -Out "Failed to login as service principal. Error was:`n$($Error[0])"
    # can echo these valuable secrets :D
    #Print-Response -Out "`$tenantId = $tenantId`n`$appPrincipalId = $appPrincipalId`n`$appPrincipalKey = $($requestBody.appPrincipalKey)"
    return
}

#Print-Response -Out "Logged in as service principal"

# Replace with your Workspace ID
$CustomerId = Get-AzureKeyVaultSecret -VaultName $VaultName -Name OMSWorkspaceID | Select-Object -ExpandProperty SecretValueText -ErrorAction Stop

# Replace with your Primary Key
$SharedKey = Get-AzureKeyVaultSecret -VaultName $VaultName -Name OMSWorkspaceKey | Select-Object -ExpandProperty SecretValueText -ErrorAction Stop

# Specify a time in the format YYYY-MM-DDThh:mm:ssZ to specify a created time for the records
$TimeStampField = "YYYY-MM-DDThh:mm:ssZ";
# need to look a bit different for Get-Date to work
$tsf = "yyyy-MM-ddThh:mm:ssZ"
$Now = Get-Date -Format $tsf

$OMSLogAnalyticsPayload = ConvertTo-Json $requestBody.OMSLogAnalyticsPayload

#Print-Response -Out "OMS LA payload is $OMSLogAnalyticsPayload"

try
{
    # Submit the data to the API endpoint
    $Response = Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($OMSLogAnalyticsPayload)) -logType $logType
}
catch [System.Exception]
{
    Print-Response -Out "Failed to post OMS data. Error:`n$($Error[0])"
}

#Print-Response -Out "Response was: $Response"

# TODO proper response logic, ex. codes

if($Response -eq 202)
{
    Print-Response -Out "Response OK from OMS Log Analytics"
}
else
{
    Print-Response -Out "Error in response from OMS Log Analytics. Response was $Response"
}