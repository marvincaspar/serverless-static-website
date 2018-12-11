# Serverless static website

This is a terraform script to setup a serverless infrastructure for static website hosting on aws using S3, CloudFront, Route53 and Certificate Manager.

## Setup

First terraform must be installed:

```sh
# unix
sudo apt-get install unzip
wget https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip
unzip terraform_0.11.10_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# macOS
brew install terraform
```

### AWS account

Create an aws account and get the access and security key for the user. Then add the keys to the environment variables.

```sh
export TF_VAR_access_key="<your-access-key>"
export TF_VAR_secret_key="<your-secret-key>"
```

To have the variables always available, add the two lines to the `~/.bashrc` file and run `source ~/.bashrc` to reload the file.

Next set the preferred aws [region](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions) (default is eu-central-1)and the domain without a protocol and without www. in the `variables.tf` file.

### E-Mail

The domain verification for the SSL certificate is done via email. Make sure that you have access to at least one of the following e-mail accounts:

```
administrator@<your-domain>
hostmaster@<your-domain>
postmaster@<your-domain>
webmaster@<your-domain>
admin@<your-domain>
```

## Usage

After completing the setup section check the terraform script:

```sh
terraform plan
```

The output shows which actions terraform will perform. If this is ok, start the creation for the infrastructure.

```sh
terraform apply
```

While terraform creates all components, amazon will send an e-mail for the domain verification. Check your e-mails and verify the domain, otherwise terraform will run into a timeout after a few minutes.

## Rework

After terraform is complete there are a few manual steps.

### Setup nameserver

Login into the aws account, go to Route53 service and view the hosting zones. Select the new domain and find the nameserver from aws. Go to your domain provider and change the nameserver. This can take up to 48 hour until the new nameserver is set.

### Upload website

Go to the aws S3 service and select the bucket with the domainname. Upload the `index.html` and all required files for the website.

## Verification

If the nameserver change is completed the website is available for the given domain, with and without `www` prefix. The website also supports IPv4 and IPv6 and uses force redirect from http to https.

Check IPv6: http://ipv6-test.com/validate.php

Check SSL setting: https://www.ssllabs.com/ssltest/
