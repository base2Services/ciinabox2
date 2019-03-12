
    require('/Users/aaronwalker/.chefdk/gem/ruby/2.4.0/gems/cfhighlander-0.7.0/lib/../cfndsl_ext/iam_helper.rb')

    require('/Users/aaronwalker/.chefdk/gem/ruby/2.4.0/gems/cfhighlander-0.7.0/lib/../cfndsl_ext/lambda_helper.rb')

    require('/Users/aaronwalker/.cfhighlander/components/vpc/latest//ext/cfndsl/az.rb')

    require('/Users/aaronwalker/.cfhighlander/components/vpc/1.2.0/ext/cfndsl/nat.rb')

    require('/Users/aaronwalker/.cfhighlander/components/vpc/1.2.0/ext/cfndsl/az.rb')

    require('/Users/aaronwalker/.cfhighlander/components/vpc/1.2.0/ext/cfndsl/sg.rb')

CloudFormation do



# render subcomponents



		  az_conditions_resources('SubnetPublic', maximum_availability_zones)
		
		  EC2_SecurityGroup('SecurityGroupLoadBalancer') do
		    GroupDescription FnJoin(' ', [Ref('EnvironmentName'), component_name])
		    VpcId Ref('VPCId')
		    SecurityGroupIngress sg_create_rules(securityGroups['loadbalancer'], ip_blocks)
		  end
		
		  atributes = []
		
		  loadbalancer_attributes.each do |key, value|
		    atributes << { Key: key, Value: value } unless value.nil?
		  end if loadbalancer_attributes.any?
		
		  tags = []
		  tags << { Key: "Environment", Value: Ref("EnvironmentName") }
		  tags << { Key: "EnvironmentType", Value: Ref("EnvironmentType") }
		
		  loadbalancer_tags.each do |key, value|
		    tags << { Key: key, Value: value }
		  end if loadbalancer_tags.any?
		
		  ElasticLoadBalancingV2_LoadBalancer('LoadBalancer') do
		
		    if loadbalancer_scheme == 'internal'
		      Subnets az_conditional_resources('SubnetCompute', maximum_availability_zones)
		      Scheme 'internal'
		    else
		      Subnets az_conditional_resources('SubnetPublic', maximum_availability_zones)
		    end
		
		    if loadbalancer_type == 'network'
		      Type loadbalancer_type
		    else
		      SecurityGroups [Ref('SecurityGroupLoadBalancer')]
		    end
		
		    Tags tags if tags.any?
		
		    LoadBalancerAttributes atributes if atributes.any?
		  end
		
		  targetgroups.each do |tg_name, tg|
		
		    atributes = []
		
		    tg['atributes'].each do |key, value|
		      atributes << { Key: key, Value: value }
		    end if tg.has_key?('atributes')
		
		    tags = []
		    tags << { Key: "Environment", Value: Ref("EnvironmentName") }
		    tags << { Key: "EnvironmentType", Value: Ref("EnvironmentType") }
		
		    tg['tags'].each do |key, value|
		      tags << { Key: key, Value: value }
		    end if tg.has_key?('tags')
		
		    ElasticLoadBalancingV2_TargetGroup("#{tg_name}TargetGroup") do
		      ## Required
		      Port tg['port']
		      Protocol tg['protocol'].upcase
		      VpcId Ref('VPCId')
		      ## Optional
		      if tg.has_key?('healthcheck')
		        HealthCheckPort tg['healthcheck']['port'] if tg['healthcheck'].has_key?('port')
		        HealthCheckProtocol tg['healthcheck']['protocol'] if tg['healthcheck'].has_key?('port')
		        HealthCheckIntervalSeconds tg['healthcheck']['interval'] if tg['healthcheck'].has_key?('interval')
		        HealthCheckTimeoutSeconds tg['healthcheck']['timeout'] if tg['healthcheck'].has_key?('timeout')
		        HealthyThresholdCount tg['healthcheck']['heathy_count'] if tg['healthcheck'].has_key?('heathy_count')
		        UnhealthyThresholdCount tg['healthcheck']['unheathy_count'] if tg['healthcheck'].has_key?('unheathy_count')
		        HealthCheckPath tg['healthcheck']['path'] if tg['healthcheck'].has_key?('path')
		        Matcher ({ HttpCode: tg['healthcheck']['code'] }) if tg['healthcheck'].has_key?('code')
		      end
		
		      TargetType tg['type'] if tg.has_key?('type')
		      TargetGroupAttributes atributes if atributes.any?
		
		      Tags tags if tags.any?
		
		      if tg.has_key?('type') and tg['type'] == 'ip' and tg.has_key? 'target_ips'
		        Targets (tg['target_ips'].map {|ip|  { 'Id' => ip['ip'], 'Port' => ip['port'] }})
		      end
		    end
		
		    Output("#{tg_name}TargetGroup") {
		      Value(Ref("#{tg_name}TargetGroup"))
		      Export FnSub("${EnvironmentName}-#{component_name}-#{tg_name}TargetGroup")
		    }
		  end if defined?('targetgroups')
		
		  listeners.each do |listener_name, listener|
		    next if listener.nil?
		    ElasticLoadBalancingV2_Listener("#{listener_name}Listener") do
		      Protocol listener['protocol'].upcase
		      Certificates [{ CertificateArn: Ref('SslCertId') }] if listener['protocol'] == 'https'
		      SslPolicy listener['ssl_policy'] if listener.has_key?('ssl_policy')
		      Port listener['port']
		      DefaultActions ([
		          TargetGroupArn: Ref("#{listener['default_targetgroup']}TargetGroup"),
		          Type: "forward"
		      ])
		      LoadBalancerArn Ref('LoadBalancer')
		    end
		    Output("#{listener_name}Listener") {
		      Value(Ref("#{listener_name}Listener"))
		      Export FnSub("${EnvironmentName}-#{component_name}-#{listener_name}Listener")
		    }
		  end if defined?('listeners')
		
		  if defined? records
		    records.each do |record|
		      Route53_RecordSet("#{record.gsub('*', 'Wildcard')}LoadBalancerRecord") do
		        HostedZoneName FnJoin("", [Ref("EnvironmentName"), ".", Ref('DnsDomain'), "."])
		        Name FnJoin("", ["#{record}.", Ref("EnvironmentName"), ".", Ref('DnsDomain'), "."])
		        Type 'A'
		        AliasTarget ({
		            DNSName: FnGetAtt("LoadBalancer", "DNSName"),
		            HostedZoneId: FnGetAtt("LoadBalancer", "CanonicalHostedZoneID")
		        })
		      end
		    end
		  end
		
		  Output("LoadBalancer") {
		    Value(Ref("LoadBalancer"))
		    Export FnSub("${EnvironmentName}-#{component_name}-LoadBalancer")
		  }
		  Output("SecurityGroupLoadBalancer") {
		    Value(Ref("SecurityGroupLoadBalancer"))
		    Export FnSub("${EnvironmentName}-#{component_name}-SecurityGroupLoadBalancer")
		  }
		
		



    # cfhighlander generated lambda functions
    

    # cfhighlander generated parameters

    Parameter('EnvironmentName') do
      Type 'String'
      Default 'dev'
      NoEcho false
    end

    Parameter('EnvironmentType') do
      Type 'String'
      Default 'development'
      NoEcho false
    end

    Parameter('StackOctet') do
      Type 'String'
      Default ''
      NoEcho false
    end

    Parameter('DnsDomain') do
      Type 'String'
      Default ''
      NoEcho false
    end

    Parameter('SslCertId') do
      Type 'String'
      Default ''
      NoEcho false
    end

    Parameter('SubnetPublic0') do
      Type 'String'
      Default ''
      NoEcho false
    end

    Parameter('SubnetPublic1') do
      Type 'String'
      Default ''
      NoEcho false
    end

    Parameter('SubnetPublic2') do
      Type 'String'
      Default ''
      NoEcho false
    end

    Parameter('SubnetPublic3') do
      Type 'String'
      Default ''
      NoEcho false
    end

    Parameter('SubnetPublic4') do
      Type 'String'
      Default ''
      NoEcho false
    end

    Parameter('VPCId') do
      Type 'AWS::EC2::VPC::Id'
      Default ''
      NoEcho false
    end



    Description 'alb - v0.1.0 (loadbalancer@latest)'

    Output('CfTemplateUrl') {
        Value("https://855280047356.ap-southeast-2.ciinabox.s3.amazonaws.com/cloudformation/ciinabox-example/0.1.0/loadbalancer.compiled.yaml")
    }
    Output('CfTemplateVersion') {
        Value("0.1.0")
    }
end
