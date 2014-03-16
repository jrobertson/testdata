#!/usr/bin/env ruby

# file: testdata.rb

require 'rexml/document'
require 'app-routes'
require 'testdata_text'

class Testdata
  include REXML
  include AppRoutes

  attr_accessor :debug

  def initialize(s, options={})
    super()
    @params = {}
    #routes()

    @success = [] # used by summary
    @debug = false

    # open the testdata document
    procs = {
      String: proc {|x|
                    
        if x.strip[/^</] then
          x
        elsif x[/https?:\/\//] then
          read_url x
        else
          read_file x
        end                   
      },
      Polyrex: proc {|x| x.to_xml}
    }

    buffer =  procs[s.class.to_s.to_sym].call(s)
    @doc = Document.new(buffer)
  
    o = {log: false}.merge(options)
    @log =  o[:log] == true ? Document.new(tests) : nil
  end

  def testdata_values(id)

    stringify = Proc.new do |x| 
      r = x.text.to_s.gsub(/^[\n\s]+/,'').length > 0 ? x.text : x.cdatas.join.strip
      #REXML::Text::unnormalize(r)
      r
    end

    node = XPath.first(@doc.root, "records/test[summary/path='#{id}']")
    raise "Path error: node title not found" unless node

    path_no = node.text('summary/path').to_s

    xpath = "records/io/summary[type='input']/*"
    input_nodes = XPath.match(node, xpath)[1..-1]
    input_values = input_nodes.map(&stringify)  + []

    input_names = input_nodes.map(&:name)
    
    summary = XPath.first node, 'summary'
    type, desc = summary.text('type'), summary.text('description')

    xpath = "records/io/summary[type='output']/*"
    raw_output = XPath.match(node, xpath)
    output_values = raw_output.length > 0 ? raw_output[1..-1].map(&stringify) : []
    
    [path_no, input_values, input_names, type, output_values, desc]
  end

  def run(x=nil, debug2=nil)
    @debug2 = debug2 ? true : false
    @success = []
    procs = {NilClass: :test_all, Range: :test_all, String: :test_id, Fixnum: :test_id}

    method(procs[x.class.to_s.to_sym]).call(x)
    summary()
  end

  def test_all(x)
    x ||=(0..-1)

    break_on_fail = XPath.first(@doc.root, 
                            'summary/break_on_fail/text()') == 'true'

    XPath.match(@doc.root, "records/test/summary/path/text()")[x].each do |id|
      result = test_id(id)
      break if result == false and break_on_fail 
    end
  end

  def test_id(id='')

    path_no, inputs, input_names, type, expected, @desc = 
                                          testdata_values(id.to_s)
    @inputs = inputs
    tests() # load the routes

    raw_actual = run_route type
    puts  "warning: no test route found for " + type unless raw_actual

    result = nil
    @success << [nil, path_no.to_i]      

    begin

      if raw_actual then

        a = raw_actual.is_a?(String) ? [raw_actual].flatten.map(&:strip) : raw_actual
        b = expected.map(&:strip)
        #puts 'b :' + b.inspect
        if @debug == true or @debug2 == true then
          
          inputs = input_names.zip(inputs).map{|x| '  ' + x.join(": ")}\
            .join("\n")

          puts "\ninputs: \n" + inputs
          puts "\ntype or description:\n %s: %s" % [type, @desc]
          puts "\nexpected : \n  " + b.inspect
          puts "\nactual : \n  " + a.inspect + "\n"
        end

        result = a == b
      else
        result = [raw_actual].compact == expected
      end

    rescue Exception => e  
      err_label = e.message + " :: \n" + e.backtrace.join("\n")
      raise 'testdata :' + err_label
      result = false
    ensure
      @success[-1][0] = result
      result
    end
  end

  def tests(*args)
    # override this method in the child class
  end

  def read_file(s) 
    buffer = File.open(s, 'r').read
    ext = url[/\.(\w+)$/,1]
    method(('read_' + ext).to_sym).call(buffer)    
  end
    
  def read_url(url)
    buffer = open(url, 'UserAgent' => 'Testdata').read  
    ext = url[/.*\/[^\.]+\.(\w+)/,1]
    method(('read_' + ext).to_sym).call(buffer)
  end

  def read_xml(buffer)
    buffer
  end
  
  def read_td(buffer)
    TestdataText.parse buffer
  end


  def test(s)
    #@inputs = @inputs.first if @inputs.length == 1
    self.add_route(s){yield(*(@inputs + [@desc]))}
  end

  def summary()
    success = @success.map(&:first)
    a = @success.map(&:last).sort
    {
      passed: success.all?,
      score:  [success.grep(true), success].map(&:length).join('/'),
      failed:  @success.select{|x| x[0] == false}.map(&:last).sort
    }
  end
end