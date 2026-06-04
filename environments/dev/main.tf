data "aws_iam_role" "labrole" {
  name = "LabRole"
}

module "networking" {
  source             = "../../modules/networking"
  vpc_name           = var.vpc_name
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnet_cidr_blocks
  private_subnets    = var.private_subnet_cidr_blocks
  availability_zones = var.azs
  environment        = var.environment
}

module "cluster" {
  source       = "../../modules/ecs"
  cluster_name = var.cluster_name
  environment  = var.environment
}

module "ecr" {
  source      = "../../modules/ecr"
  name        = var.app_name
  environment = var.environment
}

module "app" {
  source             = "../../modules/ecs_service"
  app_name           = var.app_name
  environment        = var.environment
  cluster_id         = module.cluster.cluster_id
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  image_url          = "${module.ecr.repository_url}:latest"
  execution_role_arn = data.aws_iam_role.labrole.arn
  container_port     = var.container_port
  cpu                = var.app_cpu
  memory             = var.app_memory
  desired_count      = var.app_desired_count
  aws_region         = var.aws_region
}
