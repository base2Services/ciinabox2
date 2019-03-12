import time
import boto3
import json
import os
import sys
import traceback
import uuid

sys.path.append(f"{os.environ['LAMBDA_TASK_ROOT']}/lib")
sys.path.append(os.path.dirname(os.path.realpath(__file__)))

import cr_response

def handler(event, context):
    print(f"Received event:{json.dumps(event)}")
    request_type = event['RequestType']
    dns_zone =  event['ResourceProperties']['RootDomainName']
    domain_name = event['ResourceProperties']['DomainName']
    region = event['ResourceProperties']['AwsRegion']
    ns_records = event['ResourceProperties']['NSRecords']
    iam_role = event['ResourceProperties']['ParentIAMRole']

    try:
        dns_request = get_ns_upsert(domain_name, ns_records, dns_zone)
        if request_type == 'Create':
            print(f"adding {domain_name} NS records {ns_records} to dns zone {dns_zone}")
            create_route53_nsrecord(dns_request, dns_zone, iam_role, region)
            event['PhysicalResourceId'] = domain_name
            r = cr_response.CustomResourceResponse(event)
            r.respond()
            return   
        if request_type == 'Update':
            print(f"updating {domain_name} NS records {ns_records} to dns zone {dns_zone}")
            create_route53_nsrecord(dns_request, dns_zone, iam_role, region)
            r = cr_response.CustomResourceResponse(event)
            r.respond()
            return   
        if request_type == 'Delete':
            print(f"ignoring delete for {domain_name}")
            r = cr_response.CustomResourceResponse(event)
            r.respond()
            return
    except Exception as ex:
        print("Failed Adding NS Records. Payload:\n" + str(event))
        print(str(ex))
        traceback.print_exc(file=sys.stdout)
        r = cr_response.CustomResourceResponse(event)
        r.respond_error(str(ex))

def get_session(role, service, region):
  session = get_role_session(role_arn=role)
  return session.client(service, region_name=region)

def get_role_session(role_arn=None, sts_client=None):
        """
        Created a session for the specified role
        :param role_arn: Role arn
        :param sts_client: Optional sts client, if not specified a (cache) sts client instance is used
        :return: Session for the specified role
        """
        if role_arn is not None:
            sts = sts_client if sts_client is not None else boto3.client("sts")
            token = sts.assume_role(RoleArn=role_arn, RoleSessionName="{}".format(str(uuid.uuid4())))
            credentials = token["Credentials"]
            return boto3.Session(aws_access_key_id=credentials["AccessKeyId"],
                                 aws_secret_access_key=credentials["SecretAccessKey"],
                                 aws_session_token=credentials["SessionToken"])
        else:
            return boto3.Session() 

def get_ns_upsert(domain_name, ns_records, dns_zone):
    ns_change_set = []
    for ns in ns_records:
        ns_change_set.append({ 'Value' : ns })
    upsert = {
        'Comment': f"NS records for  validation for {domain_name}",
        'Changes': [
            {
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': domain_name,
                    'Type': 'NS',
                    'TTL': 60,
                    'ResourceRecords': ns_change_set
                }
            },
        ]        
    }
    return upsert


def create_route53_nsrecord(upsert, dns_zone, role, region):
    route53 = get_session(role, 'route53', region)
    hosted_zone = route53.list_hosted_zones_by_name(
        DNSName=dns_zone
    )
    if len(hosted_zone['HostedZones']) == 0:
        raise Exception(f"Zone {dns_zone} is not managed via Route53 in this AWS Account")
    hosted_zone_id = hosted_zone['HostedZones'][0]['Id']

    print(upsert)
    route53.change_resource_record_sets(
        HostedZoneId=hosted_zone_id,
        ChangeBatch=upsert
        )