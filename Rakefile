task :spec do
  Dir["spec/*_spec.rb"].each do |spec|
    load spec
  end
  Bacon.summary_on_exit
end

task :prof => :reprof do
  sh "open prof.html"
end

task :reprof do
  sh "ruby prof.rb > prof.html"
end

task :bench do
  sh "ruby bench/run.rb nasty 500"
end
