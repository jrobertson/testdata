#!/usr/bin/ruby

# file: testdata.rb

require 'rexml/document'
require 'app-routes'

class Testdata
  include REXML
  include AppRoutes

  attr_accessor :debug

  def initialize(s, options={})
    @route = {}; @params = {} # used by app-routes
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
      REXML::Text::unnormalize(r)
    end

    node = XPath.first(@doc.root, "records/test[summary/path='#{id}']")
    raise "Path error: node title not found" unless node

    path_no = node.text('summary/path').to_s

    xpath = "records/io/summary[type='input']/*"
    input_nodes = XPath.match(node, xpath)[1..-1]
    input_values = input_nodes.map(&stringify)   
    input_names = input_nodes.map(&:name)
    
    # find the type or description
    xpath = "summary/type/text() | summary/description/text()"
    type_or_desc = XPath.match(node, xpath).map(&:to_s).find{|x| x != ''}

    xpath = "records/io/summary[type='output']/*"
    raw_output = XPath.match(node, xpath)
    output_values = raw_output.length > 0 ? raw_output[1..-1].map(&stringify) : []
    
    [path_no, input_values, input_names, type_or_desc, output_values]
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

    XPath.match(@doc.root, "records/test/summary/path/text()")[x].each do |id|
      puts 'id : ' + id.to_s
      test_id(id)
    end
  end

  def test_id(id='')

    path_no, @inputs, input_names, tod, expected = testdata_values(id.to_s)
    tests() # load the routes
    raw_actual = run_route tod

    result = nil
    @success << [nil, path_no.to_i]      

    begin

      if raw_actual then

        a = raw_actual.is_a?(String) ? [raw_actual].flatten.map(&:strip) : raw_actual
        b = expected.map(&:strip)

        if @debug == true or @debug2 == true then
          inputs = input_names.zip(@inputs).map{|x| '  ' + x.join(": ")}\
            .join("\n")
          puts "\ninputs: \n" + inputs
          puts "\ntype or description:\n  " + tod
          puts "\nexpected : \n  " + b.inspect
          puts "\nactual : \n  " + a.inspect + "\n"
        end

        result = a == b
      else
        result = [raw_actual].compact == expected
      end

    rescue Exception => e  
      err_label = e.message + " :: \n" + e.backtrace.join("\n")

      puts err_label
      result = false
    ensure
      @success[-1][0] = result
    end
  end

  def tests(*args)
    # override this method in the child class
  end

  def read_file(s) File.open(s, 'r').read  end
  def read_url(xml_url)  open(xml_url, 'UserAgent' => 'S-Rscript').read  end

  def test(s)
    @inputs = @inputs.first if @inputs.length == 1
    get(s){yield(@inputs)}
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
