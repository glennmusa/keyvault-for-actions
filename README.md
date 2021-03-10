# keyvault-for-actions

Generate an Azure Key Vault and tightly scoped Service Principal to pull secrets for use in a GitHub Actions workflow.

This is the resource creation automation for the required resources in this GitHub Action: <https://github.com/marketplace/actions/azure-key-vault-get-secrets/>

## Why

At some point you'll need to use secrets like passwords, connection strings, or API keys, in an automated CI/CD pipeline and you definitely don't want those things stored in your repository for potential abuse.

- The Service Prinicipal you'll create from this repository has ["Reader" RBAC management-plane permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles) to the Key Vault. The Service Principal can access the Key Vault resource, but does not have management permissions to update or modify the Key Vault or any other resource in the resource group or subscription the Key Vault resides in.

- The Service Principal you'll create from this repository has ["get list" Key Vault data-plane permissions](https://docs.microsoft.com/en-us/azure/key-vault/general/security-overview#privileged-access) to the Key Vault. The Service Principal does not have permissions to set, delete, backup, or restore secrets.

## What you need

- A GitHub repository
- Azure CLI: <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli/>

## What is in here

1. [create_keyvault.sh](./create_keyvault.sh) - a bash script to create the resources you need so that you can execute...
1. [read_secrets.yml](.github/workflows/read-secrets.yml) - a Github Actions workflow that securely pulls secrets from that Key Vault

### create_keyvault.sh

This is a shell script that will generate a resource group, Key Vault, and a limited scope Service Principal that has the [Reader role](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles) to __only__ the Key Vault resource that is created.

1. First, make the script executable with `chmod` and login to Azure CLI:

    ```shell
    chmod u+x ./create_keyvault.sh
    az login
    ```

1. Then, execute the script to create the resources (see [Optional Parameters](#Optional-Parameters) for setting a subscription ID or location, or for use with another Cloud).

    ```shell
    ./create_keyvault.sh
    ```

1. Once everything is complete, you'll receive two things:

    - the Key Vault name and
    - a JSON object containing the value for the GitHub secret "AZURE_CREDENTIALS"

    Here's what that should look like:

    ```plaintext
    # create_keyvault.sh output

    Here's your Key Vault name. You'll need this for your azure/get-keyvault-secrets GitHub Action.
    KEY VAULT NAME: ghactionskv0123456789

    Paste the entire JSON output below into GitHub secret value named AZURE_CREDENTIALS.
    AZURE_CREDENTIALS:

    {
        "clientId": "<GUID>",
        "clientSecret": "<GUID>",
        "subscriptionId": "<GUID>",
        "tenantId": "<GUID>",
        (...)
    }
    ```

1. Create a secret in your repository called "AZURE_CREDENTIALS" and set the JSON object output from `create_keyvault.sh` as the value.

    For how to set secrets see <https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-a-repository/>

### read_secrets.yml

This is a sample GitHub Actions workflow that uses the Key Vault and Service Principal created by `create_keyvault.sh`.

The workflow contains two jobs that show how to retrieve sensitive values for logging into an Azure Container Registry and downloading a blob from an Azure storage account.

You can use these samples to achieve those things if you'd like, but the value is in describing how Key Vault secrets are accessed:

```yaml
    - uses: azure/login@v1
        with:
        creds: ${{ secrets.AZURE_CREDENTIALS }} # Our output from create_keyvault.sh, stored as a GitHub Secret
    - id: get-secrets
        uses: azure/get-keyvault-secrets@v1
        with:
        keyvault: "${{ secrets.KEY_VAULT_NAME }}" # Our output from create_keyvault.sh, stored as a GitHub Secret
        secrets: 'storage-key' # A comma-separated string of secrets to retreive from Key Vault
    - name: download file with storage account key
        uses: azure/CLI@v1
        with:
        inlineScript: | # Access secrets via the ${{ }} syntax and the step id of the azure/get-keyvault-secrets Action
            az storage blob download \
            --account-name yourstorageaccountname \
            --account-key ${{ steps.get-secrets.outputs.storage-key }} \
            --container yourcontainer \
            --name uploadedfile.txt \
            --file downloadedfile.txt
```

The key takeaways:

- The workflow uses the `azure/login` GitHub Action passing in the "AZURE_CREDENTIALS" GitHub secret you created from `create_keyvault.sh`
- The Key Vault secrets to retrieve are a comma-separated string passed into the `secrets` argument of the `azure/get-keyvault-secrets` GitHub Action
- Key Vault Secrets are used by the referencing the `outputs` of the step that retrieved the secrets.

## Optional Parameters

Optionally, you can specify the subscription and region to deploy resources into. The subscription is defaulted upon `az login` and the location defaults to `eastus`:

```shell
./create_keyvault.sh <subscription ID or name> <location>
```

For example, if I wanted to set up my Key Vault in a different cloud that doesn't have `eastus`, I would do so like:

```shell
az cloud set -n <cloud name>
az login
./create_keyvault <desired subscription ID or name> <desired region>
```

## Helpful Links

Workflow Syntax: <https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions/>

Encrypted Secrets: <https://docs.github.com/en/actions/reference/encrypted-secrets/>

GitHub Actions:

- azure/login: <https://github.com/azure/login/>
- azure/CLI: <https://github.com/azure/CLI/>
- azure/get-keyvault-secrets: <https://github.com/azure/get-keyvault-secrets/>

### .devcontainer

I like Visual Studio Code's Remote - Containers extension because I don't have to worry about what tools are available on my machine.

Instead, when I clone the repo, I get with it all the tools the authors used to create the repo.

For more information see <https://code.visualstudio.com/docs/remote/containers/>

In their words:

> The Visual Studio Code Remote - Containers extension lets you use a Docker container as a full-featured development environment. It allows you to open any folder or repository inside a container and take advantage of Visual Studio Code's full feature set. A devcontainer.json file in your project tells VS Code how to access (or create) a development container with a well-defined tool and runtime stack. This container can be used to run an application or to sandbox tools, libraries, or runtimes needed for working with a codebase.
