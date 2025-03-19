data "aws_iam_policy_document" "assume_read_only_role_policy" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = var.read_only_role_principals_type
      identifiers = var.read_only_role_principals
    }
  }
}


resource "aws_iam_role" "read_only_aws_role" {
  name                 = "${var.s3_bucket_names["logging"]}-s3-read-only"
  description          = "Read only role created for ${var.s3_bucket_names["logging"]}"
  path                 = "/"
  max_session_duration = "3600" # 1 hours
  assume_role_policy   = join("", data.aws_iam_policy_document.assume_read_only_role_policy.*.json)
  tags                 = merge(var.default_tags, var.tags, tomap({ Name = "${var.name}-s3-read-only.${var.environment}.01" }))
}

resource "aws_iam_role_policy_attachment" "policy_attach_arn" {
  for_each   = length(var.policy_arns) > 0 ? var.policy_arns : {}
  policy_arn = var.policy_arns[each.key]
  role       = aws_iam_role.read_only_aws_role.name
}

resource "aws_iam_role_policy_attachment" "policy_attach_policy" {
  for_each = length(var.new_policies) > 0 ? var.new_policies : {}

  policy_arn = aws_iam_policy.policy[each.key].arn
  role       = aws_iam_role.read_only_aws_role.name
}

resource "aws_iam_policy" "policy" {
  for_each    = length(var.new_policies) > 0 ? var.new_policies : {}
  name        = lookup(each.value, "new_policy_name", null)
  description = lookup(each.value, "new_policy_description", "Default description")
  path        = lookup(each.value, "new_policy_path", "/")
  policy      = lookup(each.value, "iam_role_policy", var.iam_role_policy_default)
}
