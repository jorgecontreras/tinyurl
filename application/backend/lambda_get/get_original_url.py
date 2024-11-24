import json
import boto3

# Initialize DynamoDB client
dynamodb = boto3.client('dynamodb')
table_name = 'URLMapping'  # Replace with your DynamoDB table name

def lambda_handler(event, context):
    try:
        # Get the short URL from the path parameter
        short_url = event['pathParameters']['short_url']
        
        # Query DynamoDB for the original URL
        response = dynamodb.get_item(
            TableName=table_name,
            Key={'ShortURL': {'S': short_url}}
        )
        
        # Check if the item exists
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'message': 'Short URL not found'})
            }
        
        original_url = response['Item']['OriginalURL']['S']
        
        # Return a 302 redirect to the original URL
        return {
            'statusCode': 302,
            'headers': {
                'Location': original_url
            },
            'body': ''
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal server error', 'error': str(e)})
        }
