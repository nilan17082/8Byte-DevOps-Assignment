# 1. Database Subnet Group (Tells AWS to put the DB in our private network)
resource "aws_db_subnet_group" "default" {
  name       = "eightbyte-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "eightbyte-db-subnet-group"
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
  
  # FIX 1: Uses the randomly generated password from Secrets Manager
  password               = random_password.db.result 
  
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db_sg.id] # Attached to the Database Security Guard
  
  publicly_accessible    = false # Blocks the public internet from reaching it

  # ==========================================
  # FIX 2: Automated Backup & Maintenance Strategy
  # ==========================================
  # Satisfies the Part 4 Backup Strategy requirement with explicit policies
  backup_retention_period = 7                     # Retain automated backups for 7 days
  backup_window           = "03:00-04:00"         # Daily backup window (UTC)
  maintenance_window      = "Mon:04:00-Mon:05:00" # Weekly maintenance window (UTC)
  
  # For a production environment, this would be set to 'false' with a 'final_snapshot_identifier'.
  # It is set to 'true' here strictly to allow clean teardown of the assignment environment.
  skip_final_snapshot     = true 

  tags = {
    Name = "8byte-rds-postgres"
  }
}