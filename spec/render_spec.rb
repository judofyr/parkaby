require File.dirname(__FILE__) + '/spec_helper'

def P(&b)
  code = b.to_ruby[6..-2]
  temp = Parkaby::Template.string(code)
  temp.compile(self).render(self)
end

describe('render') do
  behaves_like 'basic'
  
  it "should be re-usable" do
    klass = Struct.new(:name)
    first = klass.new("Magnus")
    second = klass.new("Holm")
    temp = Parkaby::Template.block { h1(name) }
    comp = temp.compile(klass)
    comp.render(first).should == "<h1>Magnus</h1>"
    comp.render(second).should == "<h1>Holm</h1>"
  end
end