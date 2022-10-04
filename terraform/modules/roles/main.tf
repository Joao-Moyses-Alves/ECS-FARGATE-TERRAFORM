resource "aws_iam_role" "exec" {
  name                = "${var.name}-execution-role-${terraform.workspace}"
  managed_policy_arns = [aws_iam_policy.policy_one.arn]
  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    application = "clicksign",
    environment = var.environment
  }
}



resource "aws_iam_policy" "policy_one" {
  name        = "${var.name}-secrets-${terraform.workspace}"
  description = "secret policy"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Condition": {
                "StringEquals": {
                    "ssm:ResourceTag/application": "clicksign",
                    "ssm:ResourceTag/environment": "${terraform.workspace}"
                }
            },
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": [
                "arn:aws:ssm:us-east-1:112353101766:parameter/*"
            ],
            "Effect": "Allow"
        },
        {
            "Condition": {
                "StringEquals": {
                    "secretsmanager:ResourceTag/application": "clicksign",
                    "secretsmanager:ResourceTag/environment": "${terraform.workspace}"
                }
            },
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "arn:aws:secretsmanager:us-east-1:112353101766:secret:*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": [
                "arn:aws:kms:us-east-1:112353101766:key/*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOT
}


resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_role" "task" {
  name                = "${var.name}-task-role-${terraform.workspace}"
  managed_policy_arns = [aws_iam_policy.policy_two.arn]
  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    application = "clicksign",
    environment = var.environment
  }
}


resource "aws_iam_policy" "policy_two" {
  name        = "${var.name}-exec-commands-${terraform.workspace}"
  description = "exec-commands"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOT
}