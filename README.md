# Intro
This script helps to run multiple Azure Bastion tunnels and SSH aggregator tunnels.

For more details visit this blog post: https://clidee.eu/2024/03/27/azure-bastion-for-advanced-users/

# Usage in Powershell
First you need to install the *ThreadJob* Powershell module:
```powershell
Install-Module -Name ThreadJob
```

Also you need to install the Azure CLI. Follow the official guide: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli

Then save the [Bastion_config.json](Bastion_config.json) and [Bastion_tunnels.ps1](Bastion_tunnels.ps1) files to your computer.

Open the Bastion_config.json file and add your parameters. This file is just an example and you need to specify with your environment.

The parameters documentation as follows:
```
{
    "Subscription": "<Your subscription's ID>",
                     
    "BastionResourceID": "<The Bastion server's ResourceID>",
    "JumpServerResourceID": "<The JumpServer's ResourceID>",
    "JumpServerUser": "<The username on the Jumpserver>",
    "JumpServerKeyPath": "<Path to the SSH private key. Use \\ to in the path like c:\\folder\\key >",
    "Tunnels": [
        {
            "Description": "<Short description>",
            "Enabled": <true or false>,
            "RemoteHost": "<IP or FQDN of the remote server>",
            "RemotePort": <Port number on the remote server>,
            "LocalAggregatorPort": <A random number on your local machine>,
            "LocalPort": <A random number on your local machine. You will use this port number to connect to your service.>
        }
    ]
}
```

Note that all the LocalAggregatorPorts and LocalPorts shall be unique and even cannot overlap other services running on your machine.

Once the configuration is ready then login to azure with Azure CLI and start the script.

```powershell
az login

powershell -executionpolicy bypass .\Bastion_tunnels.ps1
```

You can also create a shorcut icon to your desktop or start menu.

The script creates dedicated threads for each tunnel and all information will be written into the same console (it will be crowded). If there is a network break then it will automatically retry to recover the tunnels. All the logs and outputs will be in the console.

At the start there will be several Warnings with red letters which is fine. You will see something like this:

```
>  powershell -executionpolicy bypass .\Bastion_tunnels.ps1
Switching subscription to:  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Successfully changed subscription
Checking JumpServer's state...
VM is running
Opening Bastion tunnel via jumpserver to:  Example Jumpserver
az : WARNING: Command group 'az network' is in preview and under development. Reference and support levels: https://aka.ms/CLI_refstatus
At line:6 char:19
+                 &{az network bastion tunnel `
+                   ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (WARNING: Comman...s/CLI_refstatus:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
WARNING: Opening tunnel on port: 10022
WARNING: Tunnel is ready, connect on port 10022
WARNING: Ctrl + C to close
Opening SSH aggregator tunnel for:  Example Jumpserver


Tunnels are configured...
```

To stop the tunnels just close the console or press CTRL+c

# TODO
- Create a script in bash for Linux