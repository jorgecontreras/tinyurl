import json
import boto3
import uuid

# Initialize DynamoDB client
dynamodb = boto3.client('dynamodb')
table_name = 'URLMapping'  # Replace with your DynamoDB table name

def lambda_handler(event, context):
    try:
        # Parse the request body
        body = json.loads(event.get('body', '{}'))
        original_url = body.get('OriginalURL')
        
        if not original_url:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'OriginalURL is required'})
            }
        
        # Generate a unique short URL identifier (6-character UUID)
        short_url = str(uuid.uuid4())[:6]
        
        # Store the mapping in DynamoDB
        dynamodb.put_item(
            TableName=table_name,
            Item={
                'ShortURL': {'S': short_url},
                'OriginalURL': {'S': original_url}
            }
        )
        
        # Return the short URL
        return {
            'statusCode': 200,
            'body': json.dumps({'ShortURL': short_url})
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal server error', 'error': str(e)})
        }
