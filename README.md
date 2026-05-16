# deploy-3tire-webapp-php-on-cloud
تمام! اتفضل الكل:

---

# SecureVault — Complete Deployment & AWS Integration Guide

> A secure file management web application built with PHP + MariaDB, deployed on AWS Elastic Beanstalk with S3, Lambda, SNS, and Cognito integration.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Deployment on Elastic Beanstalk](#3-deployment-on-elastic-beanstalk)
4. [Database Setup (MariaDB)](#4-database-setup-mariadb)
5. [AWS SDK & S3 Integration](#5-aws-sdk--s3-integration)
6. [SNS Setup](#6-sns-setup)
7. [Lambda Function](#7-lambda-function)
8. [VPC Gateway Endpoint](#8-vpc-gateway-endpoint)
9. [S3 Intelligent-Tiering](#9-s3-intelligent-tiering)
10. [Errors & Solutions](#10-errors--solutions)

---

## 1. Project Overview

SecureVault is a secure file management system that allows users to upload, manage, and share files within their departments. It supports three user roles:

| Role | Permissions |
|------|-------------|
| `user` | Upload files, view own files |
| `department_admin` | Manage department files |
| `super_admin` | Full control over all departments and users |

**Tech Stack:**
- Backend: PHP 8
- Database: MariaDB (local on EC2)
- Web Server: nginx + php-fpm
- Hosting: AWS Elastic Beanstalk (Amazon Linux 2023)
- Storage: AWS S3
- Notifications: AWS Lambda + SNS
- Auth (planned): AWS Cognito

---

## 2. Architecture

```
User (Browser)
      │
      ▼
SecureVault Web App (Elastic Beanstalk)
  - nginx + php-fpm
  - PHP 8
  - MariaDB (local)
  - upload.php
      │
      ├──► Save file locally (/var/app/current/uploads/)
      │
      └──► Upload to S3 (uploadscurevulat) + metadata
                │
                ▼
         S3 Event Notification (PUT)
                │
                ▼
         Lambda Function (securevualt_function)
          - Reads metadata (email, department, filename)
          - Publishes to SNS
                │
                ▼
         SNS Topic (securevualt-notification)
                │
                ▼
         Super Admin Email Notification
```

**S3 Buckets:**
- `uploadscurevulat` — files uploaded here first with metadata
- Safe bucket — for clean/approved files
- `unsafesecurevulat` — for unsafe/flagged files

---

## 3. Deployment on Elastic Beanstalk

The app was deployed on Elastic Beanstalk using Amazon Linux 2023. nginx and php-fpm are pre-configured by Elastic Beanstalk.

**Key config files:**
```
/etc/nginx/nginx.conf
/etc/nginx/conf.d/elasticbeanstalk/php.conf
```

**Increase file upload size limit in nginx.conf:**
```nginx
http {
    client_max_body_size 20M;
}
```

Then restart nginx:
```bash
systemctl restart nginx
```

---

## 4. Database Setup (MariaDB)

```bash
yum install -y mariadb105-server
systemctl start mariadb
systemctl enable mariadb
mysql_secure_installation
```

**Fix root authentication for PHP:**
```sql
ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('');
FLUSH PRIVILEGES;
```

---

## 5. AWS SDK & S3 Integration

**Install Composer:**
```bash
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
```

**Install AWS SDK:**
```bash
cd /var/app/current
composer require aws/aws-sdk-php
```

**S3 Upload code in upload.php:**
```php
try {
    require_once __DIR__ . '/vendor/autoload.php';
    $s3Client = new \Aws\S3\S3Client([
        'version' => 'latest',
        'region'  => 'us-east-1',
    ]);

    $deptName = $pdo->prepare('SELECT name FROM departments WHERE id = :id LIMIT 1');
    $deptName->execute(['id' => $departmentId]);
    $department = $deptName->fetch();

    $s3Client->putObject([
        'Bucket'     => 'uploadscurevulat',
        'Key'        => $storedName,
        'SourceFile' => $targetPath,
        'Metadata'   => [
            'uploaded-by'   => $user['email'],
            'department'    => $department['name'] ?? 'Unknown',
            'original-name' => $originalName,
        ],
    ]);
} catch (\Exception $e) {
    error_log('S3 Upload failed: ' . $e->getMessage());
}
```

---

## 6. SNS Setup

1. Go to **AWS Console → SNS → Create Topic** (Standard) → Name: `securevualt-notification`
2. Create Subscription → Protocol: Email → Endpoint: Super Admin email
3. Confirm subscription from inbox

---

## 7. Lambda Function

**Function code:**
```python
import boto3

s3 = boto3.client('s3')
sns = boto3.client('sns')

SNS_TOPIC_ARN = 'arn:aws:sns:us-east-1:YOUR_ACCOUNT_ID:securevualt-notification'

def lambda_handler(event, context):
    for record in event['Records']:
        source_bucket = record['s3']['bucket']['name']
        file_key = record['s3']['object']['key']

        response = s3.head_object(Bucket=source_bucket, Key=file_key)
        metadata = response.get('Metadata', {})
        uploaded_by = metadata.get('uploaded-by', 'Unknown')
        department = metadata.get('department', 'Unknown')
        original_name = metadata.get('original-name', file_key)

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject='New File Uploaded - SecureVault',
            Message=f'File: {original_name}\nUploaded by: {uploaded_by}\nDepartment: {department}'
        )

    return {'statusCode': 200}
```

**IAM Permissions:** Attach `AmazonS3FullAccess` and `AmazonSNSFullAccess` to the Lambda role.

**S3 Trigger:** S3 → uploadscurevulat → Properties → Event Notifications → PUT → Lambda.

---

## 8. VPC Gateway Endpoint

VPC → Endpoints → Create endpoint:
- Service: `com.amazonaws.us-east-1.s3` (Gateway)
- Route tables: Select all (private-route, public-subnet, public-route)

Free of charge — eliminates data transfer costs between EC2/Lambda and S3.

---

## 9. S3 Intelligent-Tiering

Configured on `uploadscurevulat` to automatically move files to cheaper tiers:

| Tier | Condition | Savings |
|------|-----------|---------|
| Frequent Access | Active files | Standard |
| Infrequent Access | 30 days unused | ~45% |
| Archive | 90 days unused | ~68% |
| Deep Archive | 180 days unused | ~95% |

---

## 10. Errors & Solutions

### nginx

| Error | Cause | Solution |
|-------|-------|----------|
| `directory index is forbidden` | PHP crash due to DB connection failure | Fix database connection |
| `413 Request Entity Too Large` | nginx default 1MB limit | Add `client_max_body_size 20M;` in nginx.conf |

### Database

| Error | Cause | Solution |
|-------|-------|----------|
| `SQLSTATE[HY000] [2002] Connection refused` | MariaDB not installed | `yum install -y mariadb105-server` |
| `SQLSTATE[HY000] [1698] Access denied` | unix_socket auth blocks PHP | `ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password` |

### PHP

| Error | Cause | Solution |
|-------|-------|----------|
| `vendor/autoload.php not found` | SDK installed in wrong directory | Run `composer require aws/aws-sdk-php` inside `/var/app/current/` |
| `PHP Parse error in upload.php line 91` | Bash command pasted inside PHP file | Rewrite file using `cat > upload.php << 'EOF'` |

### Lambda

| Error | Cause | Solution |
|-------|-------|----------|
| `Runtime.UserCodeSyntaxError line 33` | TopicArn missing quotes | Wrap ARN in single quotes |
| `403 Forbidden on HeadObject` | Lambda missing S3 permissions | Attach `AmazonS3FullAccess` to Lambda role |
| `404 Not Found on HeadObject` | Test used non-existent file key | Use real file key from S3 bucket |
