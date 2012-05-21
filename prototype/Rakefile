target_host = 'mywebsite.com'

task :default => [:upload]

desc "Upload to #{target_host}"
task :upload => :regen do
  sh "rsync -rv --delete build/ #{target_host}:#{target_host}/"
end

desc 'Regenerate the static site'
task :regen do
  sh 'middleman build'
end
