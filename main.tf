resource "aws_vpc" "vpc-nwl-346" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "vpc-nwl-346"
  }
}

resource "aws_subnet" "snet-public-nwl-346" {
  vpc_id            = aws_vpc.vpc-nwl-346.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "snet-public-nwl-346"
  }
}

resource "aws_subnet" "snet-private-nwl-346" {
  vpc_id            = aws_vpc.vpc-nwl-346.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "snet-private-nwl-346"
  }
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.vpc-nwl-346.id

  tags = {
    Name = "igw-nwl-346"
  }
}

resource "aws_route_table" "rt-public-nwl-346" {
  vpc_id = aws_vpc.vpc-nwl-346.id
  tags   = merge(var.tags, { Name = "rt-public-nwl-346" })

  route {
    gateway_id = aws_internet_gateway.internet_gw.id
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_route_table_association" "rt_association" {
  subnet_id      = aws_subnet.snet-public-nwl-346.id
  route_table_id = aws_route_table.rt-public-nwl-346.id
}

resource "aws_nat_gateway" "ngw-public-nwl-346" {
  tags              = merge(var.tags, { Name = "ngw-public-nwl-346" })
  subnet_id         = aws_subnet.snet-public-nwl-346.id
  connectivity_type = "public"
  allocation_id     = aws_eip.eip-public-nwl-346.id
}

resource "aws_route_table" "rt-private-nwl-346" {
  vpc_id = aws_vpc.vpc-nwl-346.id
  tags   = merge(var.tags, { Name = "rt-private-nwl-346" })

  route {
    gateway_id = aws_nat_gateway.ngw-public-nwl-346.id
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_route_table_association" "rt_association2" {
  subnet_id      = aws_subnet.snet-private-nwl-346.id
  route_table_id = aws_route_table.rt-private-nwl-346.id
}

resource "aws_eip" "eip-public-nwl-346" {
  tags = merge(var.tags, { Name = "eip-public-nwl-346" })
}

resource "aws_security_group" "sg-public-nwl-346" {
  vpc_id = aws_vpc.vpc-nwl-346.id
  tags   = merge(var.tags, { Name = "sg-public-nwl-346" })

  ingress {
    to_port     = 80
    protocol    = "tcp"
    from_port   = 80
    description = "Webserver Zugriff"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_instance" "ec2-instance-public-nwl-346" {
  user_data                   = <<-EOF
#!/bin/bash
# Update der Paketliste und Installation von Apache
sudo yum update -y
sudo yum install -y httpd

# Starten des Apache-Webservers Test
sudo systemctl start httpd

# Aktivieren des Apache-Webservers beim Systemstart
sudo systemctl enable httpd
            
# Erstellen der "index.html"-Datei
echo "<html><head><title>Hello World</title></head><body><h1>Hello World</h1><p>This is a simple webpage served by Apache.</p></body></html>" | sudo tee /var/www/html/index.html >/dev/null
EOF
  tags                        = merge(var.tags, { Name = "ec2-instance-public-nwl-346" })
  subnet_id                   = aws_subnet.snet-public-nwl-346.id
  key_name                    = aws_key_pair.key_pair-nwl-346.key_name
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  ami                         = "ami-00beae93a2d981137"

  security_groups = [
    aws_security_group.sg-public-nwl-346.id,
  ]

  vpc_security_group_ids = [
    aws_security_group.sg-public-nwl-346.id,
    aws_security_group.sg-public-nwl-346.id,
  ]
}

data "aws_key_pair" "key_pair-nwl-346" {
  tags     = merge(var.tags, {})
  key_name = "vockey"
}

