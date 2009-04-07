require File.dirname(__FILE__) + '/spec_helper'

alias P Parkaby

describe('inline') do
  behaves_like 'basic'
  
  it "should capture local variables" do
    name = "Parkaby"
    P { h1(name) }.should == "<h1>Parkaby</h1>"
  end
  
  it "should capture changing local variables" do
    klass = Struct.new(:i) do
      def call
        n = (self.i += 1)
        P { h1(n) }
      end
    end
    ins = klass.new(0)
    ins.call.should == "<h1>1</h1>"
    ins.call.should == "<h1>2</h1>"
    ins.call.should == "<h1>3</h1>"
  end
end