$:.push File.join(File.dirname(__FILE__), "..", "lib")
require "ufo_compiler"

path = File.expand_path(File.dirname(__FILE__))

class String
  def strip_heredoc
    lines = self.split("\n")
    min_whitespace = lines.min {|x,y| x.match(/^ */)[0].size <=> y.match(/^ */)[0].size}.match(/^ */)[0].size
    l = lines.map do |line|
      spaces = line.match(/^ */)[0].size
      " " * (spaces - min_whitespace) + line.lstrip
    end
    l.join("\n")
  end
end

describe Slurper do
  
  it "takes a simple string and returns the same string" do
    text = <<-TEXT.strip_heredoc
      # Choosing an ORM
      
      Since you'll be using a database with your application, you'll need a way to get data from the database into your application. In Ruby, the way you do this is to install an Object Relational Mapper (ORM), which will allow you to access your database as though it was a queryable set of Ruby objects.
      
      For instance, you will be able to get back a list of all menu items as an Array, iterate over the Array, access the properties over individual items, and pretty much any normal Ruby operation. In essence, the purpose of an ORM is to hide the fact that you're working with a database, and to make code accessing your database seamlessly integrate with your other Ruby code.
    TEXT
        
    Slurper.new(text).to_s.should == text
  end
  
  it "takes a string containing a <listing:foo> and replaces it with Listing NN" do
    initial_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in Listing 1.
    
    <listing:use_orm>
    
        # config/init.rb
        use_orm :activerecord
    
    As you can see, the Rails database tasks...
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in Listing 1.
    
    <p class='listing title'><a name=\"use_orm\">Listing 1</a></p>
    
        # config/init.rb
        use_orm :activerecord
    
    As you can see, the Rails database tasks...
    TEXT
    
    Slurper.new(initial_text).to_s.should == expected_text
  end
  
  it "replaces references to listings with the listing number" do
    initial_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in <ref:listing:use_orm>.
    
    <listing:use_orm>
    
        # config/init.rb
        use_orm :activerecord
        
    As you can see, the Rails database tasks...
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in Listing 1.
    
    <p class='listing title'><a name=\"use_orm\">Listing 1</a></p>
    
        # config/init.rb
        use_orm :activerecord
        
    As you can see, the Rails database tasks...
    TEXT
    
    Slurper.new(initial_text).to_s.should == expected_text
  end
  
  it "replaces multiple references to listings with the listing number" do
    initial_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in <ref:listing:use_orm>.
    
    <listing:use_orm>
    
        # config/init.rb
        use_orm :activerecord
        
    As you can see, the Rails database tasks...
    
    <listing:another>
    
    <ref:listing:use_orm> is awesome.
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in Listing 1.
    
    <p class='listing title'><a name=\"use_orm\">Listing 1</a></p>
    
        # config/init.rb
        use_orm :activerecord
        
    As you can see, the Rails database tasks...
    
    <p class='listing title'><a name=\"another\">Listing 2</a></p>
    
    Listing 1 is awesome.
    TEXT
    
    Slurper.new(initial_text).to_s.should == expected_text
  end
  
  it "supports listing titles" do
    initial_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in <ref:listing:use_orm>.
    
    <listing:use_orm:"Some text here would be nice">
    
        # config/init.rb
        use_orm :activerecord
        
    As you can see, the Rails database tasks...
    
    <ref:listing:use_orm> is awesome.
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in Listing 1.
    
    <p class='listing title'><a name=\"use_orm\">Listing 1</a>Some text here would be nice</p>
    
        # config/init.rb
        use_orm :activerecord
        
    As you can see, the Rails database tasks...
    
    Listing 1 is awesome.
    TEXT
    
    Slurper.new(initial_text).to_s.should == expected_text    
  end
  
  it "handles an optional chapter number" do
    initial_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in <ref:listing:use_orm>.
    
    <listing:use_orm>
    
        # config/init.rb
        use_orm :activerecord
        
    As you can see, the Rails database tasks...
    
    <listing:another>
    
    <ref:listing:use_orm> is awesome.
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in Listing 3.1.
    
    <p class='listing title'><a name=\"use_orm\">Listing 3.1</a></p>
    
        # config/init.rb
        use_orm :activerecord
        
    As you can see, the Rails database tasks...
    
    <p class='listing title'><a name=\"another\">Listing 3.2</a></p>
    
    Listing 3.1 is awesome.
    TEXT
    
    Slurper.new(initial_text, :chapter => 3).to_s.should == expected_text
  end
  
  it "raises an error if you try to use the same listing twice" do
    initial_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in <ref:listing:use_orm>.
    
    <listing:use_orm>
    
        # config/init.rb
        use_orm :activerecord
        
    As you can see, the Rails database tasks...
    
    <listing:use_orm>
    
    <ref:listing:use_orm> is awesome.
    TEXT

    lambda { Slurper.new(initial_text).to_s }.should raise_error(Slurper::DuplicateName)
  end
  
  it "raises an error if you try to reference a non-existent listing" do
    initial_text = <<-TEXT.strip_heredoc
    Once ActiveRecord is installed, you'll want to go into config/init.rb in your application, and tell Merb to use it. If you run `rake -T db`, you should see a list of rake tasks for ActiveRecord, which should be identical (or at least similar) to the output in <ref:listing:use_orm>.
    
    <listing:use_orm>
    
        # config/init.rb
        use_orm :activerecord
        
    As you can see, the Rails database tasks...
    
    <listing:use_orm2>
    
    <ref:listing:another> is awesome.
    TEXT

    lambda { Slurper.new(initial_text).to_s }.should raise_error(Slurper::MissingName)
  end
  
  it "removes TODO sections" do
    initial_text = <<-TEXT.strip_heredoc
      Awesome stuff.
      
      > TODO: Stuff
      > Other Stuff
      > More Stuff
      
      > Stuff
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
      Awesome stuff.
      
      > Stuff
    TEXT
    
    Slurper.new(initial_text).to_s.should == expected_text
  end
  
  it "generates figures" do
    initial_text = <<-TEXT.strip_heredoc
      Awesome stuff.
      
      <figure:atm.jpg:"That's some ATM you got yourself">
      
      More stuff
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
      Awesome stuff.
      
      <div class='figure'><img src="#{path}/images/atm.jpg" width='528' height='396'/></div>
      <p class='figure title'><a name='atm.jpg'>Figure 3.1</a> That's some ATM you got yourself</p>
      
      More stuff
    TEXT
    
    Slurper.new(initial_text, :chapter => 3, :base_dir => path).to_s.should == expected_text
  end
  
  it "replaces references to the figure with the figure number" do
    initial_text = <<-TEXT.strip_heredoc
      Awesome stuff.
      
      <figure:atm.jpg:"That's some ATM you got yourself">
      
      <ref:figure:atm.jpg>
      
      More stuff
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
    Awesome stuff.
    
    <div class='figure'><img src="#{path}/images/atm.jpg" width='528' height='396'/></div>
    <p class='figure title'><a name='atm.jpg'>Figure 3.1</a> That's some ATM you got yourself</p>
    
    Figure 3.1
    
    More stuff
    TEXT
    
    Slurper.new(initial_text, :chapter => 3, :base_dir => path).to_s.should == expected_text
  end
  
  it "generates tables" do
    initial_text = <<-TEXT.strip_heredoc
      Awesome stuff.
      
      <grid:awesome:"This is pretty awesome">
      
      More stuff
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
      Awesome stuff.
      
      <p class='table title'><a name='awesome'>Table 3.1</a> This is pretty awesome</p>
      
      More stuff
    TEXT
    
    Slurper.new(initial_text, :chapter => 3).to_s.should == expected_text
  end
  
  it "replaces references to the table" do
    initial_text = <<-TEXT.strip_heredoc
      Awesome stuff.
      
      <grid:awesome:"This is pretty awesome">
      
      More stuff <ref:grid:awesome>
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
      Awesome stuff.
      
      <p class='table title'><a name='awesome'>Table 3.1</a> This is pretty awesome</p>
      
      More stuff Table 3.1
    TEXT
    
    Slurper.new(initial_text, :chapter => 3).to_s.should == expected_text
  end  
  
  
  it "generates section numbers" do
    initial_text = <<-TEXT.strip_heredoc
      # Foo
      
      Awesome
      Awesome
      Awesome
      
      ## Bar
      
      Awesome
      
      ## Baz
      
      Awesome
      
      #### Bat
      
      Awesome
      Awesome
      
      ## Bam
      
      Awesome
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
      # _Foo_{: .title} _3_{: .number}&nbsp;
      
      Awesome
      Awesome
      Awesome
      
      ## _3.1_{: .number} _Bar_{: .title}&nbsp;
      
      Awesome
      
      ## _3.2_{: .number} _Baz_{: .title}&nbsp;
      
      Awesome
      
      #### _3.2.1.1_{: .number} _Bat_{: .title}&nbsp;
      
      Awesome
      Awesome
      
      ## _3.3_{: .number} _Bam_{: .title}&nbsp;
      
      Awesome
    TEXT
    
    Slurper.new(initial_text, :chapter => 3).number_sections.to_s.should == expected_text
  end
  
  it "replaces cueballs" do
    initial_text = <<-TEXT.strip_heredoc
      Awesome stuff.
      
      <listing:awesome>
      
          Awesome                       # 1
          More Awesome                  # 2
      
      This is a <cue:awesome:1>.
    TEXT
    
    expected_text = <<-TEXT.strip_heredoc
      Awesome stuff.
      
      <p class='listing title'><a name=\"awesome\">Listing 3.1</a></p>
      
          Awesome                       # !!-<a name="awesome_cue_1">1</a>-!!
          More Awesome                  # !!-<a name="awesome_cue_2">2</a>-!!
      
      This is a <a href=\"#awesome_cue_1\">#1</a>.
    TEXT
    
    Slurper.new(initial_text, :chapter => 3).to_s.should == expected_text
  end  
  
end