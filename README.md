# Cost Optimization and Incident Prevention with AWS Lambda Schedulers
[Article full text](https://community.aws/content/2tZjhWq9mOX2xw7dAW4DbpQ7zNk/aws-cost-optimization-using-lambda-functions-and-terraform)

## Introduction

This is draft of article for aws community blog.

In modern cloud infrastructure, cost optimization and proactive incident prevention are crucial for maintaining efficient operations. This document outlines our implementation of AWS Lambda-based scheduling and monitoring systems that help reduce costs and prevent potential issues before they impact production.

## Resource Scheduling System

Our infrastructure utilizes several specialized Lambda functions to manage different AWS resources:

### 1. ASG (Auto Scaling Group) Scheduler

The ASG scheduler manages compute resources based on time schedules:

```python
def lambda_handler(event, context):
"""
Manages Auto Scaling Groups based on schedule:
Working hours (9:00-18:00): Normal capacity
Off hours: Minimum capacity
Weekends: Zero capacity (for non-production)
"""
try:
asg_name = event.get('asg_name')
if is_weekend():
update_asg_capacity(asg_name, min=0, desired=0, max=0)
elif is_working_hours():
update_asg_capacity(asg_name, min=1, desired=2, max=4)
else:
update_asg_capacity(asg_name, min=1, desired=1, max=2)
except Exception as e:
logger.error(f"ASG scheduling failed: {str(e)}")
```

### 2. RDS (Relational Database Service) Maintenance Scheduler

The RDS scheduler handles database maintenance tasks:
```python
def lambda_handler(event, context):
"""
Manages RDS instances:
Stops development databases during off-hours
Maintains production databases 24/7
Schedules maintenance windows
"""
for instance in get_rds_instances():
if instance.tags.get('Environment') != 'production':
if is_off_hours():
stop_rds_instance(instance.id)
else:
start_rds_instance(instance.id)
```

### 3. EKS (Elastic Kubernetes Service) Scheduler

The EKS scheduler manages Kubernetes clusters:
```python
def lambda_handler(event, context):
"""
Manages EKS node groups:
Scales down during off-hours
Adjusts capacity based on workload patterns
"""
for nodegroup in list_nodegroups():
if should_scale_down(nodegroup):
update_nodegroup_size(nodegroup, desired=0)
else:
restore_nodegroup_capacity(nodegroup)
```




## Incident Prevention System

### CloudWatch Metrics Monitoring

Our system implements proactive monitoring of critical metrics:

1. **Database Metrics**
   - Storage space utilization
   - CPU usage
   - Connection count
   - IOPS utilization

2. **Application Metrics**
   - Response times
   - Error rates
   - Queue lengths
   - Memory usage

### Automated Prevention Actions

Example of automated response to metrics:

```python
def handle_metric_alarm(event, context):
"""
Responds to CloudWatch alarms:
Executes database maintenance (VACUUM)
Adjusts resource capacity
Sends notifications
"""
metric_name = event['detail']['metricName']
if metric_name == 'FreeStorageSpace':
execute_vacuum_maintenance()
elif metric_name == 'CPUUtilization':
scale_compute_resources()
```

### Slack Notifications

Our system sends notifications to Slack channels:  

```python
def handle_metric_alarm(event, context):

Responds to CloudWatch alarms:
Executes database maintenance (VACUUM)
Adjusts resource capacity
Sends notifications
```
## IAM Security Configuration

Each Lambda function has specific IAM roles with least-privilege access:

```hcl
EC2 Scheduler Role
resource "aws_iam_role" "ec2_scheduler_lambda" {
name = "Ec2SchedulerLambda"
# Permissions for EC2 management
}
RDS Scheduler Role
resource "aws_iam_role" "rds_scheduler_lambda" {
name = "RDSSchedulerLambda"
# Permissions for RDS management
}
EKS Scheduler Role
resource "aws_iam_role" "eks_scheduler_lambda" {
name = "eksSchedulerLambda"
# Permissions for EKS management
}
```

## Cost Optimization Features

1. **Automated Resource Management**
   - Scheduled start/stop of development resources
   - Capacity adjustment based on usage patterns
   - Weekend and holiday scheduling

2. **Preventive Maintenance**
   - Automated database VACUUM operations
   - Storage space monitoring
   - Performance optimization

3. **Resource Right-sizing**
   - Regular utilization analysis
   - Automatic scaling adjustments
   - Cost-effective resource allocation

## Benefits Achieved

1. **Cost Reduction**
   - 40-60% reduction in development environment costs
   - Elimination of idle resource costs
   - Optimized resource utilization

2. **Improved Reliability**
   - Zero downtime due to storage issues
   - Proactive issue detection
   - Automated maintenance procedures

3. **Operational Efficiency**
   - Reduced manual intervention
   - Consistent resource management
   - Automated incident response

## Best Practices

1. **Resource Tagging**
   ```hcl
   tags = {
       Name = "resource-name"
       Environment = "dev"
       Schedule = "business-hours"
   }
   ```

2. **Monitoring Configuration**
   - Set appropriate thresholds based on historical data
   - Implement graduated response actions
   - Maintain comprehensive monitoring documentation

3. **Security Measures**
   - Use least-privilege IAM roles
   - Implement proper error handling
   - Maintain audit logs

## Implementation Example

Here's an example of our RDS maintenance implementation:

```python
def maintenance_task():
try:
# Connect to database
conn = connect_to_database()
# Execute maintenance
execute_vacuum_full()
# Notify success
send_notification("Maintenance completed successfully")
finally:
# Auto-terminate instance
terminate_instance()
)
## Monitoring and Alerting
```


## Monitoring and Alerting

1. **Critical Metrics**
   - Database storage utilization
   - Application error rates
   - Resource utilization patterns
   - Performance metrics

2. **Alert Thresholds**
   - Warning: 70% utilization
   - Critical: 85% utilization
   - Emergency: 95% utilization

3. **Response Actions**
   - Automated maintenance
   - Resource scaling
   - Team notifications

## Conclusion

Our AWS Lambda-based scheduling and monitoring system has proven highly effective in:
- Reducing operational costs through automated resource management
- Preventing incidents through proactive monitoring
- Improving system reliability through automated maintenance
- Reducing team workload through automation

The combination of scheduled resource management and proactive monitoring ensures optimal resource utilization while maintaining system stability and performance.

## References

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [CloudWatch Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/)
- [AWS Auto Scaling](https://docs.aws.amazon.com/autoscaling/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
