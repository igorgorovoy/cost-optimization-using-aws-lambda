#!/bin/bash
# Install required packages
yum update -y
yum install -y python3 python3-pip awscli
pip3 install psycopg2-binary slack_sdk boto3 requests

# Create Python script with improved error handling and logging
cat << 'EOF' > /home/ec2-user/script.py
import boto3
import psycopg2
import json
import requests
import sys
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_secret(secret_name):
    try:
        client = boto3.client("secretsmanager", region_name="eu-west-1")
        response = client.get_secret_value(SecretId=secret_name)
        return response["SecretString"]
    except Exception as e:
        logger.error(f"Failed to get secret {secret_name}: {e}")
        raise

def send_slack_webhook(webhook_url, message):
    try:
        resp = requests.post(webhook_url, json={"text": message})
        resp.raise_for_status()
    except Exception as e:
        logger.error(f"Slack Webhook Error: {e}")
        raise

def main():
    try:
        logger.info("Starting database maintenance task")
        
        db_creds_str = get_secret("my/dbCredentials")
        db_creds = json.loads(db_creds_str)
        
        slack_webhook_str = get_secret("my/slackWebhook")
        slack_webhook = json.loads(slack_webhook_str)["webhook"]

        conn = None
        cur = None
        
        try:
            logger.info("Connecting to database")
            conn = psycopg2.connect(
                host=db_creds["host"],
                user=db_creds["username"],
                password=db_creds["password"],
                dbname=db_creds["dbname"],
                port=db_creds["port"]
            )
            conn.autocommit = True
            cur = conn.cursor()

            logger.info("Executing VACUUM FULL")
            cur.execute("VACUUM FULL;")
            
            send_slack_webhook(slack_webhook, "SQL operations completed successfully!")
            logger.info("Task completed successfully")

        finally:
            if cur:
                cur.close()
            if conn:
                conn.close()

    except Exception as e:
        error_message = f"Error during execution: {str(e)}"
        logger.error(error_message)
        send_slack_webhook(slack_webhook, error_message)
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

# Execute the Python script
python3 /home/ec2-user/script.py

# Self-terminate instance after completion
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region eu-west-1