require 'aws-sdk-s3'

module Ciinabox
  class Bucket

    def initialize(name,bucket)
      @client = Aws::S3::Client.new()
      @name = name
      @bucket = bucket
    end

    def get_policy

    end

  end
end
