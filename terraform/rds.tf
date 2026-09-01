# 1. Database Subnet Group (Tells AWS to put the DB in our private network)
resource "aws_db_subnet_group" "default" {
  name       = "8byte-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "8byte-db-subnet-group"
  }
}

# 2. The PostgreSQL Database Instance
resource "aws_db_instance" "postgres" {
  identifier             = "app-8byte-postgres-db"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15.4" # A stable, reliable version
  instance_class         = var.db_instance_class # Uses your variables.tf file
  db_name                = "webappdb"
  username               = "dbadmin"
  
  # 🔐 FIX 1: Uses the randomly generated password from Secrets Manager
  password               = random_password.db.result 
  
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db_sg.id] # Attached to the Database Security Guard
  
  skip_final_snapshot    = true  # Makes it easy to delete later without getting stuck
  publicly_accessible    = false # Blocks the public internet from reaching it

  # 💾 FIX 2: Satisfies the Part 4 Backup Strategy requirement
  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  tags = {
    Name = "8byte-rds-postgres"
  }
}