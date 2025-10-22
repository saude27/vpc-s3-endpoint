
---

### 5️⃣ **scripts/s3-test.sh**

Your testing script (run inside the EC2 instance via Session Manager):

```bash
#!/bin/bash
# Script: s3-test.sh
# Purpose: Verify private EC2 access to S3 using VPC Gateway Endpoint

set -e

BUCKET="s3-bucket-connect"

echo "=== Starting S3 connectivity test ==="

echo "Checking AWS CLI..."
if ! command -v aws &>/dev/null; then
  echo "Installing AWS CLI..."
  yum install -y awscli
fi

echo "Listing contents of S3 bucket: $BUCKET"
aws s3 ls s3://$BUCKET

echo "Creating a test file..."
echo "Hello from private EC2 via VPC Endpoint!" > /tmp/test.txt

echo "Uploading test file to S3..."
aws s3 cp /tmp/test.txt s3://$BUCKET/

echo "Verifying upload..."
aws s3 ls s3://$BUCKET | grep test.txt && echo "✅ Upload successful!"

echo "=== Test Completed Successfully ==="
