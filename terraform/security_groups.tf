# 1. Security Guard for the Load Balancer (Allows public internet to see the website)
resource "aws_security_group" "alb_sg" {
  name        = "8byte-alb-sg"
  description = "Allow web traffic from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Security Guard for the Application (Only allows the Load Balancer to talk to it)
resource "aws_security_group" "app_sg" {
  name        = "8byte-app-sg"
  description = "Allow traffic from load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = var.app_port # FIX: Uses your variables.tf file
    to_port         = var.app_port # FIX: Uses your variables.tf file
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # This points to the guard above!
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Security Guard for PostgreSQL Database (Only allows the Application to talk to it)
resource "aws_security_group" "db_sg" {
  name        = "8byte-db-sg"
  description = "Allow database traffic from application"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow PostgreSQL traffic from App"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id] # This points to the app guard!
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}