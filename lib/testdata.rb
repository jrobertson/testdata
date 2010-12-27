#!/usr/bin/ruby

# file: testdata.rb

require 'rexml/document'

class Path
  include REXML

  def initialize(doc, success) @doc, @success = doc, success end

  def tested? description

    stringify = Proc.new {|x| x.text.to_s.gsub(/[\n\s]/,'').length > 0 ? x.text : x.cdatas.join.strip}

    node = XPath.first(@doc.root, "records/test[summary/description='#{description}']")
    input_values = XPath.match(node, "records/io/summary[type='input']/*").map(&stringify)
    output_values = XPath.match(node, "records/io/summary[type='output']/*").map(&stringify)

    path_no = node.text('summary/path')
    raise "Path error: node not found" unless node
    
    result = nil
    @success << [nil, path_no.to_i]      
    
    begin

      values = input_values - ['input']
      expected = (output_values - ['output'])
       
      yield

      raw_result =  test(*values)

      if raw_result then
        result = [raw_result].flatten.map(&:strip) == expected.map(&:strip)
      else
        result = [raw_result].compact == expected
      end

    rescue
      result = false
    ensure
      @success[-1][0] = result
    end
  end

  def test(*values)
  end
end

class Testdata
  include REXML

  attr_reader :success  
 
  def initialize(s)
    #puts 'filex : ' + $0
    buffer = self.send('read_' + (s[/https?:\/\//] ? 'file' : 'url'), s)   
    @doc = Document.new(buffer)
    raise "Testdata error: doc %s not found" % s unless @doc
    @success = []
  end

  def paths() yield(path = Path.new(@doc, @success)) end
  def read_file(s) File.open(s, 'r').read  end
  def read_url(xml_url)  open(xml_url, 'UserAgent' => 'S-Rscript').read  end

  def passed?() @success.map(&:first).all? end
  def score() success = @success.map(&:first); [success.grep(true), success].map(&:length).join('/') end
  def summary()
    a = @success.map(&:last).sort
    {false: @success.select{|x| x[0] == false}.map(&:last).sort,
     nil: ((a[0]..a[-1]).to_a - a)}
  end
  
  def find_by(s)
    XPath.match(@doc.root, "records/test/summary[type='#{s}']/description/text()").map(&:to_s)
  end
end
