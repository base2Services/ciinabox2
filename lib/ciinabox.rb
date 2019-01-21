require "thor"
require "ciinabox/version"

module Ciinabox
  class Cli < Thor

    map %w[--version -v] => :__print_version
    desc "--version, -v", "print the version"
    def __print_version
      puts Ciinabox::VERSION
    end

  end
end
