# AWS Setup

## VPC & Subnet

| Layer           | Subnet CIDR   | AZ  | Purpose            |
| --------------- | ------------- | --- | ------------------ |
| Public          | 10.10.1.0/24  | AZ1 | Bastion / NAT      |
| Public          | 10.10.2.0/24  | AZ2 | HA                 |
| Private-Compute | 10.10.10.0/24 | AZ1 | GPU nodes          |
| Private-Compute | 10.10.11.0/24 | AZ2 | GPU nodes          |
| Private-Control | 10.10.20.0/24 | AZ1 | Kubernetes / SLURM |
| Private-Control | 10.10.21.0/24 | AZ2 | HA                 |
| Storage         | 10.10.30.0/24 | AZ1 | FSx Lustre         |
| Storage         | 10.10.31.0/24 | AZ2 | Storage            |

## Command to create bucket & DynamoDB Table

```bash
# S3 bucket (private with security settings)
aws s3 mb s3://adn-ai-platform-terraform-state --region ap-southeast-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket adn-ai-platform-terraform-state \
  --versioning-configuration Status=Enabled

# Block all public access
aws s3api put-public-access-block \
  --bucket adn-ai-platform-terraform-state \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket adn-ai-platform-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }
    ]
  }'

# DynamoDB table for state locking
aws dynamodb create-table \
  --table-name adn-ai-platform-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1
```
