require File.dirname(__FILE__) + '/spec_helper'

shared 'basic' do
  it "should not change self" do
    $this = self
    P { $this.should == self }
  end

  it "should handle simple tags" do
    P { h1 "Awesome" }.should == "<h1>Awesome</h1>"
    P { h1 "Awesome"; strong "Ruby" }.
      should == "<h1>Awesome</h1><strong>Ruby</strong>"
    P { br }.should == "<br/>"
    P { br; hr}.should == "<br/><hr/>"
    P { br :style => "test" }.should == '<br style="test"/>'
    P { a "Google", :href => "http://google.com" }.
      should =='<a href="http://google.com">Google</a>'
  end
  
  it "should handle nested tags" do
    P { html { head { h1 "Awesome" }; body { "Cool" } } }.
      should == "<html><head><h1>Awesome</h1></head><body>Cool</body></html>"
    P { html(:id => 'head') { body } }.
      should == '<html id="head"><body/></html>'
  end

  it "should handle mixed syntax" do
    P { div { h1 "Awesome"; h2 "Cool"; "Silent" } }.
      should == "<div><h1>Awesome</h1><h2>Cool</h2></div>"
  end

  it "should handle escaping" do
    P { h1 'Apples & <em>Oranges</em>' }.
      should == "<h1>Apples &amp; &lt;em&gt;Oranges&lt;/em&gt;</h1>"
    P { h1 { 'Apples & <em>Oranges</em>' } }.
      should == "<h1>Apples & <em>Oranges</em></h1>"
    P { h1 'Apples', :class => '& Oranges' }.
      should == '<h1 class="&amp; Oranges">Apples</h1>'
  end

  it "should handle (forced) method calls and tags" do
    should.raise(NoMethodError) { P { self.li } }
    P { li }.should == '<li/>'
    P { tag.li }.should == '<li/>'

    meta_def(:li) { }

    P { self.li }.should == ''
    P { li }.should == ''
    P { tag.li }.should == '<li/>'

    meta_eval { remove_method(:li) }
  end
  
  it "should handle CSS proxies" do
    P { div.footer!("content") }.
      should == '<div id="footer">content</div>'
    P { div.foo.bar.foobar }.
      should == '<div class="foo bar foobar"/>'
  end   
end