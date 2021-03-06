terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  
  
  
   backend "s3" {
    bucket = "tfs3-syed"
    key    = "states/windows11.tfstate"
    region = "us-west-1"
    dynamodb_table = "tfs3-syed"
  }

}

provider "aws" {
  region = "us-west-1"
}


resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_network_interface" "foo" {
  subnet_id   = aws_subnet.mtc_public_subnet[0].id
  private_ips = ["172.16.11.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "foo" {
  ami           = "ami-04a50faf2a2ec1901" # us-west-1
  instance_type = "t2.micro"
  
  
   user_data = <<EOF
<powershell>
$admin = [adsi]("WinNT://./administrator, user")
$admin.PSBase.Invoke("SetPassword", "myTempPassword123!")
Invoke-Expression ((New-Object System.Net.Webclient).DownloadString('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'))
</powershell>
EOF

  network_interface {
    network_interface_id = aws_network_interface.foo.id
    device_index         = 0
  }
  
 
  
tags = {
    Name = "mtc-main01"
  }
}

resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_vpc_igw"
  }
}

resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "mtc-public"
  }
}


resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mtc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mtc_internet_gateway.id
}

resource "aws_default_route_table" "mtc_private_rt" {
  default_route_table_id = aws_vpc.my_vpc.default_route_table_id

  tags = {
    Name = "mtc_private"
  }
}


resource "aws_subnet" "mtc_public_subnet" {
  count                   = 1
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "172.16.11.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-1a"

  tags = {
    Name = "mtc_public_${count.index + 1}"
  }
}


output "hostnames" {
value = { for i in aws_instance.foo[*]: i.public_ip =>  "               hostname=${ i.tags.Name} "  }
}
