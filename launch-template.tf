resource "aws_launch_template" "app_template" {

  name_prefix = "app-template-"

  image_id = "ami-0152204c1a187337c"

  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
#!/bin/bash

dnf update -y
dnf install -y httpd

systemctl enable httpd
systemctl start httpd

echo "<h1>Hello from Auto Scaling EC2</h1>" > /var/www/html/index.html
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "App-Server"
    }
  }
}