def dump_load_path
  puts $LOAD_PATH.join("\n")
  found = nil
  $LOAD_PATH.each do |path|
    if File.exists?(File.join(path,"rspec"))
      puts "Found rspec in #{path}"
      if File.exists?(File.join(path,"rspec","core"))
        puts "Found core"
        if File.exists?(File.join(path,"rspec","core","rake_task"))
          puts "Found rake_task"
          found = path
        else
          puts "!! no rake_task"
        end
      else
        puts "!!! no core"
      end
    end
  end
  if found.nil?
    puts "Didn't find rspec/core/rake_task anywhere"
  else
    puts "Found in #{path}"
  end
end
require 'bundler'
require 'rake/clean'

begin
require 'rspec/core/rake_task'
rescue LoadError
dump_load_path
raise
end

require 'cucumber'
require 'cucumber/rake/task'
gem 'rdoc' # we need the installed RDoc gem, not the system one
require 'rdoc/task'

include Rake::DSL

Bundler::GemHelper.install_tasks


RSpec::Core::RakeTask.new


PROJECT_PATH=File.dirname(__FILE__)
$stderr.puts "DEBUG PROJECT_PATH is #{PROJECT_PATH}"
CUKE_RESULTS = 'results.html'
CLEAN << CUKE_RESULTS

desc "Move some environment variables around for the cukes"
task :environment do
  if ENV['CONJUR_TEST_ENVIRONMENT'] == 'acceptance'
    ENV['CONJUR_APPLIANCE_URL'] = "https://#{ENV['CONJUR_APPLIANCE_HOSTNAME']}/api"
    ENV['CONJUR_USERNAME'] = 'admin'
    ENV['CONJUR_API_KEY']  = File.read(ENV['CONJUR_ADMIN_PASSWORD_FILE']).chomp
    ENV['CONJUR_ACCOUNT'] ||= 'ci'
    $stderr.puts ENV.inspect
  else
    $stderr.puts "WRONG CONJUR_TEST_ENVIRONMENT: #{ENV['CONJUR_TEST_ENVIRONMENT']}"
  end
end

task :features => [:environment] do
  `cd #{PROJECT_PATH} && cucumber --format html -o #{CUKE_RESULTS} --format pretty --no-source -x`
end

task :test => [:spec, :features]


