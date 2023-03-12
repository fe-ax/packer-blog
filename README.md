# packer-blog

Run this Terraform config to configure the IAM role for packer. This will create a file named `packer.pkrvar.hcl` in the `packer/` directory.

The files have explainations inside them.

## Usage the Terraform config

The Terraform module uses your `~/.aws/credentials` file to connect to AWS.

```bash
# Using default AWS profile 'default'
cd terraform
terraform apply

or

# Using a different AWS profile
cd terraform
terraform apply -var 'aws_profile=other-profile-than-default'
```

## Using the Packer config

```bash
cd packer

# To test your build without creating the AMI
packer build -var-file=packer.pkrvar.hcl aws-k3s.pkr.hcl

# To create the AMI
packer build -var 'skip_create_ami=false' -var-file=packer.pkrvar.hcl aws-k3s.pkr.hcl
```