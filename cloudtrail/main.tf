# Cloudtrail monitors all events in all regions within the root account and stores them in an S3 bucket
module "cloudtrail" {
  source                        = "git::https://github.com/cloudposse/terraform-aws-cloudtrail.git?ref=master"

  name                          = "${var.project_name}_cloudtrail"
  namespace                     = "${var.organization_name}"
  s3_bucket_name                = "${module.cloudtrail_s3_bucket.bucket_id}"
  stage                         = "${var.stage}"

  enable_log_file_validation    = "true"
  enable_logging                = "true"
  include_global_service_events = "true"
  is_multi_region_trail         = "true"
}

module "cloudtrail_s3_bucket" {
  source    = "git::https://github.com/cloudposse/terraform-aws-cloudtrail-s3-bucket.git?ref=master"

  name      = "${var.project_name}_logs"
  namespace = "${var.organization_name}"
  stage     = "${var.stage}"

  force_destroy = "false"
  region    = "${var.region}"
}

# Enables SNS notifications to a topic on every log file delivered to the S3 bucket if log_export is enabled
resource "aws_sns_topic" "project_logs" {
  count = "${var.log_export}"
  name = "${var.project_name}_logs"

  policy = <<POLICY
{
    "Version":"2012-10-17",
    "Statement":[{
        "Effect": "Allow",
        "Principal": {"AWS":"*"},
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:*:*:s3-event-notification-topic",
        "Condition":{
            "ArnLike":{"aws:SourceArn":"${module.cloudtrail_s3_bucket.bucket_arn}"}
        }
    }]
}
POLICY
}

resource "aws_s3_bucket_notification" "log_bucket_notification" {
  count = "${var.log_export}"
  bucket = "${module.cloudtrail_s3_bucket.bucket_id}"

  topic {
    topic_arn     = "${aws_sns_topic.project_logs.arn}"
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}
