resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "project_bucket" {
  bucket = "${local.project}-nachodele-${random_id.suffix.hex}"

  tags = merge(local.common_tags, var.additional_tags)
}

resource "aws_s3_bucket_website_configuration" "static_website" {
  bucket = aws_s3_bucket.project_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}


resource "aws_s3_object" "website_files" {
  for_each    = local.website_files
  bucket      = aws_s3_bucket.project_bucket.bucket
  key         = each.key
  source      = each.value
  etag        = filemd5(each.value)
  content_type = "text/html"
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.project_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.project_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.project_bucket.arn}/*"
      }
    ]
  })
}

