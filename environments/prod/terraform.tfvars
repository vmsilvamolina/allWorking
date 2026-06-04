environment  = "prod"
cluster_name = "ecs-cluster-prod"
vpc_name     = "main-vpc-prod"

azs                        = ["us-east-1a", "us-east-1b"]
vpc_cidr_block             = "10.2.0.0/16"
public_subnet_cidr_blocks  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidr_blocks = ["10.2.3.0/24", "10.2.4.0/24"]

app_name          = "web-app-prod"
container_port    = 8080
app_cpu           = 1024
app_memory        = 2048
app_desired_count = 2
