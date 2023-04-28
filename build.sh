#!/bin/bash

# Check if the script was called with 3 arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 <arg1 - python handler filw>"
  exit 1
fi

if [ ! -f $1 ]; then
    echo "File not found!"
    exit 1
fi

zip -r parking_lot_code.zip $1

# Lambda creation
aws lambda create-function \
  --function-name parking-lot-lambda \
  --runtime python3.10 \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://parking_lot_code.zip


# Add a Function URL
POSSIBLE_OUTPUT=$(aws lambda create-function-url-config \
    --function-name my-function \
    --auth-type NONE)


  echo "$POSSIBLE_OUTPUT   \n/n"

