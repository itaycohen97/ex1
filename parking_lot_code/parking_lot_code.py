import json, boto3, time, re
from parking_lot_code.db_name import DB_NAME


parking_lot_db = boto3.resource("dynamodb").Table(DB_NAME)


def lambda_handler(event, context):
    match event.get("rawPath", "/"):
        case "/entry":
            args = event.get("queryStringParameters", {})
            if "parkingLot" in args and "plate" in args:
                return_id = re.sub("[^0-9]", "",args["plate"]+args["parkingLot"])
                parking_lot_db.put_item(Item={"id":return_id, "license_plate":args["plate"], "parking_lot":args["parkingLot"], "enter_time":str(time.time())})
                return {
            'statusCode': 200,
            'body': return_id
                        }
            else:
                
                return {
                'statusCode': 200,
                'body': "missing arguments"
                            }
                
        case "/exit":
            args = event.get("queryStringParameters", {})
            if args.get("ticketId", None):
                parking_item = parking_lot_db.get_item(Key={"id": args.get("ticketId", {})}).get("Item", None)
                if parking_item:
                    minutes_parked = (time.time() - float(parking_item["enter_time"])) // 60
                    minutes_parked += 1 if not minutes_parked else 0
                    units_to_pay = minutes_parked//15
                    if minutes_parked % 15 != 0:
                        units_to_pay +=1
                    price_to_pay = units_to_pay * 2.5
                    parking_lot_db.delete_item(Key={"id": args.get("ticketId", None)})
                    return {
                'statusCode': 200,
                'body': json.dumps({"minutes_parked": minutes_parked, "price_to_pay":price_to_pay, "license_plate": parking_item["license_plate"], "parking_lot": parking_item["parking_lot"]})
                            }
                            
                else:
                                        return {
                'statusCode': 200,
                'body': "Wrong Ticket ID!"
                            }

        case "/":
                                                          return {
                'statusCode': 200,
                'body': "usage - \nPOST /entry?plate=123-123-123&parkingLot=382\nPOST /exit?ticketId=123123123382"
                            }

        case _:
            return {
        'statusCode': 400,
                    }
    return {
        'statusCode': 401,
                    }

