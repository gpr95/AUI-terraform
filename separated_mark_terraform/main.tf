variable "desired_count" {
  default = 2
}

provider "aws" {}

terraform {
  backend "s3" {
    bucket = "cf-templates-5r11wlvvdn8u-eu-central-1"
    key    = "terraform/mark-terraform.tfstate"
    region = "eu-central-1"
  }
}

data "aws_ecs_task_definition" "familyDataMark" {
  task_definition = "${aws_ecs_task_definition.taskdefMark.family}"
}

resource "aws_ecs_service" "serviceMark" {
  name          = "serviceMark"
  cluster       = "AUI-projekt1-ECSCluster-1I9TQ5HLRGFX7"
  desired_count = "${var.desired_count}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.targetGroupMark.arn}"
    container_name   = "Hash"
    container_port   = 8008
  }

  task_definition = "${aws_ecs_task_definition.taskdefMark.family}:${max("${aws_ecs_task_definition.taskdefMark.revision}", "${data.aws_ecs_task_definition.familyDataMark.revision}")}"

  depends_on = [
    "aws_ecs_task_definition.taskdefMark",
  ]
}

resource "aws_ecs_task_definition" "taskdefMark" {
  family                = "mark"
  container_definitions = "${template_file.tempalteMark.rendered}"
}

resource "template_file" "tempalteMark" {
  template = "${file("templates/ecsTaskDefinitionMark.json")}"

  vars {
    uuid = "${uuid()}"
  }
}

resource "aws_lb_target_group" "targetGroupMark" {
  name     = "AUI-hasher"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-00e51206864b7c9b7"

  health_check {
    path = "/md5/test"
  }
}

resource "aws_lb_target_group_attachment" "lbAttachmentMark" {
  target_group_arn = "${aws_lb_target_group.targetGroupMark.arn}"
  target_id        = "i-093b30c1f762bb743"
  port             = 80
}

####

output "TargetGroupNamMark" {
  value = "${aws_lb_target_group.targetGroupMark.name}"
}
