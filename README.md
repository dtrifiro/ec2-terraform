# EC2 instance on AWS

## Howto

### Volume Module

```bash
terraform init

terraform plan
terraform apply
```

To customize the deployment, create a `.tfvars` file:

```bash
cat > vars.tfvars <<EOF
region='us-east-1'
instance_name="dtrifiro-gpu"

EOF
```

Then run `plan`, `apply`:

```bash
terraform plan -var-file=vars.tfvars
terraform apply -var-file=vars.tfvars
```

See [instance/variables.tf](/instance/variables.tf) for a list of allowed values

## Resources

- [inputs documentation](https://github.com/terraform-aws-modules/terraform-aws-ec2-instance?tab=readme-ov-file#inputs)
- [examples](https://github.com/terraform-aws-modules/terraform-aws-ec2-instance/tree/master/examples)

## TODO

- support for hibernation?
- use spot pricing?
- aws ec2 builder?
