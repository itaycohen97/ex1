#!/bin/bash

# Check if the script was called with 3 arguments
if [ $# -ne 2 ]; then
  echo "Usage: $0 <arg1 - python handler file> <arg2 - naming prefix>"
  exit 1
fi

if [ ! -f $1 ]; then
    echo "File not found!"
    exit 1
fi


zip -r parking_lot_code.zip $1

# Create role
ARN=$(aws iam create-role \
    --role-name parking-lot-lambda-role-$2 \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "",
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'\
    --query Role.Arn)

# Give Permisssions to new policy for read/write to dynamodb
aws iam attach-role-policy \
    --role-name parking-lot-lambda-role-$2 \
    --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess \
    
# Give Permisssions to new policy for AWSLambdaRole
aws iam attach-role-policy \
    --role-name parking-lot-lambda-role-$2 \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaRole \

# Lambda creation
aws lambda create-function \
  --function-name parking-lot-lambda-$2 \
  --runtime python3.10 \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://parking_lot_code.zip \
  --role ${ARN//\"/}


# Add a Function URL
POSSIBLE_OUTPUT=$(aws lambda create-function-url-config \
    --function-name parking-lot-lambda-$2 \
    --auth-type NONE)

# Add permission URL
aws lambda add-permission \
    --function-name parking-lot-lambda-$2 \
    --principal "*" \
    --statement-id "InvokePermission" \
    --action lambda:InvokeFunction \


  echo "$POSSIBLE_OUTPUT"
  exit 0

