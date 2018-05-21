provider "aws" {}

terraform {
  backend "s3" {
    bucket = "cf-templates-5r11wlvvdn8u-eu-central-1"
    key    = "terraform/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "aws_ecs_task_definition" "familyData" {
  task_definition = "${aws_ecs_task_definition.taskdef.family}"
}

resource "aws_ecs_service" "microJsService" {
  name          = "microJSService"
  cluster       = "AUI-projekt1-ECSCluster-1I9TQ5HLRGFX7"
  desired_count = 1

  load_balancer {
    target_group_arn = "${aws_lb_target_group.microJSTargGroup.arn}"
    container_name   = "MicroJS"
    container_port   = 3000
  }

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.taskdef.family}:${max("${aws_ecs_task_definition.taskdef.revision}", "${data.aws_ecs_task_definition.familyData.revision}")}"
}

resource "aws_ecs_task_definition" "taskdef" {
  family                = "js"
  container_definitions = "${file("templates/ecsTaskDefinitionMich.json")}"
}

resource "aws_lb_target_group" "microJSTargGroup" {
  name     = "microJs"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-00e51206864b7c9b7"
}

resource "aws_lb_target_group_attachment" "mciroJSAttachment" {
  target_group_arn = "${aws_lb_target_group.microJSTargGroup.arn}"
  target_id        = "i-0125b6f7246aac0b4"
  port             = 80
}

data "aws_ecs_task_definition" "familyDataBak" {
  task_definition = "${aws_ecs_task_definition.taskdef.family}"
}

resource "aws_ecs_service" "dateTimeService" {
  name          = "dateTimeService"
  cluster       = "AUI-projekt1-ECSCluster-1I9TQ5HLRGFX7"
  desired_count = 1

  load_balancer {
    target_group_arn = "${aws_lb_target_group.dateTimeServiceGroup.arn}"
    container_name   = "DateTime"
    container_port   = 8080
  }

  task_definition = "${aws_ecs_task_definition.taskdefBak.family}:${max("${aws_ecs_task_definition.taskdefBak.revision}", "${data.aws_ecs_task_definition.familyDataBak.revision}")}"
}

resource "aws_ecs_task_definition" "taskdefBak" {
  family                = "bak"
  container_definitions = "${file("templates/ecsTaskDefinitionBak.json")}"
}

resource "aws_lb_target_group" "dateTimeServiceGroup" {
  name     = "datetimeService"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-00e51206864b7c9b7"
}

resource "aws_lb_target_group_attachment" "datetimeAttachment" {
  target_group_arn = "${aws_lb_target_group.dateTimeServiceGroup.arn}"
  target_id        = "i-0125b6f7246aac0b4"
  port             = 80
}

output "microJSTargetGroupName" {
  value = "${aws_lb_target_group.microJSTargGroup.name}"
}

output "datetimeTargetGroupName" {
  value = "${aws_lb_target_group.dateTimeServiceGroup.name}"
}
