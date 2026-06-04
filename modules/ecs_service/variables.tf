variable "app_name" {
  description = "Nombre de la aplicación"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
}

variable "cluster_id" {
  description = "ID del cluster ECS"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de subnets públicas (para el ALB)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs de subnets privadas (para las tareas)"
  type        = list(string)
}

variable "image_url" {
  description = "URL completa de la imagen de contenedor"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN del IAM role para la ejecución de tareas ECS"
  type        = string
}

variable "container_port" {
  description = "Puerto que expone el contenedor"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU para la tarea Fargate (en unidades)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memoria para la tarea Fargate (en MB)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Número de tareas deseadas"
  type        = number
  default     = 1
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}
