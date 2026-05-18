provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "default" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

locals {
  # us-east-1e lacks some instance types in the KodeKloud playground
  subnet_ids = [
    for s in data.aws_subnet.default : s.id
    if s.availability_zone != "us-east-1e"
  ]
}

# EKS service role — named to match the KodeKloud playground's iam:PassRole allow-list
resource "aws_iam_role" "eks_cluster" {
  name = "eksClusterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# IAM role for worker nodes — named to match the playground's iam:PassRole allow-list
resource "aws_iam_role" "eks_nodes" {
  name = "eksNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# SSH key pair for node access (guide names it "node-key-pair")
resource "tls_private_key" "nodes" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "nodes" {
  key_name   = "node-key-pair"
  public_key = tls_private_key.nodes.public_key_openssh
}

resource "local_sensitive_file" "node_private_key" {
  content         = tls_private_key.nodes.private_key_pem
  filename        = "${path.module}/node-key-pair.pem"
  file_permission = "0600"
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = local.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.cluster_endpoint_public_access
  }

  # CONFIG_MAP mode with bootstrap=true gives the cluster creator implicit system:masters.
  # The terraform-aws-modules/eks module hardcodes bootstrap=false so we use the resource directly.
  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  bootstrap_self_managed_addons = false

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  # Playground blocks eks:UpdateClusterConfig — ignore post-creation drift on access_config
  lifecycle {
    ignore_changes = [access_config]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# The playground IAM policy blocks direct autoscaling:CreateAutoScalingGroup calls that
# reference a caller-owned launch template. Routing through CloudFormation is the path
# the playground docs explicitly recommend and is not subject to that restriction.
resource "aws_cloudformation_stack" "eks_nodes" {
  name         = "eks-cluster-stack"
  template_url = "https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2022-12-23/amazon-eks-nodegroup.yaml"
  capabilities = ["CAPABILITY_IAM"]

  parameters = {
    ClusterName                         = aws_eks_cluster.this.name
    ClusterControlPlaneSecurityGroup    = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
    NodeGroupName                       = "eks-demo-node"
    NodeInstanceType                    = var.node_instance_type
    NodeAutoScalingGroupDesiredCapacity = tostring(var.node_desired_size)
    NodeAutoScalingGroupMinSize         = tostring(var.node_min_size)
    NodeAutoScalingGroupMaxSize         = tostring(var.node_max_size)
    NodeVolumeSize                      = tostring(var.node_disk_size)
    NodeVolumeType                      = "gp3"
    NodeImageIdSSMParam                 = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/image_id"
    KeyName                             = aws_key_pair.nodes.key_name
    VpcId                               = data.aws_vpc.default.id
    Subnets                             = join(",", local.subnet_ids)
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  depends_on = [aws_eks_cluster.this]
}

data "aws_instances" "nodes" {
  filter {
    name   = "tag:aws:cloudformation:stack-name"
    values = [aws_cloudformation_stack.eks_nodes.name]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
  depends_on = [aws_cloudformation_stack.eks_nodes]
}

module "k8s_apps" {
  source = "../modules/k8s-apps"

  service_type  = "NodePort"
  storage_class = "gp2"

  nginx_node_port        = 30080
  gitea_node_port        = 30300
  argocd_node_port_http  = 30880
  argocd_node_port_https = 30443
  jenkins_node_port_http = 30808

  gitea_admin_username = var.gitea_admin_username
  gitea_admin_password = var.gitea_admin_password
  gitea_admin_email    = var.gitea_admin_email

  # Any node IP works for the Gitea API; the Jenkins setup uses it to push manifests
  gitea_external_url = "http://${data.aws_instances.nodes.public_ips[0]}:30300"

  harbor_admin_password = var.harbor_admin_password
  harbor_external_url   = "http://${data.aws_instances.nodes.public_ips[0]}:30500"

  sonarqube_admin_password = var.sonarqube_admin_password
  sonarqube_external_url   = "http://${data.aws_instances.nodes.public_ips[0]}:30900"

  enable_devsecops_pipeline = var.enable_devsecops_pipeline

  providers = {
    sonarqube = sonarqube
  }

  depends_on = [null_resource.gp2_default]
}

# Open NodePort range to the specified CIDR so browser/kubectl can reach NodePort services
resource "aws_security_group_rule" "nodeport_access" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32768
  protocol          = "tcp"
  cidr_blocks       = [var.nodeport_access_cidr]
  security_group_id = aws_cloudformation_stack.eks_nodes.outputs["NodeSecurityGroup"]
  description       = "NodePort service access (nginx:30080, gitea:30300, argocd:30443/30880, jenkins:30808)"
}

# Allow kubectl access to the EKS API private endpoint from within the VPC
# (the cluster SG only allows traffic from nodes by default, not from this lab VM)
resource "aws_security_group_rule" "eks_api_vpc_access" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.default.cidr_block]
  security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description       = "Allow kubectl from anywhere in the VPC"
}

resource "local_file" "aws_auth" {
  filename = "${path.module}/aws-auth-cm.yaml"
  content  = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: aws-auth
      namespace: kube-system
    data:
      mapRoles: |
        - rolearn: ${aws_cloudformation_stack.eks_nodes.outputs["NodeInstanceRole"]}
          username: system:node:{{EC2PrivateDNSName}}
          groups:
            - system:bootstrappers
            - system:nodes
  YAML
}

resource "null_resource" "aws_auth_apply" {
  triggers = {
    configmap = local_file.aws_auth.content
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name} && kubectl apply --validate=false -f ${local_file.aws_auth.filename}"
  }

  depends_on = [aws_eks_cluster.this, aws_cloudformation_stack.eks_nodes, aws_security_group_rule.eks_api_vpc_access]
}

# The CloudFormation nodegroup template creates its own IAM role for the nodes.
# Attach policies to that role — not to eksNodeRole, which is unused at runtime.
resource "aws_iam_role_policy_attachment" "eks_cni_policy_cf" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = split("/", aws_cloudformation_stack.eks_nodes.outputs["NodeInstanceRole"])[1]
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = split("/", aws_cloudformation_stack.eks_nodes.outputs["NodeInstanceRole"])[1]
}

# bootstrap_self_managed_addons=false means EKS does not install vpc-cni, kube-proxy,
# or coredns automatically — they must be declared explicitly.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  depends_on = [aws_iam_role_policy_attachment.eks_cni_policy_cf, null_resource.aws_auth_apply]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"

  depends_on = [null_resource.aws_auth_apply]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"

  depends_on = [aws_eks_addon.vpc_cni]
}

# EKS 1.23+ routes kubernetes.io/aws-ebs PVC provisioning through the CSI driver,
# which is not installed by default and must be added as a managed add-on.
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "aws-ebs-csi-driver"

  depends_on = [aws_iam_role_policy_attachment.ebs_csi_driver_policy, aws_eks_addon.vpc_cni]

  # Playground IAM blocks eks:DeleteAddon — prevent Terraform from ever trying to destroy this.
  lifecycle {
    prevent_destroy = true
  }
}

# gp2 is not the default StorageClass on EKS — mark it so PVCs without an explicit
# storageClassName bind automatically. Uses local-exec instead of kubernetes_annotations
# because the EKS auth token (~15 min TTL) expires during the CloudFormation apply (~20 min).
resource "null_resource" "gp2_default" {
  provisioner "local-exec" {
    command = "kubectl patch storageclass gp2 -p '{\"metadata\":{\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'"
  }

  depends_on = [aws_eks_addon.ebs_csi_driver, null_resource.aws_auth_apply]
}

