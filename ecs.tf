resource "aws_ecs_cluster" "ecs"{
 name = "node_app_cluster"
}

resource "aws_ecs_service" "service" {
  name            = "app_service"
  cluster         = aws_ecs_cluster.ecs.arn
  task_definition = aws_ecs_task_definition.td.arn
  desired_count   = 1
  launch_type = "FARGATE"
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {

    subnets = [aws_subnet.sub1.id, aws_subnet.sub2.id]
    security_groups = [aws_security_group.sec_group.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_task_definition" "td" {
  family = "app"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "762126917299.dkr.ecr.us-east-1.amazonaws.com/node_repo"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }

      ]
    }
  ])

  cpu       = 256
  memory    = 512
  network_mode = "awsvpc"
  task_role_arn = "${aws_iam_role.Execution_Role.arn}"
  execution_role_arn = "${aws_iam_role.Execution_Role.arn}"

}

data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    sid = "EcsTaskPolicy"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]

    resources = [
      "*" # you could limit this to only the ECR repo you want
    ]
  }
  statement {

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = [
      "*"
    ]
  }

  statement {

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*"
    ]
  }

}

resource "aws_iam_role" "Execution_Role" {
  name               = "ecsExecution-1"
  assume_role_policy = data.aws_iam_policy_document.role_policy.json

  inline_policy {
    name   = "EcsTaskExecutionPolicy"
    policy = data.aws_iam_policy_document.ecs_task_policy.json
  }
}

data "aws_iam_policy_document" "role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
