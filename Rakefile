ALL = FileList['spec/*_spec.rb']
BASIC = ALL.grep(/basic|inline/)

task :spec do
  BASIC.each { |file| load file }
  Bacon.summary_on_exit
end

task :all do
  ALL.each { |file| load file }
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
