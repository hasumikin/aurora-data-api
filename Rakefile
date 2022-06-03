# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

require "standard/rake"

task default: %i[test steep steep_cli standard]

desc "Steep check lib"
task :steep do
  sh "bundle exec steep check"
end

desc "Steep check exe/cli"
task :steep_cli do
  FileUtils.cd "exe" do
    sh "bundle exec steep check"
  end
end
