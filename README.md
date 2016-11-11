# Dynamic linked ARM templates using Azure Functions

Greetings!

I had some trouble figuring out a good descriptive title. That is at least a general description of what I want to show. The more specific purpose, for which I needed this in the first place, is providing some *unique* environment variables in an Azure web app, without having access to the app at all.
I think that with this approach you can do much more than you would normally be able to with ARM templates, at the cost of complexity. But still I believe that the added complexity is kept at a minimum by using Azure Functions and PowerShell to provide the dynamic ARM template.

Let's make ARM templates great again...

There are many ways to get code into a web app (app service) in Azure, continous deployment, ftp, deploy fra TFS, etc.

But all of those I would categorize as *push* require access to the web app. Now continous deployment allows you to pull from a public repository, but if you need an application that is specific, or rather specialized, to a web app but you *do not have access* to the web app, then what?

First let me clarify what I mean by an application specialized to the web app:

It could be that it requires a unique license key. The application code for talking to the license server is the same for all, but it needs to identify itself to your license server, and you would like to tell the application beforehand how to identify it self, ie. provide it with a license key.

In order to solve this you need to be able to inject *code* into the web app during deployment which means you can piggyback the access from the deployer, in this case the one who sent an ARM template to Azure. And in order to inject code into the ARM template I will be using [linked templates](https://azure.microsoft.com/en-us/documentation/articles/resource-group-linked-templates/#linking-to-a-parameter-file).

Linked templates are normally thought of as static, but there is no one stopping you from providing the parameter file on-the-fly, which is exactly what I will be doing. One (and you could add more) of the parameters from the parameter file will be set as an environment variable (also called *app settings*) in the Azure web app. We need some bits and pieces:

- A web application that can serve a parameter file on request
- An ARM template that requests the parameter file as part of the deployment
- A web application that displays the environment variable, illustrating that this approach works

The first one I will do in an unorthodox way; I will be using Azure functions. I just need an endpoint that will serve me some JSON, and Azure functions is capable of just that, and I can write it in PowerShell.
All you need to do is to sync your own instance of a *Function App* with a fork of this repository. There is a README in PSWebserver that will explain in further details.

And because I am really lazy I have configured this same *Function App* so that it can also return the environment variable that we will be configuring.
Now, because I *am* lazy, I need you to do some work. Since there is already some environment variables set in the Function App you will need to retrieve these. The [Azure Resource Explorer](https://resources.azure.com) is excellent for this purpose, or you can use the PowerShell snippet below (I have put this into *deploy.ps1* also):

```
$ResourceGroupName = 'azure-webapp-custom-code'
$appServiceName = 'awcc-fa'

$resource = Invoke-AzureRmResourceAction -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/config -ResourceName "$appServiceName/appsettings" -Action list -ApiVersion 2015-08-01 -Force
$resource.Properties
```

Replace the output with line 41-45 in *run.ps1*. It should look very similar. When deploying *app settings* in an ARM template whatever is in the template will overwrite the current app settings. If something is missing then those entries are lost.
Even though it seems to keep runing, there is no point in *maybe breaking it*.
Remember to sync your Github repository with these new changes.

The ARM Template can be found in the folder named *ARMTemplate* - it is of the type *Microsoft.Resources/deployments*, meaning that it will deploy a specified ARM template. in this case we point it at our Function App endpoint that will respond with a template or parameter file.
In that folder you will also find a script to deploy it. When it has deployed successfully the script will query the Function App to echo the environment variable, and should print out the meaning of life, ie. *42*.
