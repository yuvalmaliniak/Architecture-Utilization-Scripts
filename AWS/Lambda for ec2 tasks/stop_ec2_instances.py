''' Stop ec2 instances in a specific region'''
import boto3
region = 'us-west-1'
instances = ['i-123456789', 'i-1234567890']
ec2 = boto3.client('ec2', region_name=region)

def lambda_handler(event, context):
    ec2.stop_instances(InstanceIds=instances)
    print('Stopped the following instances: ' + str(instances))