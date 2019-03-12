
    require('/Users/aaronwalker/.chefdk/gem/ruby/2.4.0/gems/cfhighlander-0.7.0/lib/../cfndsl_ext/iam_helper.rb')

    require('/Users/aaronwalker/.chefdk/gem/ruby/2.4.0/gems/cfhighlander-0.7.0/lib/../cfndsl_ext/lambda_helper.rb')

    require('/Users/aaronwalker/.cfhighlander/components/vpc/latest//ext/cfndsl/az.rb')

CloudFormation do



# render subcomponents



		  cert_tags = []
		  cert_tags << { Key: "Name", Value: Ref('AWS::StackName') }
		  cert_tags << { Key: "Environment", Value: Ref("EnvironmentName") }
		  cert_tags << { Key: "EnvironmentType", Value: Ref("EnvironmentType") }
		
		  tags.each do |key, value|
		    cert_tags << { Key: key, Value: value }
		  end if defined? tags
		
		  Resource("ACMCertificate") do
		    Type 'Custom::CertificateValidator'
		    Property 'ServiceToken',FnGetAtt('CertificateValidatorCR','Arn')
		    Property 'AwsRegion', Ref('AWS::Region')
		    Property 'DomainName', Ref('DomainName')
		    Property 'Tags', cert_tags
		  end
		
		  Output("CertificateArn") { Value(Ref('ACMCertificate')) }
		
		



    # cfhighlander generated lambda functions
    
        render_lambda_functions(self,
        acm_custom_resources,
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

    Parameter('DomainName') do
      Type 'String'
      Default ''
      NoEcho false
    end

    Parameter('CrossAccountDNSZoneIAMRole') do
      Type 'String'
      Default ''
      NoEcho false
    end



    Description 'acm@latest - v0.1.0'

    Output('CfTemplateUrl') {
        Value("https://855280047356.ap-southeast-2.ciinabox.s3.amazonaws.com/cloudformation/ciinabox-example/0.1.0/acm.compiled.yaml")
    }
    Output('CfTemplateVersion') {
        Value("0.1.0")
    }
end
