require 'aws-sdk-core'
require 'aws-sdk-route53'
require 'aws-sdk-s3'
require 'resolv'
require 'fileutils'
require 'ciinabox/log'

module Ciinabox
  class Utils
    class << self
      include Ciinabox::Log

      def aws_account_id()
        sts = Aws::STS::Client.new()
        resp = sts.get_caller_identity()
        return resp[:account]
      end

      def route53_hostedzone_exists?(zone)
        route53 = Aws::Route53::Client.new()
        resp = route53.list_hosted_zones_by_name({dns_name: zone})
        return resp.hosted_zones.select { |hz| hz.name.chomp('.') == zone }.any?
      end

      def dns_is_resolvable?(zone)
        return ((Resolv::DNS.new.getresources(zone, Resolv::DNS::Resource::IN::NS)).any?) ? true : false
      end

      def valid_dns_name?(zone)
        return (zone =~ /^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/)
      end
      
      def get_bucket_policy(bucket)
        client = Aws::S3::Client.new()
        begin
          resp = client.get_bucket_policy({
            bucket: bucket
          })
          return JSON.parse(resp.policy.read)
        rescue Aws::S3::Errors::NoSuchBucketPolicy => e
          Log.logger.debug "No bucket policy found"
          return {}
        end
      end
      
      def set_bucket_policy(bucket,name)
        policy = get_bucket_policy(bucket)
        endpoint_id = get_s3_vpc_endpoint(name)
        vpce_statement = {
          Sid: "#{name}-ciinabox-vpce",
          Effect: "Allow",
          Principal: "*",
          Action: [
            "s3:GetObject",
            "s3:PutObject"
          ],
          Resource: "arn:aws:s3:::#{bucket}/#{name}/*",
          Condition: {
            StringLike: {
              "aws:sourceVpce" => "#{endpoint_id}"
            }
          }
        }
        
        if policy.empty?
          statements = [vpce_statement]
        else
          statements = policy['Statement']
          statements.push(vpce_statement)
          statements.uniq! { |s| s[:Sid] }
        end
        
        policy = {
          Version: "2012-10-17",
          Id: "ciinabox-source-bucket-policy",
          Statement: statements
        }
        
        client = Aws::S3::Client.new()
        client.put_bucket_policy({
          bucket: bucket,
          policy: policy.to_json
        })
      end
      
      def get_s3_vpc_endpoint(name)
        client = Aws::EC2::Client.new()
        vpcs = client.describe_vpcs({
          filters: [
            { name: "tag:ciinabox:name", values: [name] },
          ]
        })
        endpoints = client.describe_vpc_endpoints({
          filters: [
            { name: "vpc-id", values: [vpcs.vpcs[0].vpc_id] },
            { name: "service-name", values: ["com.amazonaws.ap-southeast-2.s3"] }
          ]
        })
        return endpoints.vpc_endpoints[0].vpc_endpoint_id
      end
      
      def store_config(bucket,name,config)
        body = File.open(config, 'rb').read
        client = Aws::S3::Client.new()
        client.put_object({
          body: body,
          bucket: bucket,
          key: "#{name}/jenkins/jenkins.yaml",
          tagging: "ciinabox:name=#{name}"
        })
      end

    end
  end
end
