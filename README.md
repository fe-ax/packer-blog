# packer-blog

Run this Terraform config to configure the IAM role for packer. This will create a file named `packer.pkrvar.hcl` in the `packer/` directory.

## Usage the Terraform config

The Terraform module uses your `~/.aws/credentials` file to connect to AWS.

```bash
# Using default AWS profile 'default'
tf apply

or

# Using a different AWS profile
tf apply -var 'aws_profile=other-profile-than-default'
```

## Using the Packer config

