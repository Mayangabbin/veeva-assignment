![Production Architecture](images/architecture.png)
this diagram shows the architecture of my Veeva-assignment app.

### Architecture Explained:

**Amazon Route 53-** routes user requests to CloudFront CDN using a DNS record.
Amazon Cognito – manages authentication and authorization and handles user sign-up, sign-in, and access control for the application.
Amazon Cloudfront-  a CDN that delivers the application’s front-end content using edge locations for low latency and high availability.
Amazon API Gateway – manages API requests, routing them to the backend API pods and handling authentication, authorization, and rate limiting.
ALB – an Amazon Load Balancer connected to public subnets in both AZ's for distributing traffic to front-end pods.

The infrastructure includes two Availability Zones for high availability and disaster recovery.  
In each AZ, there is:  
- a public subnet for the ALB  
- a private subnet for the EKS node group  
- a private subnet for RDS


For the EKS cluster, I have chosen to use a node group instead of Fargate for greater flexibility, including node auto-scaling and control over the underlying infrastructure.

The EKS node group has auto-scaling enabled, with a minimum of 2 nodes and a maximum of 5 nodes, allowing the cluster to adjust capacity based on workload demands. (Values may be adjusted after reviewing cluster metrics)

The EKS cluster has three deployments:  
- Front End  
- Backend  
- Real-time Data Streaming

Each deployment has an HPA enabled for autoscaling, configured with a CPU utilization target of 60%, and a minimum of 2 pods and a maximum of 10 pods. (to be adjusted after reviewing metrics.)

For the database, I have chosen Amazon RDS with Multi-AZ deployment for high availability and disaster recovery.

For real-time data streaming, the pods connect to Amazon Kinesis for ingesting and processing streaming data.

Alerts are configured in CloudWatch.

Monitoring Metrics:

EKS Pods & Nodes:
- CPU utilization
- Memory utilization
- Disk I/O
- Network I/O
- Pod restarts
- failed scheduling

API & Real-time Processing:
- Request latency
- throughput
- Error rates

Kinesis:
- Queue depth
- Processing latency
- Error rates

RDS:
- CPU, Memory, Disk usage
- Connections count
- Read/Write latency
- Replication lag 

ALB:
- Request coount
- Latency
- Error rates
- Healthy vs. Unhealthy targets

CloudFront:
- Cache hit/miss ratio
- Latency
- Error rates

Alerting Strategy:
for cpu utilization- 80% for 5 minutes will triger an alert

for memory usage- 75% will trigger an alert

API error rate > threshold → alert

DB replication lag > threshold → alert




