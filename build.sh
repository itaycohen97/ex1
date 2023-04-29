#!/bin/bash

# Check if the script was called with 3 arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 <arg1 - lambda function / permission role / dynamodb name suffix>"
  exit 1
fi

echo "DB_NAME = \"parking-lot-db-$1\"" > parking_lot_code/db_name.py
 
if [ ! -d "parking_lot_code" ]; then
    echo "parking_lot_code directory not found!"
    exit 1
fi

ROLE_NAME=parking-lot-lambda-role-$1
FUNCTION_NAME=parking-lot-lambda-$1

echo "Building zip archive from file parking_lot_code.py"

ZIP_PROMT=$(zip -r parking_lot_code.zip parking_lot_code)

echo "Building zip archive SUCCEDED! Building a security role for the lambda function"

# Create a new role
ROLE_ARN=$(aws iam create-role \
    --region eu-west-1 \
    --role-name $ROLE_NAME \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'\
    --no-cli-page \
    --query Role.Arn)

# Give Permisssions to new policy for read/write to dynamodb
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess \
    

# Give Permisssions to new policy for basic lambda permissions
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \


echo "Security role CREATED! now deploying lambda function"
sleep 5


# Lambda function creation
FUNC_ARN=$(aws lambda create-function \
  --region eu-west-1 \
  --function-name $FUNCTION_NAME \
  --runtime python3.10 \
  --handler parking_lot_code.lambda_handler \
  --zip-file fileb://parking_lot_code.zip \
  --no-cli-pager \
  --role $(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text) \
  --query FunctionArn
)

# echo $FUNC_ARN

echo "Lambda function DEPLOYED! Now adding Function URL and Permissions"


# Add a Function URL
FUNC_URL=$(aws lambda create-function-url-config \
    --function-name $FUNCTION_NAME \
    --no-cli-pager\
    --auth-type NONE \
    --query FunctionUrl)


TMP=$(aws lambda add-permission \
--function-name $FUNCTION_NAME \
--action lambda:InvokeFunctionUrl \
--statement-id FunctionURLAllowPublicAccess \
--principal "*" \
--function-url-auth-type NONE)

echo "Almost done, now creating a Dynamodb for the lambda function"

TMP=$(aws dynamodb create-table \
--table-name parking-lot-db-$1 \
--attribute-definitions AttributeName=id,AttributeType=S \
--key-schema AttributeName=id,KeyType=HASH \
--provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5)


echo "Finished! Now deployed on:"
echo ${FUNC_URL//\"}



exit 0

