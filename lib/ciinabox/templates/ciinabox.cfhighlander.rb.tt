CfhighlanderTemplate do

  ComponentDistribution "s3://#{source_bucket}/cloudformation/#{component_name}"
  ComponentVersion "#{ciinabox_version}"

  Parameters do
    ComponentParam 'CiinaboxAmi', '/aws/service/ecs/optimized-ami/amazon-linux/recommended/image_id', type: 'AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>'
  end

  Component template: 'vpc', name: 'vpc' do
    parameter name: 'EnvironmentName', value: "#{component_name}"
    parameter name: 'EnvironmentType', value: 'development'
    parameter name: 'NetworkPrefix', value: '10'
    parameter name: 'StackOctet', value: "#{stack_octet}"
    parameter name: 'StackMask', value: '16'
    parameter name: 'SingleNatGateway', value: 'true'
    parameter name: 'MaxNatGateways', value: '1'
    parameter name: 'DnsDomain', value: "#{dns_zone}"
    parameter name: 'dnszoneAddNSRecords', value: 'true'
    parameter name: 'dnszoneParentIAMRole', value: ''
    maximum_availability_zones.times do |az|
      parameter name: "Nat#{az}EIPAllocationId", value: 'dynamic'
    end
  end

  Component template: 'acm', name: 'acm' do
    parameter name: 'EnvironmentName', value: "#{component_name}"
    parameter name: 'EnvironmentType', value: 'development'
    parameter name: 'DomainName', value: "*.#{component_name}.#{dns_zone}"
    parameter name: 'CrossAccountDNSZoneIAMRole', value: ''
  end

  Component template: 'loadbalancer', name: 'alb' do
    parameter name: 'EnvironmentName', value: "#{component_name}"
    parameter name: 'EnvironmentType', value: 'development'
    parameter name: 'DnsDomain', value: "#{dns_zone}"
    parameter name: 'SslCertId', value: 'acm.CertificateArn'
    parameter name: 'StackOctet', value: "#{stack_octet}"
  end

  Component template: 'keypair', name: 'keypair' do
    parameter name: 'KeyPairName', value: "#{component_name}"
    parameter name: 'SSMParameterPath', value: "/ciinabox/keypair"
  end

  Component template: 'github:aaronwalker/hl-component-ecs#master.snapshot', name: 'ecs' do
    parameter name: 'EnvironmentName', value: "#{component_name}"
    parameter name: 'EnvironmentType', value: 'development'
    parameter name: 'StackOctet', value: "#{stack_octet}"
    parameter name: 'KeyName', value: cfout('keypair.KeyPair')
    parameter name: 'DnsDomain', value:"#{dns_zone}"
    parameter name: 'AsgMin', value: '1'
    parameter name: 'AsgMax', value: '2'
    parameter name: 'InstanceType', value: "#{ecs_instance_type}"
    parameter name: 'Ami', value: Ref('CiinaboxAmi')
    parameter name: 'SecurityGroupBastion', value: 'alb.SecurityGroupLoadBalancer'
    parameter name: 'SecurityGroupLoadBalancer', value: 'alb.SecurityGroupLoadBalancer'
  end

  Component template: 'ecs-service@1.7.2', name: 'ciinabox-web' do
    parameter name: 'EnvironmentName', value: "#{component_name}"
    parameter name: 'EnvironmentType', value: 'development'
    parameter name: 'LoadBalancer', value: 'alb.LoadBalancer'
    parameter name: 'TargetGroup', value: 'alb.defaultTargetGroup'
    parameter name: 'Listener', value: 'alb.httpsListener'
    parameter name: 'MinimumHealthyPercent', value: 0
    parameter name: 'MaximumPercent', value: 100
    parameter name: 'DesiredCount', value: 1
    parameter name: 'EnableScaling', value: 'false'
    parameter name: 'DnsDomain', value: "#{dns_zone}"
  end
  
  addMapping('AccountId',{
    aws_account => {
      'Dummy'=>'1'
    }
  })

end
