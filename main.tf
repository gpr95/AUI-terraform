variable "desired_count" {
  default = 2
}

provider "aws" {}

terraform {
  backend "s3" {
    bucket = "cf-templates-5r11wlvvdn8u-eu-central-1"
    key    = "terraform/terraform.tfstate"
    region = "eu-central-1"
  }
}

module "lambda_zip" {
  source = "./lambda"
}

########

data "aws_ecs_task_definition" "familyDataMich" {
  task_definition = "${aws_ecs_task_definition.taskdefMich.family}"
}

resource "aws_ecs_service" "serviceMich" {
  name          = "microJSService"
  cluster       = "AUI-projekt1-ECSCluster-1I9TQ5HLRGFX7"
  desired_count = "${var.desired_count}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.targetGroupMich.arn}"
    container_name   = "MicroJS"
    container_port   = 3000
  }

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.taskdefMich.family}:${max("${aws_ecs_task_definition.taskdefMich.revision}", "${data.aws_ecs_task_definition.familyDataMich.revision}")}"
}

resource "aws_ecs_task_definition" "taskdefMich" {
  family                = "js"
  container_definitions = "${file("templates/ecsTaskDefinitionMich.json")}"
}

resource "aws_lb_target_group" "targetGroupMich" {
  name     = "microJs"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-00e51206864b7c9b7"

  health_check {
    path = "/users"
  }
}

resource "aws_lb_target_group_attachment" "lbAttachmentMich" {
  target_group_arn = "${aws_lb_target_group.targetGroupMich.arn}"
  target_id        = "i-093b30c1f762bb743"
  port             = 80
}

####

data "aws_ecs_task_definition" "familyDataBak" {
  task_definition = "${aws_ecs_task_definition.taskdefBak.family}"
}

resource "aws_ecs_service" "serviceBak" {
  name          = "serviceBak"
  cluster       = "AUI-projekt1-ECSCluster-1I9TQ5HLRGFX7"
  desired_count = "${var.desired_count}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.targetGroupBak.arn}"
    container_name   = "DateTime"
    container_port   = 8080
  }

  task_definition = "${aws_ecs_task_definition.taskdefBak.family}:${max("${aws_ecs_task_definition.taskdefBak.revision}", "${data.aws_ecs_task_definition.familyDataBak.revision}")}"
}

resource "aws_ecs_task_definition" "taskdefBak" {
  family                = "bak"
  container_definitions = "${file("templates/ecsTaskDefinitionBak.json")}"
}

resource "aws_lb_target_group" "targetGroupBak" {
  name     = "datetimeService"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-00e51206864b7c9b7"

  health_check {
    path = "/date"
  }
}

resource "aws_lb_target_group_attachment" "lbAttachmentBak" {
  target_group_arn = "${aws_lb_target_group.targetGroupBak.arn}"
  target_id        = "i-093b30c1f762bb743"
  port             = 80
}

####

output "TargetGroupNameMich" {
  value = "${aws_lb_target_group.targetGroupMich.name}"
}

output "TargetGroupNameBak" {
  value = "${aws_lb_target_group.targetGroupBak.name}"
}
