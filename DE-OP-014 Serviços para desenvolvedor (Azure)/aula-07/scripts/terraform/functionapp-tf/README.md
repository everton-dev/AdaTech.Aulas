# Azure Terraform Project

This project is designed to provision Azure resources using Terraform. It includes configurations for various Azure services and ensures that the Terraform plan command does not prompt for parameters.

## Project Structure

```
azure-terraform-project
├── main.tf          # Main configuration for Azure resources
├── outputs.tf       # Output values after applying the configuration
├── providers.tf     # Provider configuration for Azure
├── variables.tf     # Input variables with default values
└── README.md        # Project documentation
```

## Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed on your machine.
- An Azure account with the necessary permissions to create resources.

### Initialization

Before you can use the Terraform configuration, you need to initialize the project. Run the following command in the project directory:

```
terraform init
```

### Planning

To see what changes will be made to your Azure environment, run:

```
terraform plan
```

This command will not prompt for parameters due to the default values set in `variables.tf`.

### Applying the Configuration

To create the resources defined in the configuration, run:

```
terraform apply
```

### Outputs

After applying the configuration, you can view the output values defined in `outputs.tf` by running:

```
terraform output
```

## Cleanup

To remove all resources created by this project, run:

```
terraform destroy
``` 

This will delete all resources defined in the configuration.