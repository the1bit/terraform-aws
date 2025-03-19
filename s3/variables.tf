variable "aws_profile" {
  description = "The AWS profile to use for the S3 bucket"
  type        = string
  default     = "cloudsteak"
}

variable "aws_region" {
  description = "The AWS region where the S3 bucket will be created"
  type        = string
  default     = "eu-central-1"
}

variable "name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "devtest20250312"
}

variable "enabled" {
  description = "A boolean that indicates whether the S3 bucket should be created"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the bucket"
  type        = map(string)
  default = {
    Environment  = "dev"
    ForceDestroy = "true"
  }
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error"
  type        = bool
  default     = true
}


############################################
# TEMP
############################################

# >
# Global
# ====================
variable "region" {
  description = "AWS default region"
  type        = string
  default     = "eu-central-1"
}

variable "profile_prod" {
  description = "Profile to use in Prod environment"
  type        = string
  default     = "vfde-test"
}

variable "profile" {
  description = "Profile to use in NProd environment"
  type        = string
  default     = "vfde-test"
}

variable "default_tags" {
  description = "AWS Tags"
  type        = map(any)
  default     = {}
}

variable "alb_ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "nlb_ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "environment" {
  default = "playground"
}


variable "one_nat_gateway_per_az" {
  default     = false
  description = "Indicates if there should be a nat gateway per availability zone or a single nat gateway for the region"
}

variable "zone_name_vf_eo" {
  description = "Hosted Zone VF EO"
  type        = string
  default     = "vf-eo.de"
}

###################################################################################
#################################### S3 Buckets ###################################
###################################################################################

variable "s3_actions" {
  description = "List of actions the user is permitted to perform on the S3 bucket"
  default     = ["s3:PutObject", "s3:PutObjectAcl", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:GetBucketLocation", "s3:AbortMultipartUpload"]
}

variable "s3_bucket_names" {
  type        = map(any)
  description = "FQDN of the buckets"
  default = {
    logging = "cs-s3-playground-logging"
  }
}

variable "s3_sse_algorithm" {
  description = "Map of SSE algorithms to apply to each S3 bucket"
  default = {
    vpc_flow  = "AES256"
    logging   = "AES256"
    user_data = "AES256"
    alb       = "AES256"
  }
}

variable "s3_acl" {
  description = "Map of ACL to apply to each S3 bucket"
  type        = map(any)
  default = {
    logging   = "log-delivery-write"
    vpc_flow  = "private"
    user_data = "private"
    alb       = "private"
  }
}

variable "s3_bucket_rules" {
  type = map(any)
  default = {
    logging = [{
      "id" : "cs-playground-logging-expire",
      "enabled" : false,
      "prefix" : "",
      "transition" : []
      "expiration" : {
        "days" : 30
      },
      "AbortIncompleteMultipartUpload" : {
        "DaysAfterInitiation" : 7
      }
      },
    ]
    vpc_flow = [{
      "id" : "vfde-edo-playground-vpc-flow-expire",
      "enabled" : false,
      "prefix" : "",
      "transition" : []
      "expiration" : {
        "days" : 7
      },
      "AbortIncompleteMultipartUpload" : {
        "DaysAfterInitiation" : 7
      }
      },
    ]
  }
}

###########
#NETWORKING
###########

variable "vpc_cidr" {
  default = "10.14.0.0/16"
  type    = string
}

variable "cidrs" {
  default = {
    private = ["10.14.0.0/20", "10.14.16.0/20", "10.14.32.0/20"]
    public  = ["10.14.48.0/20", "10.14.64.0/20", "10.14.80.0/20"]
  }
  type = map(any)
}

###############
#EKS PLAYGROUND MAIN
###############

variable "ami_eks_node" {
  # DO NOT USE AMIs from the PCS account. Always copy it to the respective AWS account (Playground is 004770426262)
  # default = "ami-076b21f70551da9a9"
  default = "ami-111111111"
}

variable "eks_cluster_name" {
  default = "vfde-edo-eks-playground"
}

variable "whitelist_ips" {
  description = "IP Whitelist"
  type        = list(string)
  default     = []
}

########
# ELK
########

variable "logstash_image" {
  type        = string
  default     = "004770426262.dkr.ecr.eu-central-1.amazonaws.com/logstash:8.6.2"
  description = "Logstash image to pull"
}

variable "logstash_pipelines" {
  description = "Logstash pipelines to implement"
  default = {
    playground_metricbeat = {
      input               = "beats"
      type                = "metricbeat_playground"
      auth                = false # only supported by HTTP input
      codec               = "json_lines"
      host                = "0.0.0.0"
      port                = 5000
      ssl_enabled         = "true"
      id                  = "metricbeat"
      index               = "metricbeat-playground"
      number_of_workers   = 4
      debug               = "false"
      rotation            = "weekly"
      number_of_shards    = 7
      index_template      = "generic"
      env                 = "playground"
      ordered             = "false"
      batch_size          = "125"
      number_of_pipelines = 1
      optimization_tag    = "true"
    }
    playground_filebeat = {
      input               = "beats"
      type                = "filebeat_beats_playground"
      auth                = false # only supported by HTTP input
      codec               = "plain"
      host                = "0.0.0.0"
      port                = 5002
      ssl_enabled         = "true"
      id                  = "filebeat"
      index               = "filebeat-playground"
      number_of_workers   = 4
      debug               = "false"
      rotation            = "weekly"
      number_of_shards    = 4
      index_template      = "generic"
      env                 = "playground"
      ordered             = "false"
      batch_size          = "125"
      number_of_pipelines = 2
      optimization_tag    = "true"
    }
  }
}

variable "logstash_aws_services_consumer_pipelines" {
  description = "Logstash AWS service consumer pipelines to implement"
  default = {
    playground_cloudwatch = {
      type              = "cloudwatch_rds"
      id                = "Logstash_Cloudwatch"
      index             = "cloudwatch-rds"
      number_of_workers = 1
      debug             = "false"
      rotation          = "weekly"
      number_of_shards  = 2
      index_template    = "generic"
      env               = "playground"
      ordered           = "false"
      batch_size        = "125"
      optimization_tag  = "false"
    }
  }
}

######################
##### Opensearch #####
######################

variable "opensearch_master_user" {
  type        = string
  description = "Username for elasticsearch master user"
  default     = "elastic_master"
}

variable "opensearch_master_user_password" {
  type        = string
  description = "Password for elasticsearch master user"
  default     = "tempPassword123!"
}

##################
##### Qualys #####
##################

variable "qualys_activation_id" {
  default = "6f5d2eec-ba86-443c-88af-07a394fc3148"
}
variable "qualys_customer_id" {
  default = "3f751192-e92e-d42e-83ce-c5a54f519118"
}


###################################################################################
# IAM
###################################################################################

variable "read_only_role_principals_type" {
  type        = string
  default     = "AWS"
  description = "Principals that can assume the role read_only to be created (AWS, Service)"
}

variable "read_only_role_principals" {
  type        = list(any)
  default     = []
  description = "List of read only principals that may assume read only role"
}

variable "read_write_principals" {
  type        = list(any)
  default     = []
  description = "List of read|write principals"
}

variable "iam_role_policy_default" {
  description = "Default trust relationship to apply to roles associated with lambda"
  default     = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ViewBilling",
            "Effect": "Allow",
            "Action": [
              "aws-portal:ViewBilling"
            ],
            "Resource": "*"
        }
    ]
}
  EOF
}


