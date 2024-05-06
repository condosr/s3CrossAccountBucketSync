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

variable "userName" {
  description = "Name of the IAM user (optional)"
  type=string
}

variable "roleName" {
  description = "Name of the IAM role"
  type=string
}

variable "bucketName" {
  description = "Name of the S3 bucket (optional)"
  type=string
}

variable "sendingAccount" {
  description = "AWS account ID of the sending account"
  type=string
}

variable "createUser"{
  description="Boolean determining of a user should be created or an existing one will be used"
  type=bool
}

variable "createBucket"{
  description="Boolean determining if a bucket should be created or an existing one will be used"
  type=bool
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

resource "aws_iam_user" "user" {
  count = var.createUser ? 1 : 0
  name  = var.userName
  force_destroy=true
  tags = {
    Project = var.project
    CreatedBy = var.createdBy
    DeployedDate = var.deployedDate
  }
}

resource "aws_iam_user_policy" "policy" {
  user       = var.userName
  policy     = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::${var.sendingAccount}:role/${var.roleName}"
    }]
  })
}

resource "aws_s3_bucket" "bucket" {
  count = var.createBucket ? 1 : 0
  bucket = var.bucketName
  force_destroy=true
  tags = {
    Project = var.project
    CreatedBy = var.createdBy
    DeployedDate = var.deployedDate
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket  = var.bucketName
  policy  = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.sendingAccount}:role/${var.roleName}"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${var.bucketName}",
        "arn:aws:s3:::${var.bucketName}/*"
      ]
    }]
  })
}


