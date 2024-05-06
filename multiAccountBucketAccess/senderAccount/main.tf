terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

variable "project"{
  type=string
  description="Project associated with resources"
}

variable "createdBy"{
  type=string
  description="Who Created Resource"
}

variable "deployedDate"{
  type=string
  description="Date Resources were originally deployed"
}

variable "recievingAccount" {
  type=string
  description = "AWS account ID of the receiving account"
}

variable "externalID" {
  type=string
  description = "External ID for trust relationship"
}

variable "sendingBucketName" {
  type=string
  description = "Name of the S3 bucket"
}

variable "recievingBucketName" {
  type=string
  description = "Name of the S3 bucket"
}

variable "kmsKeyArn" {
  type=string
  description = "ARN of the KMS key"
}

variable "roleName"{
  type=string
  description="Name of the role that will help the transfer"
}

resource "aws_iam_role" "role" {
  name               = var.roleName
  tags = {
    Project = var.project
    CreatedBy = var.createdBy
    DeployedDate = var.deployedDate
  }
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.recievingAccount}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": var.externalID
        }
      }
    }]
  })
}

resource "aws_iam_policy" "policy" {
  name        = "${var.project}TransferPolicy"
  tags = {
    Project = var.project
    CreatedBy = var.createdBy
    DeployedDate = var.deployedDate
  }
  description = "Policy for accessing S3 and KMS"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource": ["arn:aws:s3:::${var.sendingBucketName}","arn:aws:s3:::${var.recievingBucketName}"]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource": ["arn:aws:s3:::${var.sendingBucketName}/*","arn:aws:s3:::${var.recievingBucketName}/*"]
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource": var.kmsKeyArn
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:Describe*",
          "kms:Get*",
          "kms:List*"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

