# ECR
resource "aws_ecr_repository" "this" {
  name = "codepipeline-tutorial/app"
}

# ALB Resources
data "aws_vpc" "develop" {
  filter {
    name   = "tag:Name"
    values = ["develop"]
  }
}
resource "aws_alb_target_group" "this" {
  count       = 2
  name        = "codepipeline-tutorial-tg${count.index}"
  vpc_id      = data.aws_vpc.develop.id
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/codepipeline-tutorial"
  retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/codepipeline-tutorial"
  retention_in_days = 7
}

moved {
  from = aws_cloudwatch_log_group.this
  to   = aws_cloudwatch_log_group.ecs
}
moved {
  from = data.aws_iam_role.this
  to   = data.aws_iam_role.codebuild
}

# CodeBuild
data "aws_iam_role" "codebuild" {
  name = "codebuild-service-role"
}
data "aws_caller_identity" "current" {}
resource "aws_codebuild_project" "this" {
  name = "codepipeline-tutorial"
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "AWS_REGION"
      type  = "PLAINTEXT"
      value = "ap-northeast-1"
    }
    environment_variable {
      name  = "ACCOUNT_ID"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
  }
  service_role = data.aws_iam_role.codebuild.arn
  source {
    type = "CODEPIPELINE"
  }
}

# CodePipeline
data "aws_codestarconnections_connection" "github" {
  name = "github"
}
data "aws_iam_role" "codepipeline" {
  name = "AWSCodePipelineServiceRole-ap-northeast-1"
}
resource "aws_codepipeline" "this" {
  name     = "codepipeline-tutorial"
  role_arn = data.aws_iam_role.codepipeline.arn
  artifact_store {
    type     = "S3"
    location = "codepipeline-ap-northeast-1-697830664414"
  }
  stage {
    name = "Source"
    action {
      category = "Source"
      owner    = "AWS"
      name     = "Source"
      provider = "CodeStarSourceConnection"
      version  = 1
      configuration = {
        "BranchName"           = "develop"
        "ConnectionArn"        = data.aws_codestarconnections_connection.github.arn
        "FullRepositoryId"     = "nimowagukari/codepipeline-tutorial"
        "OutputArtifactFormat" = "CODEBUILD_CLONE_REF"
      }
      output_artifacts = ["SourceArtifact"]
    }
  }
  stage {
    name = "Build"
    action {
      category = "Build"
      owner    = "AWS"
      name     = "Build"
      provider = "CodeBuild"
      version  = 1
      configuration = {
        "ProjectName" = aws_codebuild_project.this.name
      }
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
    }
  }
  stage {
    name = "Deploy"
    action {
      category = "Deploy"
      owner    = "AWS"
      name     = "Deploy"
      provider = "ECS"
      version  = 1
      configuration = {
        "ClusterName" = "default"
        "ServiceName" = "codepipeline-tutorial"
      }
      input_artifacts = ["BuildArtifact"]
    }
  }
}
