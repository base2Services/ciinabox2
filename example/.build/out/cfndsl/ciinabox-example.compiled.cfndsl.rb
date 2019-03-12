
    require('/Users/aaronwalker/.chefdk/gem/ruby/2.4.0/gems/cfhighlander-0.7.0/lib/../cfndsl_ext/iam_helper.rb')

    require('/Users/aaronwalker/.chefdk/gem/ruby/2.4.0/gems/cfhighlander-0.7.0/lib/../cfndsl_ext/lambda_helper.rb')

CloudFormation do


    Mapping('AccountId', mappings['AccountId'])

    Mapping('855280047356', mappings['855280047356'])


# render subcomponents

    CloudFormation_Stack('vpc') do
        TemplateURL 'https://855280047356.ap-southeast-2.ciinabox.s3.amazonaws.com/cloudformation/ciinabox-example/0.1.0/vpc.compiled.yaml'
        Parameters ({
        	'EnvironmentType' => 'development',
        	'EnvironmentName' => 'ciinabox-example',
        	'StackOctet' => '150',
        	'NetworkPrefix' => '10',
        	'StackMask' => '16',
        	'Az0' => FnFindInMap(Ref('AWS::AccountId'),Ref('AWS::Region'),'Az0'),
        	'Nat0EIPAllocationId' => 'dynamic',
        	'Az1' => FnFindInMap(Ref('AWS::AccountId'),Ref('AWS::Region'),'Az1'),
        	'Nat1EIPAllocationId' => 'dynamic',
        	'Az2' => FnFindInMap(Ref('AWS::AccountId'),Ref('AWS::Region'),'Az2'),
        	'Nat2EIPAllocationId' => 'dynamic',
        	'Az3' => FnFindInMap(Ref('AWS::AccountId'),Ref('AWS::Region'),'Az3'),
        	'Nat3EIPAllocationId' => 'dynamic',
        	'Az4' => FnFindInMap(Ref('AWS::AccountId'),Ref('AWS::Region'),'Az4'),
        	'Nat4EIPAllocationId' => 'dynamic',
        	'DnsDomain' => 'meetup.base2.services',
        	'MaxNatGateways' => '1',
        	'SingleNatGateway' => 'true',
        	'dnszoneAddNSRecords' => 'true',
        	'dnszoneParentIAMRole' => '',
        })
        
    end

    CloudFormation_Stack('acm') do
        TemplateURL 'https://855280047356.ap-southeast-2.ciinabox.s3.amazonaws.com/cloudformation/ciinabox-example/0.1.0/acm.compiled.yaml'
        Parameters ({
        	'EnvironmentName' => 'ciinabox-example',
        	'EnvironmentType' => 'development',
        	'DomainName' => '*.ciinabox-example.meetup.base2.services',
        	'CrossAccountDNSZoneIAMRole' => '',
        })
        
    end

    CloudFormation_Stack('alb') do
        TemplateURL 'https://855280047356.ap-southeast-2.ciinabox.s3.amazonaws.com/cloudformation/ciinabox-example/0.1.0/alb.compiled.yaml'
        Parameters ({
        	'EnvironmentName' => 'ciinabox-example',
        	'EnvironmentType' => 'development',
        	'StackOctet' => '150',
        	'DnsDomain' => 'meetup.base2.services',
        	'SslCertId' => {"Fn::GetAtt":["acm","Outputs.CertificateArn"]},
        	'SubnetPublic0' => {"Fn::GetAtt":["vpc","Outputs.SubnetPublic0"]},
        	'SubnetPublic1' => {"Fn::GetAtt":["vpc","Outputs.SubnetPublic1"]},
        	'SubnetPublic2' => {"Fn::GetAtt":["vpc","Outputs.SubnetPublic2"]},
        	'SubnetPublic3' => {"Fn::GetAtt":["vpc","Outputs.SubnetPublic3"]},
        	'SubnetPublic4' => {"Fn::GetAtt":["vpc","Outputs.SubnetPublic4"]},
        	'VPCId' => {"Fn::GetAtt":["vpc","Outputs.VPCId"]},
        })
        
    end

    CloudFormation_Stack('keypair') do
        TemplateURL 'https://855280047356.ap-southeast-2.ciinabox.s3.amazonaws.com/cloudformation/ciinabox-example/0.1.0/keypair.compiled.yaml'
        Parameters ({
        	'KeyPairName' => 'ciinabox-example',
        	'SSMParameterPath' => '/ciinabox/keypair',
        })
        
    end

    CloudFormation_Stack('ecs') do
        TemplateURL 'https://855280047356.ap-southeast-2.ciinabox.s3.amazonaws.com/cloudformation/ciinabox-example/0.1.0/ecs.compiled.yaml'
        Parameters ({
        	'EnvironmentName' => 'ciinabox-example',
        	'EnvironmentType' => 'development',
        	'Ami' => {"Ref":"CiinaboxAmi"},
        	'InstanceType' => 't2.small',
        	'AsgMin' => '1',
        	'AsgMax' => '2',
        	'KeyName' => {"Fn::GetAtt":["keypair","Outputs.KeyPair"]},
        	'DnsDomain' => 'meetup.base2.services',
        	'SubnetCompute0' => {"Fn::GetAtt":["vpc","Outputs.SubnetCompute0"]},
        	'SubnetCompute1' => {"Fn::GetAtt":["vpc","Outputs.SubnetCompute1"]},
        	'SubnetCompute2' => {"Fn::GetAtt":["vpc","Outputs.SubnetCompute2"]},
        	'SubnetCompute3' => {"Fn::GetAtt":["vpc","Outputs.SubnetCompute3"]},
        	'SubnetCompute4' => {"Fn::GetAtt":["vpc","Outputs.SubnetCompute4"]},
        	'VPCId' => {"Fn::GetAtt":["vpc","Outputs.VPCId"]},
        	'SecurityGroupLoadBalancer' => {"Fn::GetAtt":["alb","Outputs.SecurityGroupLoadBalancer"]},
        	'SecurityGroupBastion' => {"Fn::GetAtt":["alb","Outputs.SecurityGroupLoadBalancer"]},
        	'StackOctet' => '150',
        })
        
    end

    CloudFormation_Stack('ciinaboxweb') do
        TemplateURL 'https://855280047356.ap-southeast-2.ciinabox.s3.amazonaws.com/cloudformation/ciinabox-example/0.1.0/ciinabox-web.compiled.yaml'
        Parameters ({
        	'EnvironmentName' => 'ciinabox-example',
        	'EnvironmentType' => 'development',
        	'EcsCluster' => {"Fn::GetAtt":["ecs","Outputs.EcsCluster"]},
        	'VPCId' => {"Fn::GetAtt":["vpc","Outputs.VPCId"]},
        	'LoadBalancer' => {"Fn::GetAtt":["alb","Outputs.LoadBalancer"]},
        	'TargetGroup' => {"Fn::GetAtt":["alb","Outputs.defaultTargetGroup"]},
        	'Listener' => {"Fn::GetAtt":["alb","Outputs.httpsListener"]},
        	'DnsDomain' => 'meetup.base2.services',
        	'DesiredCount' => '1',
        	'MinimumHealthyPercent' => '0',
        	'MaximumPercent' => '100',
        	'EnableScaling' => 'false',
        	'Version' => {"Ref":"ciinaboxwebVersion"},
        })
        
    end






    # cfhighlander generated lambda functions
    

    # cfhighlander generated parameters

    Parameter('CiinaboxAmi') do
      Type 'AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>'
      Default '/aws/service/ecs/optimized-ami/amazon-linux/recommended/image_id'
      NoEcho false
    end

    Parameter('ciinaboxwebVersion') do
      Type 'String'
      Default 'latest'
      NoEcho false
    end



    Description 'ciinabox-example@latest - v0.1.0'

    Output('CfTemplateUrl') {
        Value("https://855280047356.ap-southeast-2.ciinabox.s3.amazonaws.com/cloudformation/ciinabox-example/0.1.0/ciinabox-example.compiled.yaml")
    }
    Output('CfTemplateVersion') {
        Value("0.1.0")
    }
end
