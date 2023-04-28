#!/bin/bash

# Check if the script was called with 3 arguments
if [ $# -ne 3 ]; then
  echo "Usage: $0 <arg1> <arg2> <arg3>"
  exit 1
fi


# Lambda creation
aws lambda create-function \
  --function-name parking-lot-lambda \
  --runtime python3.10 \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://$1


# Print the arguments

echo "The arguments are: $1, $2, and $3"
