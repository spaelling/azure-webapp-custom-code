# Custom code on an Azure web app

There are many ways to get code into a web app (app service) in Azure, continous deployment, ftp, deploy fra TFS, etc.

But all of those I would categorize as *push* require access to the web app. Now continous deployment allows you to pull from a public repository, but if you need an application that is specific, or rather specialized, to a web app but you *do not have access* to the web app, then what?

First let me clarify what I mean by an application specialized to the web app:

It could be that it requires a unique license key. The application code for talking to the license server is the same for all, but it needs to identify itself to your license server, and you would like to tell the application beforehand how to identify it self, ie. provide it with a license key.

In order to solve this you need to be able to inject *code* into the web app during deployment which means you can piggyback the access from the deployer, in this case the one who sent an ARM template to Azure. And in order to inject code into the ARM template I will be using [linked templates](https://azure.microsoft.com/en-us/documentation/articles/resource-group-linked-templates/#linking-to-a-parameter-file).

Linked templates are normally thought of as static, but there is no one stopping you from providing the parameter file on-the-fly, which is exactly what I will be doing. One (and you could add more) of the parameters from the parameter file will be set as an environment variable in the Azure web app. We need some bits and pieces:

- A web application that can server a parameter file on request
- An ARM template that requests the parameter file as part of the deployment
- A web application that displays the environment variable, illustrating that this approach works
