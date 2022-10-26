module "VPC" {
  source            = "./Modules/network"
  vpc_cidr          = "10.0.0.0/16"
  pubsubCIDRblocks  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  privsubCIDRblocks = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  azs               = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

module "LoadBalancer" {
  source         = "./Modules/balancer"
  pubsuballid    = module.VPC.pubsuballid
  vpc_id         = module.VPC.vpcid
  listenport     = 80
  listenprotocol = "HTTP"
  instanceid1    = module.Ec2.instanceid1
  instanceid2    = module.Ec2.instanceid2
  websecurityid  = module.VPC.websecurityid
}

module "ec2" {
  source        = "./Modules/ec2"
  image_ami     = "ami-026b57f3c383c2eec"
  instance_type = "t2.micro"
  tags          = "ExampleAppServerInstance"
  sg_id         = module.security_group.group_id
  profile       = module.IAM.instance_profile
  key_name      = "latestpair"
}