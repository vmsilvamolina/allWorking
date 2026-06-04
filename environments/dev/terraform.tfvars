environment  = "dev"
cluster_name = "ecs-cluster-dev"
vpc_name     = "main-vpc-dev"

azs                        = ["us-east-1a", "us-east-1b"]
private_subnet_cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"]

app_name          = "web-app-dev"
container_port    = 8080
app_cpu           = 256
app_memory        = 512
app_desired_count = 1
