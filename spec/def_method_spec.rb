require File.dirname(__FILE__) + '/spec_helper'

def P(&b)
  Parkaby::Template.block(&b).def_method(self, :parkaby)
  parkaby
end

describe('def_method') do
  behaves_like 'basic'
  
  it "should define instance method if Class/Module" do
    kla = Class.new
    ins = kla.new
    temp = Parkaby::Template.block { h1{self} }
    temp.def_method(kla, :parkaby)
    ins.parkaby.should == "<h1>#{ins}</h1>"
  end
end