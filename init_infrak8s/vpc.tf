# 1: Create VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "K8s-VPC"  # Capitalized to follow common naming conventions
  }
}

# 2: Create a Public Subnet in Availability Zone 1
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.k8s_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zones[0]
  # Consider adding tags for better organization (optional)
  tags = {
    Name = "Public-Subnet"
  }
}

# 3: Create a Private Subnet in Availability Zone 2 (Different Zone)
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.k8s_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = var.availability_zones[0]
  # Consider adding tags for better organization (optional)
  tags = {
    Name = "Private-Subnet"
  }
}

# 4: Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  # Consider adding tags for better organization (optional)
  tags = {
    Name = "K8s-IGW"
  }
}

resource "aws_eip" "my_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

# 5: Create a Route Table for the Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  # Consider adding tags for better organization (optional)
  tags = {
    Name = "Public-Route-Table"
  }
}

# 6: Associate the Public Subnet with the Public Route Table
resource "aws_route_table_association" "public_rt_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.k8s_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  # Consider adding tags for better organization (optional)
  tags = {
    Name = "Private-Route-Table"
  }
}

# Association de la table de routage avec le sous resau privé
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}


# # Mis en place des routes
# resource "aws_route" "private_nat_route" {
#   route_table_id         = aws_route_table.private_route_table.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.nat_gateway.id
# }



# 7: Create a Security Group with Appropriate Rules
resource "aws_security_group" "allow_tls" {
  name        = "allow-tls"  # Hyphens for readability
  description = "Allow TLS inbound and all outbound traffic"
  vpc_id      = aws_vpc.k8s_vpc.id

  tags = {
    Name = "Allow-TLS"
  }
}

resource "aws_security_group" "public_sg" {
  name        = "PublicSecurityGroup"
  description = "Security group for public subnet instances"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # remplacer x.x.x.x par votre adresse public. c-a-d celle de votre box internet
  }
  egress{ 
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]  # Autorise tout le trafic sortant
  }
}

resource "aws_security_group" "private_sg" {
  name        = "PrivateSecurityGroup"
  description = "Security group for private subnet instances"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.public_sg.id] # permet à la machine frontend d'acceder à celle du backend en SSH 
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    # Autoriser tout le trafic provenant du même groupe de sécurité
    cidr_blocks       = [aws_subnet.private_subnet.cidr_block]
  }

  egress{ 
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]  # Autorise tout le trafic sortant
  }
}




# 10 Ajout d'une ip public
resource "aws_eip" "ip_bastion" {
  count = 1 
  instance = "${aws_instance.bastion[count.index].id}"
  vpc      = true
}
