# EC2 instance on AWS

## Howto

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

### Creating an AMI (WIP)

In the standard setup, an EC2 instance is created and `user_data.sh` is run at startup, configuring the machine. If `user_data.sh` does not change often, it is convenient to create an AMI and use that to start the ec2 instance.

0. Create an instance as described above if it does not exist already.
1. Get the `instance_id`:

   ```bash
   instance_id="$(terraform show -json | jq -r '.values.outputs.instance_id.value')"
   ```

2. Create the AMI using the given instance id:

   ```bash
   cd ami && terraform apply -var="instance_id=${instance_id}" -var="name=my-custom-ami'
   ```

   **Warning:** Creating an AMI like this also takes a snapshot of the attached EBS instance and attaches a copy to each EC2 instance created with this AMI. This clashes with the `aws_volume_attachment` config in `main.tf`

3. Create a new instance:

   ```bash
   # Warning: as mentioned above, this might not entirely work as expected as the attached snapshot is not mounted properly as done in `user_data.sh`
   terraform apply -var=custom_ami=my-custom-ami
   ```

## Resources

- [inputs documentation](https://github.com/terraform-aws-modules/terraform-aws-ec2-instance?tab=readme-ov-file#inputs)
- [examples](https://github.com/terraform-aws-modules/terraform-aws-ec2-instance/tree/master/examples)

## TODO

- support for hibernation?
- use spot pricing?
- aws ec2 builder?
