require 'appraisal/gemfile'
require 'appraisal/command'
require 'fileutils'
require 'parallel'

module Appraisal
  # Represents one appraisal and its dependencies
  class Appraisal
    attr_reader :name, :gemfile

    def initialize(name, source_gemfile)
      @name = name
      @gemfile = source_gemfile.dup
    end

    def gem(name, *requirements)
      gemfile.gem(name, *requirements)
    end

    def write_gemfile
      ::File.open(gemfile_path, "w") do |file|
        signature = "# This file was generated by Appraisal"
        file.puts([signature, gemfile.to_s].reject {|s| s.empty? }.join("\n\n"))
      end
    end

    def install
      Command.new(bundle_command).run
    end

    def gemfile_path
      unless ::File.exist?(gemfile_root)
        FileUtils.mkdir(gemfile_root)
      end

      ::File.join(gemfile_root, "#{clean_name}.gemfile")
    end

    def bundle_command
      gemfile = "--gemfile='#{gemfile_path}'"
      commands = ['bundle', 'install', gemfile, bundle_parallel_option]
      "bundle check #{gemfile} || #{commands.compact.join(' ')}"
    end

    private

    def gemfile_root
      ::File.join(Dir.pwd, "gemfiles")
    end

    def clean_name
      name.gsub(/[^\w\.]/, '_')
    end

    def bundle_parallel_option
      if Gem::Version.create(Bundler::VERSION) >= Gem::Version.create('1.4.0.pre.1')
        "--jobs=#{::Parallel.processor_count}"
      end
    end
  end
end
