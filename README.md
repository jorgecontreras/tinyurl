# AWS Serverless URL Shortener 🚀

A lightweight, serverless URL shortener application built on **AWS** using **Terraform** for infrastructure as code. This project demonstrates how to design and deploy a scalable and cost-effective URL shortening service leveraging AWS services like Lambda, DynamoDB, and API Gateway.

---

## Features
- **URL Shortening**: Convert long URLs into short, user-friendly URLs.
- **Redirection**: Retrieve and redirect users to the original URL using the shortened link.
- **Serverless Architecture**: Scalable, pay-as-you-go infrastructure with no servers to manage.
- **Infrastructure as Code (IaC)**: Fully automated deployment using Terraform.

---

## Architecture Overview

### **AWS Services Used**
1. **AWS Lambda**:
   - `CreateShortURL`: Handles URL shortening logic and stores data in DynamoDB.
   - `GetOriginalURL`: Handles redirection logic based on the short URL.
2. **Amazon DynamoDB**:
   - Stores mappings between short URLs and original URLs.
   - Designed to scale seamlessly.
3. **Amazon API Gateway**:
   - Exposes RESTful API endpoints for `POST` (shorten URL) and `GET` (retrieve original URL).
4. **Terraform**:
   - Defines and provisions all AWS resources in a reproducible manner.
## Prerequisites
- **AWS Account**: Required to deploy resources.
- **Terraform**: Install [Terraform](https://www.terraform.io/downloads) (v1.5+ recommended).
- **Python**: Install Python 3.9 or higher.
- **cURL**: For testing API endpoints.

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/jorgecontreras/tinyurl.git
cd tinyurl
```

### 2. Set Up Terraform

1. Navigate to the terraform/ directory:

```bash
cd terraform
```

2. Initialize Terraform:

```bash
terraform init
```

3. Apply the Terraform configuration:

```bash
terraform apply
```

> Note the API Gateway Invoke URL from the Terraform outputs.

### 3. Deploy Lambda Code

1. Package Lambda functions as ZIP files:

```bash
cd application/backend/lambda_create
zip create_short_url.zip create_short_url.py
```

2. Repeat for lambda_get.

## Usage

**POST** /shorten

Create a shortened URL

**Request:**

```bash
curl -X POST -H "Content-Type: application/json" \
-d '{"OriginalURL": "https://www.example.com"}' \
https://<api-gateway-id>.execute-api.<region>.amazonaws.com/dev/shorten
```

**Response:**

```bash
{
  "ShortURL": "abc123"
}
```

**GET** /{short_url}

Redirect to the original URL using the short URL.

**Request:**
```bash
curl -I https://<api-gateway-id>.execute-api.<region>.amazonaws.com/dev/abc123
```

**Response:**

302 Found with a Location header pointing to the original URL.

## Future Enhancements

- Add authentication using AWS Cognito.
- Implement expiration dates for short URLs.
- Build a frontend to make the application more user-friendly.