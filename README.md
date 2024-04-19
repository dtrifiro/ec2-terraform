# EC2 instance on AWS

## Howto

```bash
cd volume
terraform init
terraform plan
terraform apply

cd ../instance
vim main.tf # edit as needed
terraform init
terraform plan
terraform apply
```

## Resources

- [inputs documentation](https://github.com/terraform-aws-modules/terraform-aws-ec2-instance?tab=readme-ov-file#inputs)
- [examples](https://github.com/terraform-aws-modules/terraform-aws-ec2-instance/tree/master/examples)

## TODO

- support for hibernation?
- use spot pricing?
- aws ec2 builder?
