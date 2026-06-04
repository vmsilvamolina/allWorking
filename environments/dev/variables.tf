variable "aws_region" {
  description = "Región para desplegar la infra"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de despliegue, por ejemplo: dev, staging, prod"
  type        = string
}

variable "vpc_cidr_block" {
  description = "El bloque CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  description = "Los bloques CIDR para las subredes publicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidr_blocks" {
  description = "Los bloques CIDR para las subredes privadas"
  type        = list(string)
}

variable "vpc_name" {
  description = "El nombre de la VPC"
  type        = string
}

variable "azs" {
  description = "Las zonas de disponibilidad para la VPC"
  type        = list(string)
}

variable "cluster_name" {
  description = "El nombre del cluster de ECS"
  type        = string
}

variable "app_name" {
  description = "Nombre de la aplicación web"
  type        = string
  default     = "web-app"
}

variable "container_port" {
  description = "Puerto que expone el contenedor"
  type        = number
  default     = 8080
}

variable "app_cpu" {
  description = "CPU para la tarea Fargate (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "app_memory" {
  description = "Memoria para la tarea Fargate en MB"
  type        = number
  default     = 512
}

variable "app_desired_count" {
  description = "Número de tareas deseadas"
  type        = number
  default     = 1
}
