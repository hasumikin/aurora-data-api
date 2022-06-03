require "thor"
require "fileutils"

require_relative "aurora-data-api/converter"
require_relative "aurora-data-api/model"
require_relative "aurora-data-api/schema"

module AuroraDataApi
  class Error < StandardError; end

  class Tool < Thor
    DEFAULT_MODELS_DIR = "app/models"
    DEFAULT_OUTPUT_PATH = "db/schema.sql"

    desc "version", "Print version"
    def version
      puts "aurora-data-api v#{AuroraDataApi::VERSION}"
    end

    desc "export", "Overwrite #{DEFAULT_OUTPUT_PATH} by aggregating #{DEFAULT_MODELS_DIR}/*.rb"
    option :models, aliases: :m, default: DEFAULT_MODELS_DIR
    option :output, aliases: :o, default: DEFAULT_OUTPUT_PATH
    def export
      models_dir = options[:models]
      output_path = options[:output]
      Dir.glob("#{models_dir}/*.rb").each do |rb|
        load rb
      end
      if Schema::CREATE_TABLE.empty? && Schema::ALTER_TABLE.empty?
        puts "Nothing to be exported."
        exit 1
      end
      overwrite = false
      if File.exist? output_path
        print "#{output_path} exists. Overwrite? [Y/n]: "
        answer = $stdin.gets.chomp
        if %w[Y y yes].include?(answer.chomp)
          overwrite = true
        else
          puts "Abort."
          exit 1
        end
      else
        FileUtils.touch output_path
        overwrite = true
      end
      if overwrite
        File.open output_path, "w" do |f|
          f.write <<~COMMENT
            /*
             * This file was automatically genarated by the command:
             *   aurora-data-api export --models #{models_dir} --output #{output_path}
             *
             * Genarated at #{Time.now}
             *
             * https://github.com/hasumikin/aurora-data-api
             */\n
          COMMENT
          f.write Schema::CREATE_TABLE.flatten.join("\n")
          f.write "\n"
          f.write Schema::ALTER_TABLE.flatten.join("\n")
        end
      end
    end
  end
end
