# Using the testdata gem

The testdata gem is a basic test framework which reads testdata from a Polyrex file.

## Installation

`gem install testdata`

## Example: testing the Dynarex gem

Here's the main tests I used for testing Dynarex:

    #!/usr/bin/env ruby

    # file: test_dynarex.rb

    require 'json'
    require 'timecop'


    class TestDynarex < Testdata

      def tests()

        # 2011-07-24 19:52:15
        Timecop.freeze(Time.local(2011, 7, 24, 19, 52, 15))

        test 'create records' do |schema, records|
          dynarex = Dynarex.new schema            
          JSON.parse(records).each {|record| dynarex.create record }
          dynarex.to_xml
        end

        test 'parse to xml' do |string|
          dynarex = Dynarex.new             
          dynarex.parse string
          dynarex.to_xml
        end    
        
        test 'open document' do |string|
          Dynarex.new(string).to_xml pretty: true
        end        

        test 'parse to pretty xml' do |string|
          dynarex = Dynarex.new             
          dynarex.parse string
          dynarex.to_xml pretty: true
        end    

        test 'parse to_s' do |string|
          dynarex = Dynarex.new             
          dynarex.parse string
          dynarex.to_s
        end  
      end
    end

... and here's the testdata:

file: testdata_dynarex.xml
<pre>
&lt;tests&gt;
  &lt;summary&gt;
    &lt;title&gt;dynarex testdata&lt;/title&gt;
    &lt;recordx_type&gt;polyrex&lt;/recordx_type&gt;
    &lt;schema&gt;tests/test[path,description]/io[type,*]&lt;/schema&gt;
    &lt;ruby_version&gt;ruby-1.9.2-p180&lt;/ruby_version&gt;
    &lt;script&gt;//job:test http://rorbuilder.info/r/gemtest/dynarex.rsf&lt;/script&gt;
    &lt;test_dir&gt;/home/james/test-ruby/rexle&lt;/test_dir&gt;    
  &lt;/summary&gt;
  &lt;records&gt;
    &lt;test&gt;
      &lt;summary&gt;
        &lt;path&gt;1&lt;/path&gt;
        &lt;type&gt;create records&lt;/type&gt;
        &lt;description&gt;Creates a couple of records using a hash for each record input/&lt;/description&gt;
      &lt;/summary&gt;
      &lt;records&gt;
        &lt;io&gt;
          &lt;summary&gt;
            &lt;type&gt;input&lt;/type&gt;
            &lt;schema&gt;companies/company(name, last_contacted, contact)&lt;/schema&gt;
            &lt;xml&gt;[{"name":"Julie","last_contact":"12-May-2010","contact":"0353 5363"},{"name":"Amy","last_contact":"16-May-2010","contact":"0353 5377"}]
&lt;/xml&gt;
          &lt;/summary&gt;
        &lt;/io&gt;
        &lt;io&gt;
          &lt;summary&gt;
            &lt;type&gt;output&lt;/type&gt;
            &lt;value&gt;
              &lt;![CDATA[
&lt;?xml version='1.0' encoding='UTF-8'?&gt;&lt;companies&gt;&lt;summary&gt;&lt;recordx_type&gt;dynarex&lt;/recordx_type&gt;&lt;format_mask&gt;[!name] [!last_contacted] [!contact]&lt;/format_mask&gt;&lt;schema&gt;companies/company(name, last_contacted, contact)&lt;/schema&gt;&lt;default_key&gt;name&lt;/default_key&gt;&lt;/summary&gt;&lt;records&gt;&lt;company id='1' created='2011-07-24 19:52:15 +0100' last_modified=''&gt;&lt;name&gt;Julie&lt;/name&gt;&lt;last_contacted/&gt;&lt;contact&gt;0353 5363&lt;/contact&gt;&lt;/company&gt;&lt;company id='2' created='2011-07-24 19:52:15 +0100' last_modified=''&gt;&lt;name&gt;Amy&lt;/name&gt;&lt;last_contacted/&gt;&lt;contact&gt;0353 5377&lt;/contact&gt;&lt;/company&gt;&lt;/records&gt;&lt;/companies&gt;              
              ]]&gt;
            &lt;/value&gt;
          &lt;/summary&gt;
        &lt;/io&gt;
      &lt;/records&gt;
    &lt;/test&gt;    
    &lt;test&gt;
      &lt;summary&gt;
        &lt;path&gt;2&lt;/path&gt;
        &lt;type&gt;parse to xml&lt;/type&gt;
        &lt;description&gt;The delimiter attribute contains spaces before and after the equals sign&lt;/description&gt;
      &lt;/summary&gt;
      &lt;records&gt;
        &lt;io&gt;
          &lt;summary&gt;
            &lt;type&gt;input&lt;/type&gt;
            &lt;string&gt;
              &lt;![CDATA[
&lt;?dynarex schema="entries/entry(title,class,url)" delimiter = " # "?&gt;CV # pdf # abc
Finding out disk space # snippets # u444
              ]]&gt;
            &lt;/string&gt;
          &lt;/summary&gt;
        &lt;/io&gt;
        &lt;io&gt;
          &lt;summary&gt;
            &lt;type&gt;output&lt;/type&gt;
            &lt;value&gt;
              &lt;![CDATA[
&lt;?xml version='1.0' encoding='UTF-8'?&gt;&lt;entries&gt;&lt;summary&gt;&lt;recordx_type&gt;dynarex&lt;/recordx_type&gt;&lt;format_mask&gt;[!title] # [!class] # [!url]&lt;/format_mask&gt;&lt;schema&gt;entries/entry(title,class,url)&lt;/schema&gt;&lt;default_key&gt;title&lt;/default_key&gt;&lt;delimiter&gt; # &lt;/delimiter&gt;&lt;/summary&gt;&lt;records&gt;&lt;entry id='1' created='2011-07-24 19:52:15 +0100' last_modified=''&gt;&lt;title&gt;CV&lt;/title&gt;&lt;class&gt;pdf&lt;/class&gt;&lt;url&gt;abc&lt;/url&gt;&lt;/entry&gt;&lt;entry id='2' created='2011-07-24 19:52:15 +0100' last_modified=''&gt;&lt;title&gt;Finding out disk space&lt;/title&gt;&lt;class&gt;snippets&lt;/class&gt;&lt;url&gt;u444&lt;/url&gt;&lt;/entry&gt;&lt;/records&gt;&lt;/entries&gt;
              ]]&gt;
            &lt;/value&gt;
          &lt;/summary&gt;
        &lt;/io&gt;
      &lt;/records&gt;
    &lt;/test&gt;
  &lt;/records&gt;
&lt;/tests&gt;
</pre>

### Running testdata

    test = TestDynarex.new 'testdata_dynarex.xml'
    test.run

output:

<pre>{:passed=>true, :score=>"2/2", :failed=>[]}</pre>


## Resources
 
* [jrobertson/testdata](https://github.com/jrobertson/testdata)

