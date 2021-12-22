variable "bc_env" {
  description = "Env. dev, staging, prod"
  type        = string

  validation {
    condition = contains(
      [
        "dev",
        "staging",
        "prod",
        "tooling"
      ],
      var.bc_env
    )
    error_message = "Bad environment name. bc_env must be one of (dev|prod|staging)."
  }
}

variable "bc_name" {
  description = "Name of the application, used in stringbuilding"
  type        = string
}

variable "bc_app_name" {
  description = "Name of the application, used in stringbuilding"
  type        = string
}

variable "aws_target_profile" {
  description = "Name of the application, used in stringbuilding"
  type        = string
}


# NETWORK VARIABLES
variable "priv_subnet_ids" {
  type        = list(string)
  description = "Private Subnet IDs used by EKS. Provide input as list of strings"
}

variable "pub_subnet_ids" {
  type        = list(string)
  description = "Public Subnet IDs used by EKS. Provide input as list of strings."
}

# TAGS
## Expand this with any tags that absolutely must be applied to everything
variable "bc_vpc_generic_tags" {
  description = "Generic tags to be applied to all taggable resources in the VPC. For internal use."
  type        = map

  default = {
    "terraform_managed" = "True"
  }
}

## Intentionally left blank, to be used by code that includes this module
variable "bc_vpc_defined_tags" {
  description = "Tags specific to the Bounded Context, to be applied to all taggable resources in the VPC"
  type        = map
  default     = {}
}

## CLUSTER NAMESPACE
variable "namespaces" {
  type        = list(string)
  description = "Kubernetes namespace(s) for selection.  Adding more than one namespace, creates and manages multiple namespaces."
  default     = ["default", "kube-system"]
}

variable "labels" {
  type        = map(string)
  description = "Key-value mapping of Kubernetes labels for selection"
  default     = {}
}

variable "oidc_thumbprint_list" {
  description = "WIP"
  type        = list
  default     = []
}

# Kubectl Variables
variable "assume_role_name" {
  description = "The name of the role that was used to invoke the module"
  type        = string
}

variable "bc_region" {
  description = "Region of the Bounded Context"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "The VPC_ID that is used to create resources inside of that vpc"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the ssh key to import and use for the jump box default"
  type        = string
}

variable "ssh_private_key_identity" {
  description = "The host name in .ssh/config on the box which is executing terraform commands, so that terraform can connect to remote box"
  type        = string
}

variable "kubectl_version" {
  # Versions can be found: https://github.com/kubernetes/kubernetes/releases
  description = "The version to download"
  type        = string
  default     = "1.18.12"
}

variable "account_id" {
  description = "The account number in which the resource is being created in"
  type        = string
}

variable "enable_detailed_instance_monitoring" {
  description = "Turn on detailed instance monitoring"
  type        = bool
  default     = "false"
}

variable "root_volume_size" {
  description = "The size of the root volume on the instance"
  type        = string
  default     = "50"
}

variable "instance_type" {
  description = "The type of instance to launch"
  type        = string
  default     = "t3.medium"
}
