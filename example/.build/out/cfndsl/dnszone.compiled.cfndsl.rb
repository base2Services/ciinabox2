
    require('/Users/aaronwalker/.chefdk/gem/ruby/2.4.0/gems/cfhighlander-0.7.0/lib/../cfndsl_ext/iam_helper.rb')

    require('/Users/aaronwalker/.chefdk/gem/ruby/2.4.0/gems/cfhighlander-0.7.0/lib/../cfndsl_ext/lambda_helper.rb')

CloudFormation do



# render subcomponents



			
			  Condition("LocalNSRecords", FnAnd([
			    FnEquals(Ref('AddNSRecords'), 'true'), 
			    FnEquals(Ref('ParentIAMRole'), '')
			  ]))
			
			  Condition("RemoteNSRecords", FnAnd([
			    FnEquals(Ref('AddNSRecords'), 'true'),
			    FnNot(FnEquals(Ref('ParentIAMRole'), ''))
			  ]))
			
			  Condition('CreateZone', FnEquals(Ref('CreateZone'), 'true'))
			
			  dns_domain = FnJoin('.',[Ref('EnvironmentName'),Ref('RootDomainName')])
			  tags = []
			  tags << { Key: 'Environment', Value: Ref(:EnvironmentName) }
			  tags << { Key: 'EnvironmentType', Value: Ref(:EnvironmentType) }
			  extra_tags.each { |key,value| tags << { Key: key, Value: value } } if defined? extra_tags
			
			
			  Route53_HostedZone('HostedZone') do
			    Condition 'CreateZone'
			    Name dns_domain
			    HostedZoneConfig ({
			      Comment: FnSub("Hosted Zone for ${EnvironmentName}")
			    })
			    HostedZoneTags tags
			  end
			
			  Resource("DomainNameZoneNSRecords") do
			    Condition 'RemoteNSRecords'
			    Type 'Custom::Route53ZoneNSRecords'
			    Property 'ServiceToken',FnGetAtt('Route53ZoneCR','Arn')
			    Property 'AwsRegion', Ref('AWS::Region')
			    Property 'RootDomainName', Ref('RootDomainName')
			    Property 'DomainName', dns_domain
			    Property 'NSRecords', FnGetAtt('HostedZone', 'NameServers')
			    Property 'ParentIAMRole', Ref('ParentIAMRole')
			  end
			  
			  Route53_RecordSet('NSRecords') do
			    Condition 'LocalNSRecords'
			    HostedZoneName Ref('RootDomainName')
			    Comment FnJoin('',[FnSub('${EnvironmentName} - NS Records for ${EnvironmentName}.'), Ref('RootDomainName')])
			    Name dns_domain
			    Type 'NS'
			    TTL 60
			    ResourceRecords FnGetAtt('HostedZone', 'NameServers')
			  end
			
			  Output('DnsDomainZoneId') do
			    Condition 'CreateZone'
			    Value(Ref('HostedZone'))
			  end
			
			



    # cfhighlander generated lambda functions
    
        render_lambda_functions(self,
        route53_custom_resources,
        lambda_metadata,
        {'bucket'=>'855280047356.ap-southeast-2.ciinabox','prefix' => 'cloudformation/ciinabox-example', 'version'=>'0.1.0'})
    

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

    Parameter('CreateZone') do
      Type 'String'
      Default 'false'
      NoEcho false
      AllowedValues ["true", "false"]
    end

    Parameter('RootDomainName') do
      Type 'String'
      Default ''
      NoEcho false
    end

    Parameter('AddNSRecords') do
      Type 'String'
      Default 'false'
      NoEcho false
      AllowedValues ["true", "false"]
    end

    Parameter('ParentIAMRole') do
      Type 'String'
      Default ''
      NoEcho false
    end



    Description 'dnszone - v0.1.0 (route53-zone@1.0.2)'

    Output('CfTemplateUrl') {
        Value("https://855280047356.ap-southeast-2.ciinabox.s3.amazonaws.com/cloudformation/ciinabox-example/0.1.0/route53-zone.compiled.yaml")
    }
    Output('CfTemplateVersion') {
        Value("0.1.0")
    }
end
