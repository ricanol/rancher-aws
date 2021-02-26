## Create VPC prod
resource "aws_vpc" "vpc_prod" {
  cidr_block           = var.vpcCIDRblockProd
  instance_tenancy     = var.instanceTenancy 
  enable_dns_support   = var.dnsSupport 
  enable_dns_hostnames = var.dnsHostNames
tags = {
    Name = "VPC ${var.company} PROD"
}
}

## Create VPC HML
resource "aws_vpc" "vpc_hml" {
  cidr_block           = var.vpcCIDRblockHml
  instance_tenancy     = var.instanceTenancy 
  enable_dns_support   = var.dnsSupport 
  enable_dns_hostnames = var.dnsHostNames
tags = {
    Name = "VPC ${var.company} HML"
}
}

#==========================================================

data "aws_availability_zones" "available" {
  state = "available"
}

## Create SUBNET PUBLIC PROD
resource "aws_subnet" "Public_subnet_prod_A" {
  vpc_id                  = aws_vpc.vpc_prod.id
  cidr_block              = var.publicsCIDRblockprodA
  map_public_ip_on_launch = var.mapPublicIP 
  availability_zone       = data.aws_availability_zones.available.names[0]
tags = {
   Name = "Public subnet prod A"
}

depends_on = [aws_vpc.vpc_prod]

}

## Create SUBNET PRIVATE PROD
resource "aws_subnet" "Private_subnet_prod_B" {
  vpc_id                  = aws_vpc.vpc_prod.id
  cidr_block              = var.privateCIDRblockprodB
  map_public_ip_on_launch = var.mapPrivateIP 
  availability_zone       = data.aws_availability_zones.available.names[1]
tags = {
   Name = "Public subnet prod B"
}

depends_on = [aws_vpc.vpc_prod]

}

## Create SUBNET PUBLIC HML
resource "aws_subnet" "Public_subnet_hml_C" {
  vpc_id                  = aws_vpc.vpc_hml.id
  cidr_block              = var.publicsCIDRblockdevC
  map_public_ip_on_launch = var.mapPublicIP 
  availability_zone       = data.aws_availability_zones.available.names[2]
tags = {
   Name = "Public subnet dev C"
}

depends_on = [aws_vpc.vpc_hml]

}

## Create SUBNET PRIVATE HML
resource "aws_subnet" "Private_subnet_hml_D" {
  vpc_id                  = aws_vpc.vpc_hml.id
  cidr_block              = var.privateCIDRblockprodD
  map_public_ip_on_launch = var.mapPrivateIP 
  availability_zone       = data.aws_availability_zones.available.names[3]
tags = {
   Name = "Public subnet dev D"
}

depends_on = [aws_vpc.vpc_hml]
}
#==========================================================

## Create Internet gateway PROD
resource "aws_internet_gateway" "IGW_PROD" {
 vpc_id = aws_vpc.vpc_prod.id
 tags = {
        Name = "Internet gateway ${var.company} PROD"
}
} 

## Create Internet gateway HML
resource "aws_internet_gateway" "IGW_HML" {
 vpc_id = aws_vpc.vpc_hml.id
 tags = {
        Name = "Internet gateway ${var.company} HML"
}
} 
#==========================================================

## Create Route table PROD
resource "aws_route_table" "Public_RT_PROD" {
 vpc_id = aws_vpc.vpc_prod.id
 tags = {
        Name = "Public Route table PROD"
}
}

## Create Route table PROD
resource "aws_route_table" "Private_RT_PROD" {
 vpc_id = aws_vpc.vpc_prod.id
 tags = {
        Name = "Private Route table PROD"
}
}

## Create Route table HML
resource "aws_route_table" "Public_RT_HML" {
 vpc_id = aws_vpc.vpc_hml.id
 tags = {
        Name = "Public Route table HML"
}
}

## Create Route table DEV
resource "aws_route_table" "Private_RT_HML" {
 vpc_id = aws_vpc.vpc_hml.id
 tags = {
        Name = "Private Route table HML"
}
}
#==========================================================

## Create Route to internet PROD A public
resource "aws_route" "internet_access_prod_A" {
  route_table_id         = aws_route_table.Public_RT_PROD.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW_PROD.id
}

## Create Route to internet PROD B private
resource "aws_route" "internet_access_prod_B" {
  route_table_id         = aws_route_table.Private_RT_PROD.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW_PROD.id
}

## Create Route to internet DEV C public
resource "aws_route" "internet_access_dev_C" {
  route_table_id         = aws_route_table.Public_RT_HML.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW_HML.id
}

## Create Route to internet DEV D private
resource "aws_route" "internet_access_dev_D" {
  route_table_id         = aws_route_table.Private_RT_HML.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW_HML.id
}
#==========================================================

## Associate route table to subnet PROD-A
resource "aws_route_table_association" "Public_association_prod_A" {
  subnet_id      = aws_subnet.Public_subnet_prod_A.id
  route_table_id = aws_route_table.Public_RT_PROD.id
}

## Associate route table to subnet PROD-B
resource "aws_route_table_association" "Private_association_prod_B" {
  subnet_id      = aws_subnet.Private_subnet_prod_B.id
  route_table_id = aws_route_table.Private_RT_PROD.id
}

## Associate route table to subnet DEV-C
resource "aws_route_table_association" "Public_association_hml_C" {
  subnet_id      = aws_subnet.Public_subnet_hml_C.id
  route_table_id = aws_route_table.Public_RT_HML.id
}

## Associate route table to subnet DEV-D
resource "aws_route_table_association" "Private_association_hml_D" {
  subnet_id      = aws_subnet.Private_subnet_hml_D.id
  route_table_id = aws_route_table.Private_RT_HML.id
}