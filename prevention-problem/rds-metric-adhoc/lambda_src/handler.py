import boto3
import base64

ec2_client = boto3.client('ec2')
def lambda_handler(event, context):

    user_data_script = r"""#!/bin/bash
    yum update -y

    yum install -y python python3-pip
    cd /home/ec2-user
    python -m venv venv
    . venv/bin/activate
    pip3 install psycopg2-binary slack_sdk boto3 requests


cat << 'EOF' > /home/ec2-user/script.py
import boto3
import psycopg2
import json
import requests
import sys
def get_secret(secret_name):
    client = boto3.client("secretsmanager", region_name="eu-central-1")
    response = client.get_secret_value(SecretId=secret_name)
    return response["SecretString"]
def main():
    slack_secret_str = get_secret("rdbms/slackWebhook-test")
    slack_webhook = json.loads(slack_secret_str)["webhook"]

    db_creds_str = get_secret("rdbms/dbCredentials-test")
    db_creds = json.loads(db_creds_str)
    conn = psycopg2.connect(
        host=db_creds["host"],
        user=db_creds["username"],
        password=db_creds["password"],
        dbname=db_creds["dbname"],
        port=db_creds["port"]
    )
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute('DROP TABLE IF EXISTS test_table;')
    requests.post(slack_webhook, json={"text": "SQL operations DROP TABLE IF EXISTS test_table;."})
    cur.execute('CREATE TABLE test_table (id SERIAL PRIMARY KEY, data VARCHAR(255));')
    requests.post(slack_webhook, json={"text": "SQL operations CREATE TABLE test_table (id SERIAL PRIMARY KEY, data VARCHAR(255));."})
    cur.execute('INSERT INTO test_table (data) VALUES (\'Hello, world!\');')
    requests.post(slack_webhook, json={"text": "SQL operations INSERT INTO test_table (data) VALUES (\'Hello, world!\');."})
    cur.execute("VACUUM FULL;")
    requests.post(slack_webhook, json={"text": "SQL operations VACUUM FULL;."})
    cur.close()
    conn.close()

    requests.post(slack_webhook, json={"text": "SQL operations completed successfully."})
if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        slack_secret_str = get_secret("rdbms/slackWebhook")
        slack_webhook = json.loads(slack_secret_str)["webhook"]
        requests.post(slack_webhook, json={"text": f"Error during SQL ops: {str(e)}"})
        sys.exit(1)
EOF
    chmod +x /home/ec2-user/script.py
    python3 /home/ec2-user/script.py

    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    
    echo "INSTANCE_ID : $INSTANCE_ID" 
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region eu-central-1
"""
    
    response = ec2_client.run_instances(
        ImageId='ami-0e54671bdf3c8ed8d',
        InstanceType='t3.micro',
        MinCount=1,
        MaxCount=1,
        IamInstanceProfile={
            'Name': 'adhock-ec2-instance-profile'  
        },
        SecurityGroupIds=['sg-00f8a0e8638670e03'],
        SubnetId='subnet-0b130f943fd7dc122',
        UserData=user_data_script,
        TagSpecifications=[{
            'ResourceType': 'instance',
            'Tags': [{'Key': 'Name', 'Value': 'rdbms-RDS-Task'}]
        }]
    )
    
    return {
        "statusCode": 200,
        "body": "EC2 instance launched successfully."
    }