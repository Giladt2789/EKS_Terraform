# Security group for public subnet
resource "aws_security_group" "public_sg" {
  name   = "${var.project}-Public-sg"
  vpc_id = aws_vpc.EKS.id
  #ingress
  ingress {
    description       = "sg_ingress_public_443"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  ingress {
    description       = "sg_ingress_public_80"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  egress {
    description       = "sg_egress_public"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-Public-sg"
  }
}

# Security group for data plane
resource "aws_security_group" "data_plane_sg" {
  name   = "${var.project}-Worker-sg"
  vpc_id = aws_vpc.EKS.id

  tags = {
    Name = "${var.project}-Worker-sg"
  }

  # Security group traffic rules
  ingress {
    description       = "Allow nodes to communicate with each other"
    from_port         = 0
    to_port           = 65535
    protocol          = "tcp"
    cidr_blocks       = flatten([cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 0), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 1), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 2), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 3)])
  }

  ingress {
    description       = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
    from_port         = 1025
    to_port           = 65535
    protocol          = "tcp"
    cidr_blocks       = flatten([cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 2), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 3)])
  }

  egress {
    description       = "node_outbound"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }
}

# Security group for control plane
resource "aws_security_group" "control_plane_sg" {
  name   = "${var.project}-ControlPlane-sg"
  vpc_id = aws_vpc.EKS.id

  tags = {
    Name = "${var.project}-ControlPlane-sg"
  }

  ingress {
    description       = "control_plane_inbound"
    from_port         = 0
    to_port           = 65535
    protocol          = "tcp"
    cidr_blocks       = flatten([cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 0), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 1), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 2), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 3)])
  }

  egress {
    description       = "control_plane_outbound" 
    from_port         = 0
    to_port           = 65535
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }
}

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project}-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.EKS.id

  tags = {
    Name = "${var.project}-cluster-sg"
  }

  ingress {
    description              = "Allow worker nodes to communicate with the cluster API Server"
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
  }

  egress {
    description              = "Allow cluster API Server to communicate with the worker nodes"
    from_port                = 1024
    to_port                  = 65535
    protocol                 = "tcp"
  }
}

# EKS Node Security Group
resource "aws_security_group" "eks_nodes" {
  name        = "${var.project}-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.EKS.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description              = "Allow nodes to communicate with each other"
    from_port                = 0
    to_port                  = 65535
    protocol                 = "-1"
  }

  ingress {
    description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
    from_port                = 1025
    to_port                  = 65535
    protocol                 = "tcp"
  }

  tags = {
    Name                                           = "${var.project}-node-sg"
    "kubernetes.io/cluster/${var.project}-cluster" = "owned"
  }
}