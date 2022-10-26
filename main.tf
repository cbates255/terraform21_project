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
  asgid          = module.ec2.asgid
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
  privsubids    = module.network.privsubid
  albarn        = module.balancer.albarn
}