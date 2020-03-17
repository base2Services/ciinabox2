
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ciinabox/version"

Gem::Specification.new do |spec|
  spec.name          = "ciinabox"
  spec.version       = Ciinabox::VERSION
  spec.authors       = ["aaronwalker", "Guslington"]
  spec.email         = ["ciinabox@base2services.com"]

  spec.summary       = %q{Create and Manage a ciinaboxes}
  spec.description   = %q{Create and Manage a ciinaboxes}
  spec.homepage      = "http://ciinabox.co"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "http://mygemserver.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 0.19"
  spec.add_dependency "terminal-table", '~> 1', '<2'
  spec.add_dependency 'cfhighlander', '~>0.10', '<1'
  spec.add_runtime_dependency 'aws-sdk-core', '~> 3','<4'
  spec.add_runtime_dependency 'aws-sdk-s3', '~> 1', '<2'
  spec.add_runtime_dependency 'aws-sdk-ec2', '~> 1', '<2'
  spec.add_runtime_dependency 'aws-sdk-ecs', '~> 1', '<2'
  spec.add_runtime_dependency 'aws-sdk-route53', '~> 1', '<2'
  spec.add_runtime_dependency 'aws-sdk-cloudformation', '~> 1.30', '<2'
  spec.add_runtime_dependency 'aws-sdk-codecommit', '~> 1', '<2'
  spec.add_runtime_dependency 'aws-sdk-codebuild', '~> 1', '<2'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
end
