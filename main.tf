module "network" {
  source            = "./Modules/network"
  vpc_cidr          = "10.0.0.0/16"
  pubsubCIDRblocks  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  privsubCIDRblocks = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  azs               = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

module "balancer" {
  source         = "./Modules/balancer"
  privsuballid   = module.network.privsubid
  vpc_id         = module.network.vpc_id
  listenport     = 80
  listenprotocol = "HTTP"
  ASGid          = module.ec2.ASGid
}

module "ec2" {
  source        = "./Modules/ec2"
  instance_type = "t2.micro"
  tags          = "ExampleAppServerInstance"
  pubsg_name    = module.network.pubsg_name
  listedAZs     = module.network.listedAZs
  sg_id         = module.network.privSG_id
  tag           = "webserver"
  targetARN     = module.balancer.targetARN
  key_name      = var.key_name
  ami_id        = "ami-09d3b3274b6c5d4aa"
}

module "autoscale_group" {
  source = "cloudposse/ec2-autoscale-group/aws"

  namespace   = var.namespace
  stage       = var.stage
  environment = var.environment
  name        = var.name

  image_id                    = "ami-09d3b3274b6c5d4aa"
  instance_type               = "t2.micro"
  security_group_ids          = module.network.privSG_id
  subnet_ids                  = module.network.privsubid
  health_check_type           = "EC2"
  min_size                    = 2
  max_size                    = 5
  wait_for_capacity_timeout   = "5m"
  associate_public_ip_address = true
  user_data_base64            = filebase64("${path.cwd}/script.sh")
}  