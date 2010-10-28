#!/usr/bin/ruby

# file: testdata.rb

require 'rexml/document'

class Select
  include REXML

  def initialize(type, node)  @node, @type = node, type  end
  
  def data(x)

    stringify = Proc.new {|x| x.texts.length <= 1 ? x.text : x.cdatas.join.strip}

    procs = {}
    procs[:String] = Proc.new do |type,x| 
      e = XPath.first(@node, "records/io/summary[type='#{type}']/#{x}")
      stringify.call(e)
    end
    procs[:Array] = Proc.new do |type,a|     
      xpath = a.map {|x| "records/io/summary[type='#{type}']/#{x}"}.join(' | ')
      XPath.match(@node, xpath).map {|x| stringify.call(x)}
    end

    values = procs[x.class.to_s.to_sym].call(@type, x) 
    block_given? ? yield(values) : values
  end
end

class Path
  include REXML

  def initialize(doc) @doc = doc end

  def tested? description
    node = XPath.first(@doc.root, "records/test[summary/description='#{description}']")
    raise "Path error: node not found" unless node
    yield *%w(input output).map {|x| Select.new(x,node)}
  end
end

class Testdata
  include REXML

  attr_reader :success  
 
  def initialize(s)
    buffer = self.send('read_' + (s[/https?:\/\//] ? 'file' : 'url'), s)   
    @doc = Document.new(buffer)
    raise "Testdata error: doc %s not found" % s unless @doc
    @success = []
  end

  def paths() 
    begin
      @success << yield(path = Path.new(@doc))
    raise
      @success << false
    end
  end
  def read_file(s) File.open(s, 'r').read  end
  def read_url(xml_url)  open(xml_url, 'UserAgent' => 'S-Rscript').read  end

  def passed?() @success.all? end
end
