#Step:1 Create the iam role 

data "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

resource "aws_iam_role" "test_role" {
  name = "lambda-s3-read"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    tag-key = "lambda-s3-read"
  }
}

data "aws_iam_policy_document" "cloudwatch_policy" {

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

data "template_file" "S3policyDocumentForLambda" {

  template = file("./templates/s3_policy.json.tpl")

  vars = {
    bucket_arn =data.aws_s3_bucket.this.arn
  }
}

resource "aws_iam_policy" "s3policygetaccess" {
  name = "s3policygetaccess"
  description       ="Policy for s3 list and get object"
  policy =data.template_file.S3policyDocumentForLambda.rendered
}

# #Step 2 Create iam policy to grant a specific bucket access 
# resource "aws_iam_policy" "elitech_bucket_policy" {
#   name = "elitech_bucket_policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "VisualEditor0"
#         Effect = "Allow"
#         Action = [
#           "s3:PutObject",
#           "s3:GetObject",
#           "s3:ListBucket",
#           "s3:DeleteObject"
#         ]
#         # Resource = [
#         #   data.aws_s3_bucket.this.arn,
#         #   "${data.aws_s3_bucket.this.arn}/*"
#         # ]
#       }
#     ]
#   })
# }

# #Step:3 Attach the iam s3 bucket policy to the iam lambda role 
# resource "aws_iam_role_policy_attachment" "s3_policy_attatch" {
#   role       = aws_iam_role.test_role.name
#   policy_arn = aws_iam_policy.elitech_bucket_policy.arn
# }

#Step:3 Attach the iam s3 bucket policy to the iam lambda role 
resource "aws_iam_role_policy_attachment" "s3_policy_attatch" {
  role       = aws_iam_role.test_role.name
  policy_arn = aws_iam_policy.s3policygetaccess.arn
}


resource "aws_iam_role_policy" "cloudwatch_policy_attatch" {
  name = "lambdacloudwatchPolicy"
  role       = aws_iam_role.test_role.name
  policy = data.aws_iam_policy_document.cloudwatch_policy.json
}

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "s3-read-get-object"
  description   = "This function read an s3 bucket and print the content"
  create_role   = false
  lambda_role   = aws_iam_role.test_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  timeout       = "15"

  source_path = "./functions"

  tags = {
    Name = "s3-read-get-object"
  }
}
