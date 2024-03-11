# Define AWS provider
provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

# Variables
variable "instance_type" {
  default = "t2.micro"
}

variable "db_engine" {
  default = "mysql"
}

# EC2 Instance
module "ec2_instance" {
  source       = "terraform-aws-modules/ec2-instance/aws"
  version      = "3.0.0"
  name         = "web-server"
  instance_type = var.instance_type
  ami           = "ami-0c55b159cbfafe1f0"  # Update with your desired AMI
}

# RDS Database
module "rds" {
  source            = "terraform-aws-modules/rds/aws"
  version           = "2.0.0"
  identifier        = "mydb"
  instance_class    = "db.t2.micro"
  engine            = var.db_engine
  engine_version    = "5.7"
  allocated_storage = 20
}

# S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-name"
  acl    = "private"
}

# CodePipeline
resource "aws_codepipeline" "example" {
  name     = "example-pipeline"
  role_arn = aws_iam_role.example.arn

  artifact_store {
    location = aws_s3_bucket.my_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Terraform"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      configuration = {
        ProjectName = "Terraform-Build"
      }

      input_artifacts = ["source_output"]
    }
  }
}

# CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "example" {
  alarm_name          = "example"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "example"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "example" {
  name              = "/example"
  retention_in_days = 7
}
