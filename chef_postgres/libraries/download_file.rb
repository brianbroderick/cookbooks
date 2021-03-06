# frozen_string_literal: true
# Options:
#   :region
#   :file
#   :bucket
#   :destination       - path to where it will be saved

class Chef
  class Provider
    class DownloadFile < Chef::Provider::LWRPBase
      attr_reader :node, :opts

      def self.call(*args)
        new(*args).call
      end

      def initialize(node, opts = {})
        @node = node
        @opts = opts
      end

      def call
        s3 = ::Aws::S3::Resource.new(
          { region: node["chef_postgres"]["s3"]["region"],
            access_key_id: node["chef_postgres"]["s3"]["access_key_id"],
            secret_access_key: node["chef_postgres"]["s3"]["secret_access_key"] }
        )
        obj = s3.bucket(opts[:bucket]).object("#{node["chef_postgres"]["server_name"]}/#{opts[:file]}")
        obj.get({ response_target: opts[:destination] })
      end
    end
  end
end
