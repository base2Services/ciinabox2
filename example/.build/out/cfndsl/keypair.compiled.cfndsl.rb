
    require('/Users/aaronwalker/.chefdk/gem/ruby/2.4.0/gems/cfhighlander-0.7.0/lib/../cfndsl_ext/iam_helper.rb')

    require('/Users/aaronwalker/.chefdk/gem/ruby/2.4.0/gems/cfhighlander-0.7.0/lib/../cfndsl_ext/lambda_helper.rb')

    require('/Users/aaronwalker/.cfhighlander/components/vpc/latest//ext/cfndsl/az.rb')

CloudFormation do



# render subcomponents



		  Resource('KeyPair') do
		    Type 'Custom::KeyPair'
		    Property 'ServiceToken',FnGetAtt('KeyPairCR','Arn')
		    Property 'Region', Ref('AWS::Region')
		    Property 'KeyPairName', Ref('KeyPairName')
		    Property 'SSMParameterPath', Ref('SSMParameterPath')
		  end
		
		  Output('KeyPair'){ Value(Ref('KeyPair'))}
		
		



    # cfhighlander generated lambda functions
    
        render_lambda_functions(self,
        keypair_custom_resources,
        lambda_metadata,
        {'bucket'=>'855280047356.ap-southeast-2.ciinabox','prefix' => 'cloudformation/ciinabox-example', 'version'=>'0.1.0'})
    

    # cfhighlander generated parameters

    Parameter('KeyPairName') do
      Type 'String'
      Default ''
      NoEcho false
    end

    Parameter('SSMParameterPath') do
      Type 'String'
      Default ''
      NoEcho false
    end



    Description 'keypair@latest - v0.1.0'

    Output('CfTemplateUrl') {
        Value("https://855280047356.ap-southeast-2.ciinabox.s3.amazonaws.com/cloudformation/ciinabox-example/0.1.0/keypair.compiled.yaml")
    }
    Output('CfTemplateVersion') {
        Value("0.1.0")
    }
end
