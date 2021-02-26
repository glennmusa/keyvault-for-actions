# keyvault-for-actions

Generate a KeyVault and tightly scoped Service Principal to pull secrets for use in a Git Hub Actions workflow.

This is the resource creation automation for this tutorial: <https://github.com/marketplace/actions/azure-key-vault-get-secrets/>

## Why

At some point you'll need to use secrets like passwords, connection strings, or API keys, in an automated CI/CD pipeline and you definitely don't want those things stored in your repository for potential abuse.

## What you need

- A GitHub repository
- Azure CLI: <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli/>

## What is in here

1. [create_keyvault.sh](#create_keyvault.sh) - a bash script to create the resources you need so that you can execute...
2. [read_secrets.yml](#read_secrets.yml) - a Github Actions workflow that securely pulls secrets from that KeyVault

### create_keyvault.sh

A shell script that will generate a resource group, Azure KeyVault, and a limited scope Service Principal that has the [Contributor role](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles) to __only__ the KeyVault resource that is created.

1. First, login to Azure CLI:

    ```shell
    az login
    ```

2. Then, make the script executable:

    ```shell
    chmod u+x ./create_keyvault.sh
    ```

3. Finally, execute the script to create the resources.

    ```shell
    ./create_keyvault.sh
    ```

    Optionally, you can specify the subscription and region to deploy resources into. The subscription is defaulted upon `az login` and the location defaults to `eastus`:

    ```shell
    ./create_keyvault.sh <subscription ID or name> <location>
    ```

    For example, if I wanted to set up my KeyVault in a different cloud that doesn't have `eastus`, I would do so like:

    ```shell
    az cloud set -n <cloud name>
    az login
    ./create_keyvault <desired subscription ID or name> <desired region>
    ```

4. Once everything is complete, you'll receive a JSON output containing the value to provide the GitHub secret "AZURE_CREDENTIALS".

    ```shell
    # The command should output a JSON object similar to this:
      {
        "clientId": "<GUID>",
        "clientSecret": "<GUID>",
        "subscriptionId": "<GUID>",
        "tenantId": "<GUID>",
        (...)
      }
    ```

5. Create a secret in your repository called "AZURE_CREDENTIALS" and provide the JSON output from the command as the value.

    For more information on how to set a secret see <https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-a-repository/>

### read_secrets.yml

A GitHub Actions workflow that uses the KeyVault and Service Principal created by `create_keyvault.sh`

## Other helpful things

### .devcontainer

I like Visual Studio Code's Remote - Containers extension because I don't have to worry about what tools are available on my machine.

Instead, when I clone the repo, I get with it all the tools the authors used to create the repo.

For more information see <https://code.visualstudio.com/docs/remote/containers/>

In their words:

> The Visual Studio Code Remote - Containers extension lets you use a Docker container as a full-featured development environment. It allows you to open any folder or repository inside a container and take advantage of Visual Studio Code's full feature set. A devcontainer.json file in your project tells VS Code how to access (or create) a development container with a well-defined tool and runtime stack. This container can be used to run an application or to sandbox tools, libraries, or runtimes needed for working with a codebase.
