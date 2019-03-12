import sys
import os
import boto3

sys.path.append(f"{os.environ['LAMBDA_TASK_ROOT']}/lib")
sys.path.append(os.path.dirname(os.path.realpath(__file__)))

import json
import cr_response


def handler(event, context):
    print(f"Received event:{json.dumps(event)}")

    cr_resp = cr_response.CustomResourceResponse(event)
    params = event['ResourceProperties']
    print(f"Resource Properties {params}")

    try:

        if 'KeyPairName' not in params:
            raise Exception('Resource must have a KeyPairName')

        if 'SSMParameterPath' not in params:
            raise Exception('Resource must have a SSMParameterPath')

        region = params['Region']
        key_name = params['KeyPairName']
        ssm_path= params['SSMParameterPath']
        ssm_param = ''
        if ssm_path:
            if ssm_path.endswith('/'):
                ssm_param = f'{ssm_path}{key_name}'
            else:
                ssm_param = f'{ssm_path}/{key_name}'

        if event['RequestType'] == 'Create':
            event['PhysicalResourceId'] = key_name
            create_keypair(key_name, region, ssm_param)
            cr_resp.respond()
        elif event['RequestType'] == 'Update':
            if key_name == event['PhysicalResourceId']:
                print('ignoring changes')
                cr_resp.respond()
            else:
                print("creating new keypair {key_name} replacing {event['PhysicalResourceId']}")
                event['PhysicalResourceId'] = key_name
                create_keypair(key_name, region, ssm_param)
                cr_resp.respond()
        elif event['RequestType'] == 'Delete':
            delete_keypair(params['KeyPairName'], params['Region'], ssm_param)
            cr_resp.respond()    
    except Exception as e:
        message = str(e)
        cr_resp.respond_error(message)

    return 'OK'

def create_keypair(keypair_name, region, ssm_param):
    ec2 = boto3.client('ec2', region_name=region)
    key = ec2.create_key_pair(KeyName=keypair_name)
    if ssm_param:
        print(f"storing keypair {key['KeyName']} in ssm param:{ssm_param}")
        ssm = boto3.client('ssm', region_name=region)
        ssm.put_parameter(
            Name=ssm_param,
            Description='EC2 KeyPair',
            Value=key['KeyMaterial'],
            Type='SecureString',
            Overwrite=True
        )
        print(f"stored key {key['KeyName']} in ssm {ssm_param} with fingerprint {key['KeyFingerprint']}")

def delete_keypair(keypair_name, region, ssm_param):
    ec2 = boto3.client('ec2', region_name=region)
    ec2.delete_key_pair(KeyName=keypair_name)
    if ssm_param:
        ssm = boto3.client('ssm', region_name=region)
        ssm.delete_parameter(Name=ssm_param)

