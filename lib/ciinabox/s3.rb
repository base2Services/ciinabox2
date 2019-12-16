require 'aws-sdk-s3'
require 'time'
require 'ciinabox/log'

module Ciinabox
  class S3
    include Ciinabox::Log
    
    attr_reader :errors, :logs
    
    def initialize(bucket)
      @bucket = bucket
      @client = Aws::S3::Client.new()
    end
    
    def get_object(path)
      @client.get_object({
        bucket: @bucket,
        key: path
      })
    end
    
  end
end