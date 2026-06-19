//Create A security group calling var.jenkins_security_gatekeeper_sg_name for Jenkins pipeline execution role
resource "aws_security_group" "jenkins_security_gatekeeper_sg" {
  name        = var.jenkins_sg_name
  description = "Security group for Jenkins pipeline execution role"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "Jenkins Security Gatekeeper SG"
    Environment = "DevSecOps"
  }
}

//Allow inbound SSH traffic on port 22 SSH (Port 22) and set the source type to My IP
resource "aws_security_group_rule" "allow_ssh_from_my_ip" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.admin_ip]
  security_group_id = aws_security_group.jenkins_security_gatekeeper_sg.id
}

//Allow Custopm TCP traffic on port 8080 and set the source type to My IP
resource "aws_security_group_rule" "allow_tcp_8080_from_my_ip" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = [var.admin_ip]
  security_group_id = aws_security_group.jenkins_security_gatekeeper_sg.id
}

//Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins_security_gatekeeper_sg.id


}