##Policy
variable "policy_arns" {
  description = "Use in case of specific policy ARN need (Policy will no be created)"
  type = map
  default = {}
}

variable "new_policies" {
  description = "The policy to be created"
  type = map
  default = {}
}


###################################################################################
# BUCKET POLICY
###################################################################################

# data "aws_iam_policy_document" "bucket_policy" {
#   # -- Statement #1: Enforce HTTPS Only --
#   statement {
#     sid    = "EnforceHttpsAlways"
#     effect = "Deny"

#     principals {
#       type        = "AWS"
#       identifiers = ["*"]
#     }

#     actions = [
#       "*",
#     ]

#     resources = [
#       "arn:aws:s3:::${var.name}",
#       "arn:aws:s3:::${var.name}/*",
#     ]

#     condition {
#       test     = "Bool"
#       variable = "aws:SecureTransport"
#       values   = ["false"]
#     }
#   }

#   # -- Statement #2: Read-Write Permissions --
#   statement {
#     sid    = "ReadWrite"
#     effect = "Allow"

#     principals {
#       type = "AWS"
#       identifiers = [
#         "arn:aws:iam::004770426262:user/Auto_CelFocus",
#         "arn:aws:iam::004770426262:role/vfde-edo-s3-playground-logging-s3-read-write",
#       ]
#     }

#     actions = [
#       "s3:PutObjectAcl",
#       "s3:PutObject",
#       "s3:ListBucketMultipartUploads",
#       "s3:ListBucket",
#       "s3:GetObjectVersion",
#       "s3:GetObject",
#       "s3:GetBucketLocation",
#       "s3:DeleteObjectVersion",
#       "s3:DeleteObject",
#       "s3:AbortMultipartUpload",
#     ]

#     resources = [
#       "arn:aws:s3:::${var.name}",
#       "arn:aws:s3:::${var.name}/*",
#     ]
#   }

#   # -- Statement #3: Read-Only Permissions --
#   statement {
#     sid    = "ReadOnly"
#     effect = "Allow"

#     principals {
#       type = "AWS"
#       identifiers = [
#         "arn:aws:iam::004770426262:user/Auto_CelFocus",
#       ]
#     }

#     actions = [
#       "s3:ListBucketMultipartUploads",
#       "s3:ListBucket",
#       "s3:GetObject",
#       "s3:GetBucketLocation",
#     ]

#     resources = [
#       "arn:aws:s3:::${var.name}",
#       "arn:aws:s3:::${var.name}/*",
#     ]
#   }
# }



