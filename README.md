![Production Architecture](images/architecture.png)
this diagram shows the architecture of my Veeva-assignment app.

### Architecture Explained:

**Amazon Route 53-** routes user requests to CloudFront CDN using a DNS record.

**Amazon Cognito-** manages authentication and authorization and handles user sign-up, sign-in, and access control for the application.

**Amazon Cloudfront-** a CDN that delivers the application’s front-end content using edge locations for low latency and high availability.

**Amazon API Gateway-** manages API requests, routing them to the backend API pods and handling authentication, authorization, and rate limiting.

**ALB-** an Amazon Load Balancer connected to public subnets in both AZ's for distributing traffic to front-end pods.

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

**Monitoring Metrics & Alerting Strategy:**

*EKS Pods & Nodes:*
- CPU utilization. Warning alert at 70% for 5 min, Critical alert at 85% for 5 min.
- Memory utilization. Warning alert at 70%, Critical alert at 80%.
- Disk I/O.
- Network I/O.
- Pod restarts. warning alert at 3 Pod restarts in 10 mins evaluation period.
- failed scheduling. warning alert at FailedSchedueling events > 0 for 5 mins. 

*API :*
- Request latency. Warning alert at p95 > 500ms, Critical alert at p95 > 2s.
- throughput.
- Error rates. alert at 5xx > 1%

*Kinesis:*
- Queue depth. warning alert at IteratorAgeMilliseconds > 1 mins, Critical alert at IteratorAgeMilliseconds > 5 mins. 
- Processing latency
- Error rates. warning alert at 5xx > 1%, Critical at 5xx > 5%.

*RDS:*
- CPU utilization. Warning alert at 70% for 5 min, Critical alert at 80% for 5 min.
- Memory utilization. warning alert at Freeable memory < 1GB for 10 mins, Critical alert at freeable memory < 500MB for 10 mins.
- Disk usage. Warning alert at 20% free storage, Critical alert at 10% free storage.
- Connections count. Warning alert at 80% of max connections, Critical alert at 90%. 
- Read/Write latency. Warning alert at p95 > 100ms for 5 mins, Critical alert at p95 > 300ms for 5mins.
- Replication lag. Warning alert at ReplicaLag > 30–60s for 5 mins, Critical alert at ReplicaLag > 5mins for 5-10 mins

*ALB:*
- Request count.
- Latency. Warning alert at p95 > 500ms, Critical alert at p95 > 2s.
- Error rates. warning alert at 5xx > 1%, Critical alert at 5xx > 5%.
- Unhealthy targets. Critical Alert at Unhealthy targets > 0.

*CloudFront:*
- Cache hit/miss ratio. warning alert at cache hit ratio < 70%
- Latency. Warning alert at p95 > 200ms, Critical alert at p95 > 500ms.
- Error rates. warning alert at 5xx > 1%, Critical alert at 5xx > 5%.

| Metric           | Warning Threshold | Critical Threshold |
| ---------------- | ----------------- | ------------------ |
| Cache hit ratio  | < 70%             | -                  |
| Latency (p95)    | > 200ms           | > 500ms            |
| Error rate (5xx) | > 1%              | > 5%               |


thresholds are tuned after observing production baselines.


