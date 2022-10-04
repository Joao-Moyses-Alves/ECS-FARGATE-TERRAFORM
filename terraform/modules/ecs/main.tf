###ECR###
resource "aws_ecr_repository" "ecr" {
  name                 = "${var.name}-ecr-${terraform.workspace}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    application = var.name
    environment = var.environment
  }

}


##CLuster###


resource "aws_ecs_cluster" "cluster" {
  name = "${var.name}-cluster-${terraform.workspace}"

  tags = {
    application = var.name
    environment = var.environment
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }
}




resource "aws_ecs_task_definition" "task" {
  container_definitions    = jsonencode([
  { 
     "essential": true,
     "image": "112353101766.dkr.ecr.us-east-1.amazonaws.com/${var.name}-ecr-${terraform.workspace}:latest",
     "name": "clicksign",
     "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": [],
        "options": {
          "awslogs-group": "/${var.name}/${terraform.workspace}",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "${var.name}"
        }
      },
     "portMappings": [      
       { 
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }       
     ],
     "executionRoleArn": "arn:aws:iam::112353101766:role/${var.name}-execution-role-${terraform.workspace}",
     "taskRoleArn": "arn:aws:iam::112353101766:role/${var.name}-task-role-${terraform.workspace}",
     "family": "${var.name}-task-dev",
     "networkMode": "awsvpc",

     "requiresCompatibilities": [ 
        "FARGATE" 
     ]
  }


  
])
  execution_role_arn       = "arn:aws:iam::112353101766:role/${var.name}-execution-role-${terraform.workspace}"
  task_role_arn            = "arn:aws:iam::112353101766:role/${var.name}-task-role-${terraform.workspace}"
  family                   = "${var.name}-task-${terraform.workspace}"
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]

  tags = {
    application = var.name
    environment = var.environment
  }

}


resource "aws_ecs_service" "service" {
  name                              = "${var.name}-service-${terraform.workspace}"
  cluster                           = "${var.name}-cluster-${terraform.workspace}"
  task_definition                   = "${var.name}-task-${terraform.workspace}"
  launch_type                       = "FARGATE"
  scheduling_strategy               = "REPLICA"
  desired_count                     = 1
  enable_execute_command            = true
  propagate_tags                    = "SERVICE"
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = [var.subnet_id1a, var.subnet_id1b]
    assign_public_ip = false
    security_groups  = [("${aws_security_group.internal.id}")]
  }


  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }



  load_balancer {
    target_group_arn = (aws_lb_target_group.target.id)
    container_name   = var.name
    container_port   = 80
  }


  tags = {
    application = var.name
    environment = var.environment
  }

}


##cloudwatch log group###


resource "aws_cloudwatch_log_group" "log" {
  name              = "/${var.name}-${terraform.workspace}"
  retention_in_days = 30

  tags = {
    application = var.name
    environment = var.environment
  }
}




#           >>> Criação de Application Load Balancer, Listeners e Target Group   <<< 




resource "aws_lb" "alb" {
  name                       = "${var.name}-alb-${terraform.workspace}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [("${aws_security_group.internet_facing.id}")]
  subnets                    = [var.subnet_id_pub1a, var.subnet_id_pub1b]
  enable_deletion_protection = false

  tags = {
    application = var.name
    environment = var.environment
  }

}



resource "aws_lb_target_group" "target" {
  name                   = "${var.name}-target-80-${terraform.workspace}"
  target_type            = "ip"
  port                   = 80
  protocol               = "HTTP"
  protocol_version       = "HTTP1"
  vpc_id                 = var.vpc_id
  connection_termination = false
  deregistration_delay   = "60"

  tags = {
    application = var.name
    environment = var.environment
  }

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }


  stickiness {
    cookie_duration = 86400
    enabled         = false
    type            = "lb_cookie"
  }


}





resource "aws_lb_listener" "listener" {

  load_balancer_arn = (aws_lb.alb.id)

  port = 80

  protocol = "HTTP"

  default_action {

    target_group_arn = (aws_lb_target_group.target.id)

    type = "forward"

  }

}






#                                          >>> security_groups   <<<



resource "aws_security_group" "internet_facing" {
  name        = "${var.name}-internt-facing-${terraform.workspace}"
  description = "Access from the internet to load balancer"
  vpc_id      = var.vpc_id

  tags = {
    application = var.name
    environment = var.environment
  }


  ingress {
    description = "Allow from anyone on port 80"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }


  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}



resource "aws_security_group" "internal" {
  name        = "${var.name}-internal-${terraform.workspace}"
  description = "Access from the internet to load balancer"
  vpc_id      = var.vpc_id

  tags = {
    application = var.name
    environment = var.environment
  }


  ingress {
    description     = "internal"
    security_groups = [("${aws_security_group.internet_facing.id}")]
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
  }

  ingress {
    description = "Allow access from load balancer"
    cidr_blocks = ["10.76.192.0/20"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }


  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}