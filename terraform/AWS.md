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

## Node Placement

### Create Key Pair

```bash
# create key pair (ensure local directory exists first)
aws ec2 create-key-pair \
  --region ap-southeast-1 \
  --key-name adnsg-aws-ai-platform \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/adnsg-aws-ai-platform.pem
chmod 400 ~/.ssh/adnsg-aws-ai-platform.pem
```

### SSH Access

All EC2 instances are launched with the `ssh_key_name` specified in `terraform.tfvars`. Be sure you've created an AWS key pair with that name in the target region (e.g. `ap-southeast-1`). You can connect using:

```bash
ssh -i ~/.ssh/adnsg-aws-ai-platform.pem ubuntu@<instance_public_ip>
```

| Component                | Subnet        |
| ------------------------ | ------------- |
| Bastion                  | 10.10.1.0/24  |
| SLURM Controller         | 10.10.20.0/24 |
| Kubernetes Control Plane | 10.10.20.0/24 |
| GPU Node 1               | 10.10.10.0/24 |
| GPU Node 2               | 10.10.11.0/24 |
| CPU Worker               | 10.10.10.0/24 |
| FSx Lustre               | 10.10.30.0/24 |

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
