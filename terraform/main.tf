# DynamoDB Table for URL Mapping
resource "aws_dynamodb_table" "url_mapping" {
  name         = "URLMapping"
  billing_mode = "PAY_PER_REQUEST" # On-demand capacity

  hash_key = "ShortURL" # Partition key

  attribute {
    name = "ShortURL"
    type = "S" # String
  }

  tags = {
    Environment = "Dev"
    Project     = "URL Shortener"
  }
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec_role" {
  name = "url_shortener_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for Lambda to Access DynamoDB
resource "aws_iam_policy" "lambda_policy" {
  name = "url_shortener_lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ],
        Resource = aws_dynamodb_table.url_mapping.arn
      }
    ]
  })
}

# Attach IAM Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda Function: CreateShortURL
resource "aws_lambda_function" "create_short_url" {
  filename         = "${path.module}/../application/backend/lambda_create/create_short_url.zip"
  function_name    = "CreateShortURL"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "create_short_url.lambda_handler"
  runtime          = "python3.9"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.url_mapping.name
    }
  }
}

# Lambda Function: GetOriginalURL
resource "aws_lambda_function" "get_original_url" {
  filename         = "${path.module}/../application/backend/lambda_get/get_original_url.zip"
  function_name    = "GetOriginalURL"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "get_original_url.lambda_handler"
  runtime          = "python3.9"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.url_mapping.name
    }
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "url_shortener_api" {
  name          = "URLShortenerAPI"
  protocol_type = "HTTP"
}

# API Gateway Integration: POST /shorten
resource "aws_apigatewayv2_integration" "create_url_integration" {
  api_id           = aws_apigatewayv2_api.url_shortener_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.create_short_url.arn
}

# API Gateway Integration: GET /{short_url}
resource "aws_apigatewayv2_integration" "get_url_integration" {
  api_id           = aws_apigatewayv2_api.url_shortener_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_original_url.arn
}

# API Gateway Route: POST /shorten
resource "aws_apigatewayv2_route" "create_url_route" {
  api_id    = aws_apigatewayv2_api.url_shortener_api.id
  route_key = "POST /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.create_url_integration.id}"
}

# API Gateway Route: GET /{short_url}
resource "aws_apigatewayv2_route" "get_url_route" {
  api_id    = aws_apigatewayv2_api.url_shortener_api.id
  route_key = "GET /{short_url}"
  target    = "integrations/${aws_apigatewayv2_integration.get_url_integration.id}"
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.url_shortener_api.id
  name        = "dev"
  auto_deploy = true
}

output "api_url" {
  value = aws_apigatewayv2_stage.api_stage.invoke_url
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.url_mapping.name
}

# Allow API Gateway to invoke the CreateShortURL Lambda
resource "aws_lambda_permission" "allow_apigateway_create" {
  statement_id  = "AllowExecutionFromAPIGatewayCreate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_short_url.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.url_shortener_api.execution_arn}/*"
}

# Allow API Gateway to invoke the GetOriginalURL Lambda
resource "aws_lambda_permission" "allow_apigateway_get" {
  statement_id  = "AllowExecutionFromAPIGatewayGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_original_url.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.url_shortener_api.execution_arn}/*"
}
