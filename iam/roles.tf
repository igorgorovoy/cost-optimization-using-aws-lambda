# IAM Role for Lambda ec2_scheduler
resource "aws_iam_role" "ec2_scheduler_lambda" {
  name = "Ec2SchedulerLambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ec2_scheduler-lambda"
    Environment = "dev"
    Terraform   = "true"
  }
}

# Policy for Lambda ec2_scheduler
resource "aws_iam_role_policy" "ec2_scheduler_lambda_policy" {
  name   = "ec2_scheduler_lambda_policy"
  role   = aws_iam_role.ec2_scheduler_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:eu-central-1:29xxxxxxxxxxx7:parameter/ec2/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
  })
}


# IAM Role for Lambda rds_scheduler
resource "aws_iam_role" "rds_scheduler_lambda" {
  name = "RDSSchedulerLambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "rds_scheduler-lambda"
    Environment = "dev"
    Terraform   = "true"
  }
}

# Policy for Lambda rds_scheduler
resource "aws_iam_role_policy" "rds_scheduler_lambda_policy" {
  name   = "rds_scheduler_lambda_policy"
  role   = aws_iam_role.rds_scheduler_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            "Effect": "Allow",
            "Action": [
                "rds:DescribeDBInstances",
                "rds:StartDBInstance",
                "rds:StopDBInstance",
                "rds:DescribeDBEngineVersions"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:eu-west-1:29xxxxxxxxxxx7:parameter/rds/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
  })
}



# IAM Role for Lambda eks_scheduler
resource "aws_iam_role" "eks_scheduler_lambda" {
  name = "eksSchedulerLambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "eks_scheduler-lambda"
    Environment = "dev"
    Terraform   = "true"
  }
}

# Policy for Lambda eks_scheduler
resource "aws_iam_role_policy" "eks_scheduler_lambda_policy" {
  name   = "eks_scheduler_lambda_policy"
  role   = aws_iam_role.eks_scheduler_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            "Effect": "Allow",
            "Action": [
                "eks:ListNodegroups",
                "eks:DescribeNodegroup",
                "eks:UpdateNodegroupConfig"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:eu-west-1:29xxxxxxxxxxx7:parameter/eks/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
  })
}


# IAM Role for Lambda asg_scheduler
resource "aws_iam_role" "asg_scheduler_lambda" {
  name = "asgSchedulerLambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "asg_scheduler-lambda"
    Environment = "dev"
    Terraform   = "true"
  }
}

# Policy for Lambda asg_scheduler eu-west-1:29xxxxxxxxxxx7
resource "aws_iam_role_policy" "asg_scheduler_lambda_policy" {
  name   = "asg_scheduler_lambda_policy"
  role   = aws_iam_role.asg_scheduler_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:UpdateAutoScalingGroup",
                "eks:ListNodegroups",
                "eks:DescribeNodegroup",
                "eks:UpdateNodegroupConfig",
                "ssm:GetParameter",
                "ssm:PutParameter"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters",
                "ssm:GetParametersByPath",
                "ssm:PutParameter"
            ],
            "Resource": "arn:aws:ssm:eu-west-1:29xxxxxxxxxxx7:parameter/asg/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters",
                "ssm:GetParametersByPath",
                "ssm:PutParameter"
            ],
            "Resource": "arn:aws:ssm:eu-west-1:29xxxxxxxxxxx7:parameter/eks/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:eu-west-1:29xxxxxxxxxxx7:log-group:/aws/lambda/*:*:*"
        }
    ]
  })
}

resource "aws_iam_role" "lambda_scheduler_role" {
  name = "lambda-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Політики для доступу до різних сервісів
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_scheduler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "lambda-custom-permissions"
  role = aws_iam_role.lambda_scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:*",
          "rds:*",
          "cloudwatch:*",
          "sns:*",
          "ec2:*"
        ]
        Resource = "*"
      }
    ]
  })
}