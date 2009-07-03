# == Using it
# 
#   # in config/initializers/parkaby.rb
#   require 'parkaby'
#   Parkaby::Frameworks::Rails.active!
class Parkaby::Frameworks::Rails < ActionView::TemplateHandler
  @@cache = {}
  
  def self.call(template)
    @@cache.delete(template) || super
  end
  
  def render(template, local_assigns)
    undef_cached(template, local_assigns)
    compile(template)
    template.render(@view, local_assigns)
  end
  
  def undef_cached(template, local_assigns)
    ActionView::Base::CompiledTemplates.instance_eval do
      remove_method(template.method_name(local_assigns))
    end
  end
  
  def compile(template)
    view = @view
    @@cache[template] = Parkaby::Template.string(template.source).to_ruby(view)
  end
  
  def self.activate!
    ActionView::Template.register_template_handler 'mab', self
  end
end