# How I use the testdata gem

The testdata gem is a test framework for unit testing. It uses a separate file for test data to keep things as simple as possible. Here's an example:

    #!/usr/bin/env ruby

    # file: test_gtk2html.rb

    require 'testdata'
    require 'requestor'

    eval Requestor.read('http://rorbuilder.info/r/ruby') do |x|
      x.require 'gtk2html'
    end

    class TestGtk2HTML < Testdata::Base

      def tests()

        test 'Render to_a' do |html, width, height|
          
          doc = Htmle.new(html)
          Gtk2HTML::Render.new(doc, width, height).to_a.inspect
            
        end

      end
    end


    url = 'http://rorbuilder.info/r/gemtest/gtk2html/testdata_gtk2html.xml'

    TestGtk2HTML.new(url).run
    #=> {:passed=>true, :score=>"2/2", :failed=>[]}


To run a specific test, we enter the path number into the *run* method e.g.

    TestGtk2HTML.new(url).run '1'

Note: The path number is simply the identifier for a specific test.

If the test failed, we can examine the expected results with the actual results using the debug flag e.g.

    TestGtk2HTML.new(url).run '1', debug=true

Output:

<pre>
inputs: 
  html: &lt;html style="background-color:white;margin:0;padding:0;font-size:1.3em;color:red"&gt;&lt;div style="background-color:white;margin:0;padding:0;font-size:1.3em;color:red"&gt;&lt;/div&gt;&lt;/html&gt;
  width: 320
  height: 240

type or description:
 Render to_a: 

expected : 
  ["[[:draw_box, [0.0, 0.0, 0.0, 0.0], [0, 0, 320, 240], [0.0, 0.0, 0.0, 0.0], {:\"background-color\"=&gt;\"white\", :margin=&gt;{:top=&gt;0.0, :right=&gt;0.0, :bottom=&gt;0.0, :left=&gt;0.0}, :padding=&gt;{:top=&gt;0.0, :right=&gt;0.0, :bottom=&gt;0.0, :left=&gt;0.0}, :\"font-size\"=&gt;\"1.3em\", :color=&gt;\"red\"}], [[:draw_box, [0.0, 0.0, 0.0, 0.0], [nil, nil, nil, nil], [0.0, 0.0, 0.0, 0.0], {:\"background-color\"=&gt;\"white\", :margin=&gt;{:top=&gt;0.0, :right=&gt;0.0, :bottom=&gt;0.0, :left=&gt;0.0}, :padding=&gt;{:top=&gt;0.0, :right=&gt;0.0, :bottom=&gt;0.0, :left=&gt;0.0}, :\"font-size\"=&gt;\"1.3em\", :color=&gt;\"red\"}]]]"]</pre>

## Resources

* testdata https://rubygems.org/gems/testdata

testdata test gem testing
