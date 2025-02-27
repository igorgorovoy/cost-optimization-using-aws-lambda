/**
 * # rdmbs-adhoc Lambda Function
 *
 * This module creates an AWS Lambda function for processing rdmbs (Open, High, Low, Close, Volume) data in ad-hoc mode.
 *
 * ## Usage
 *
 * ```hcl
 * module "rdmbs_adhoc_lambda" {
 *   source = "./lambda/rdmbs-adhoc"
 *   # add required variables
 * }
 * ```
 *
 * ## Requirements
 *
 * | Name | Version |
 * |------|---------|
 * | terraform | >= 1.0 |
 * | aws | >= 4.0 |
 *
 * ## Providers
 *
 * | Name | Version |
 * |------|---------|
 * | aws | >= 4.0 |
 *
 * ## Resources
 *
 * | Name | Type |
 * |------|------|
 * | aws_lambda_function | Resource |
 * | aws_iam_role | Resource |
 * | aws_cloudwatch_log_group | Resource |
 *
 * ## Input Variables
 *
 * | Name | Description | Type | Default | Required |
 * |------|-------------|------|---------|----------|
 * | environment | Deployment environment | string | "dev" | yes |
 * | region | AWS region | string | "eu-west-1" | yes |
 *
 * ## Output Values
 *
 * | Name | Description |
 * |------|-------------|
 * | lambda_function_arn | Lambda function ARN |
 * | lambda_function_name | Lambda function name |
 *
 * ## Additional Information
 *
 * This Lambda function is designed for processing rdmbs data in ad-hoc mode.
 * It can be invoked through API Gateway or other AWS services.
 */

variable "rds_instance_id" {
  type        = string
  description = "RDS instance identifier (DBInstanceIdentifier)"
  default     = "multiregion-dev-saas-rdmbs-test"
}

# data "aws_ami" "amazon_linux2" {
#   provider    = aws.Green
#   most_recent = true
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
#   filter {
#     name   = "state"
#     values = ["available"]
#   }
#   owners = ["amazon"]
# }


resource "aws_iam_role" "adhock_ec2_role" {
  name               = "adhock-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Політика (inline) на читання секретів + термінацію самого себе
resource "aws_iam_role_policy" "adhock_ec2_role_policy" {
  name = "adhock-ec2-role-policy"
  role = aws_iam_role.adhock_ec2_role.id

  policy = data.aws_iam_policy_document.adhock_ec2_role_policy.json
}

data "aws_iam_policy_document" "adhock_ec2_role_policy" {
  provider = aws.Green
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:eu-central-1:294949574448:secret:rdmbs/dbCredentials-test-vL",
      "arn:aws:secretsmanager:eu-central-1:294949574448:secret:rdmbs/slackWebhook-test-MR"
    ]
  }

  statement {
    actions = [
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
  }
}

# Створюємо Instance Profile для EC2
resource "aws_iam_instance_profile" "adhock_ec2_profile" {
  provider = aws.Green
  name     = "adhock-ec2-instance-profile"
  role     = aws_iam_role.adhock_ec2_role.name
}


resource "aws_iam_role" "lambda_role" {
  name               = "adhock-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Політика (inline) для Lambda, щоб створювати EC2 та писати логи
resource "aws_iam_role_policy" "lambda_role_policy" {
  name = "adhock-lambda-role-policy"
  role = aws_iam_role.lambda_role.id

  policy = data.aws_iam_policy_document.lambda_role_policy.json
}

data "aws_iam_policy_document" "lambda_role_policy" {
  statement {
    actions = [
      "ec2:RunInstances",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeTags",
      "ec2:CreateTags",
      "iam:PassRole"
    ]
    resources = ["*"]
  }

  # Дозвіл на log
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda_src.zip"
}

resource "aws_lambda_function" "db_maintenance_lambda" {
  provider      = aws.Green
  function_name = "rdmbs-maintenance-lambda"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.9"
  handler       = "handler.lambda_handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  # environment {
  #   variables = {
  #     # Приклад змінної, якщо потрібно
  #     SOME_VAR = "some_value"
  #   }
  # }

  depends_on = [
    aws_iam_role_policy.lambda_role_policy
  ]
}


resource "aws_cloudwatch_event_rule" "db_maintenance_rule" {
  provider      = aws.Green
  name          = "db-maintenance-event-rule"
  description   = "Rule triggered by CloudWatch Alarm state change"
  event_pattern = <<EOF
{
  "source": ["aws.cloudwatch"],
  "detail-type": ["CloudWatch Alarm State Change"],
  "detail": {
    "alarmName": ["rds-ebsbytebalance-alarm"] 
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "db_maintenance_target" {
  provider  = aws.Green
  rule      = aws_cloudwatch_event_rule.db_maintenance_rule.name
  target_id = "rdmbs-maintenance-lambda"
  arn       = aws_lambda_function.db_maintenance_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  provider      = aws.Green
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.db_maintenance_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.db_maintenance_rule.arn
}

resource "aws_cloudwatch_metric_alarm" "rds_ebsbytebalance_alarm" {
  provider                  = aws.Green
  alarm_name                = "rds-ebsbytebalance-alarm"
  alarm_description         = "Alarm when RDS EBS usage less than 80%"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 1
  metric_name               = "EBSByteBalance%"
  namespace                 = "AWS/RDS"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 80
  alarm_actions             = [] #[aws_cloudwatch_event_rule.db_maintenance_rule.arn]
  insufficient_data_actions = []
  ok_actions                = []

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_secretsmanager_secret" "db_credentials" {
  provider                = aws.Green
  name                    = "rdmbs/dbCredentials-test"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  provider  = aws.Green
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    host     = "multiregion-dev-saas-rdmbs-test.c0q2smbp0rd7.eu-west-1.rds.amazonaws.com"
    port     = 5432
    username = "rdmbs"
    password = "******************"
    dbname   = "rdmbs"
  })
  depends_on = [aws_secretsmanager_secret.db_credentials]
}



resource "aws_secretsmanager_secret" "slack_webhook" {
  provider                = aws.Green
  name                    = "rdmbs/slackWebhook-test"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "slack_webhook_version" {
  provider  = aws.Green
  secret_id = aws_secretsmanager_secret.slack_webhook.id

  secret_string = jsonencode({
    webhook = "https://hooks.slack.com/services/***********/***********/**************************"
  })
  depends_on = [aws_secretsmanager_secret.slack_webhook]
}