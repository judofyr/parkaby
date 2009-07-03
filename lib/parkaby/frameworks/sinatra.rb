# == Using it
#
#   # if you're using Sinatra::Base
#   Parkaby::Frameworks::Sinatra.activate!
#   
#   # if you're using your own class
#   class MyApp < Sinatra::Base
#     include Parkaby::Frameworks::Sinatra
#   end
#   
#   # in your code
#   
#   get '/' do
#     parkaby do
#       h1 'Chunky Bacon'
#     end
#   end
#   
#   get '/template' do 
#     # works with inline and external templates
#     parkaby :template
#   end
module Parkaby::Frameworks::Sinatra
  def self.activate!
    ::Sinatra::Base.instance_eval do
      include Parkaby::Frameworks::Sinatra
    end
  end
  
  def self.included(mod)
    mod.instance_eval do
      set :parkaby_cache, Module.new
      include parkaby_cache
    end
  end
  
  def parkaby(template = nil, &block)
    template = lambda { block } if template.nil?
    render :parkaby, template
  end
  
  def render_parkaby(template, data, options, locals, &block)
    if data.is_a?(Proc)
      Parkaby(&data)
    else
      name = "__parkaby_#{template}"
      parkaby_compile(name, data) unless parkaby_cached?(name)
      send(name, &block)
    end
  end
  
  def parkaby_cached?(method)
    self.class.parkaby_cache.instance_methods.include?(method)
  end
  
  def parkaby_compile(method, string)
    Parkaby::Template.string(string).def_method(self.class.parkaby_cache, method)
  end
end