# Request certificate https to domain
resource "aws_acm_certificate" "prod" {
  domain_name       = join(".", ["*", var.domain])
  validation_method = "DNS"
}

resource "aws_route53_record" "prod" {
  for_each = {
    for dvo in aws_acm_certificate.prod.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id

  depends_on = [aws_acm_certificate.prod]
}

#validadte certificate
resource "aws_acm_certificate_validation" "prod" {
  certificate_arn         = aws_acm_certificate.prod.arn
  validation_record_fqdns = [var.domain]
  depends_on = [aws_route53_record.prod]
}
#=====================================================================

# Create SG to open port 80 and 443 LB prod
resource "aws_security_group" "lb_sg_web_prod" {
  name        = "LB-k8s-prod-web-sg"
  vpc_id      = aws_vpc.vpc_prod.id
  description = "load Balance to k8s prod - web ports 80 and 443"

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-LB-k8s-PROD"
  }
}

# Create SG to open port 80 and 443 LB hml
resource "aws_security_group" "lb_sg_web_hml" {
  name        = "LB-k8s-hml-web-sg"
  vpc_id      = aws_vpc.vpc_hml.id
  description = "load Balance to k8s hml - web ports 80 and 443"

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-LB-k8s-HML"
  }
}
#=====================================================================
# Create bucket s3 to logs elb-prod
resource "aws_s3_bucket" "bucket_log_prod_elb" {
  bucket = "${var.company}-elb-logs-k8s-prod"
  acl    = "private"

  tags = {
    Name        = "${var.company}-elb-logs-k8s-prod"
    Environment = "PROD"
  }
}

# create Application Load balance prod
resource "aws_elb" "prod" {
  name               = "k8s-prod-elb"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]

  access_logs {
    bucket        = aws_s3_bucket.bucket_log_prod_elb.bucket
    bucket_prefix = "k8s-prod-elb-log-"
    interval      = 60
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = aws_acm_certificate_validation.prod.certificate_arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = [aws_spot_instance_request.k8s_cluster_prod[0].id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "k8s-prod-elb"
  }
  depends_on              = [aws_s3_bucket.bucket_log_prod_elb,
                             aws_spot_instance_request.k8s_cluster_prod[0]
                            ]
}

resource "aws_lb_target_group" "prod" {
  name        = "prod-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc_prod.id

  health_check {
    path     = "/"
    protocol = "HTTPS"
    matcher  = "404" #traefik return 200 to ELB, but ELB he understood 404.
  }
}

resource "aws_lb_listener" "prod" {
  load_balancer_arn = aws_elb.prod.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.prod.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod.arn
  }
}





# Create bucket s3 to logs elb-hml
resource "aws_s3_bucket" "bucket_log_elb_hml" {
  bucket = "${var.company}-elb-logs-k8s-hml"
  acl    = "private"

  tags = {
    Name        = "${var.company}-elb-logs-k8s-hml"
    Environment = "HML"
  }
}

# create Application Load balance hml
resource "aws_elb" "hml" {
  name               = "k8s-hml-elb"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]

  access_logs {
    bucket        = aws_s3_bucket.bucket_log_elb_hml.bucket
    bucket_prefix = "k8s-hml-elb-log-"
    interval      = 60
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = aws_acm_certificate_validation.prod.certificate_arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = [aws_spot_instance_request.k8s_cluster_hml[0].id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "k8s-hml-elb"
  }
  depends_on              = [aws_s3_bucket.bucket_log_elb_hml,
                             aws_spot_instance_request.k8s_cluster_hml[0]
                            ]
}

resource "aws_lb_target_group" "hml" {
  name        = "hml-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc_hml.id

  health_check {
    path     = "/"
    protocol = "HTTPS"
    matcher  = "404" #traefik return 200 to ELB, but ELB he understood 404.
  }
}

resource "aws_lb_listener" "hml" {
  load_balancer_arn = aws_elb.prod.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.prod.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod.arn
  }
}


#=====================================================================
# Create Route53 to ELB
# get id elb prod
data "aws_elb_hosted_zone_id" "prod" {}

## Create wild-card to cluster prod
resource "aws_route53_record" "dns_wild_card_prod" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name = join(".", ["*", "prod" , "rancher", var.domain])
  type = "CNAME"

  alias {
    name                   = aws_elb.prod.dns_name
    zone_id                = data.aws_elb_hosted_zone_id.prod.id
    evaluate_target_health = true
  }
  depends_on               = [aws_elb.prod]
}

# get id elb hml
data "aws_elb_hosted_zone_id" "hml" {}

## Create wild-card to cluster hml
resource "aws_route53_record" "dns_wild_card_hml" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name = join(".", ["*", "hml" , "rancher", var.domain])
  type = "CNAME"

  alias {
    name                   = aws_elb.hml.dns_name
    zone_id                = data.aws_elb_hosted_zone_id.hml.id
    evaluate_target_health = true
  }
  depends_on               = [aws_elb.hml]
}






#- Criar load balance
#    - Application load balance http/https
#    - name: rancher-prod
#    - scheme: internet-facing
#    - ipv4
#    - listerns: http/https
#    - vpc: default (prod)
#    - enable zone (us-east-1a e us-esat-1b)
#    - choose certificate ACM
#    - depends_on [certificate manager name]
#    - security policy - default
#    - security group LB
#    - configure routing - define target group:
#        - tg-rancher-prod
#        - instance
#        - protocol: HTTP
#        - port 80
#        - Advance health check settings:
#            - sucess code: 404

#    depends_on = create spot instance, LB, certificate



#- apontar o DNS do LB para o Route53 no wite card de prod e dev
#    type: alias
#    destination: LB-name