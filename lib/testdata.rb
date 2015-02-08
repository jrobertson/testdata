#!/usr/bin/env ruby

# file: testdata.rb

require 'app-routes'
require 'testdata_text'
require 'diffy'


class TestdataException < Exception
end

module Testdata
  
  class Base

    include AppRoutes

    attr_accessor :debug

    def initialize(s, options={})
      
      super()

      @params = {}

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
      @doc = Rexle.new(buffer)
      
      o = {log: false}.merge(options)

      @log =  o[:log] == true ? Rexle.new(tests) : nil
    end

    def run(x=nil, debug2=nil)
      @debug2 = debug2 ? true : false
      @success = []
      procs = {NilClass: :test_all, Range: :test_all, String: :test_id, Fixnum: :test_id}

      method(procs[x.class.to_s.to_sym]).call(x)
      summary()
    end
    
    private
    
    def testdata_values(id)
      
      node = @doc.root.element "records/test[summary/path='#{id}']"

      raise TestdataException, "Path error: node title not found" unless node

      path_no = node.text('summary/path')
      xpath = "records/input/summary/*"
      input_nodes = node.xpath(xpath) #[1..-1]
      input_values = input_nodes.map{|x| x.texts.map(&:unescape).join.strip}  + []

      input_names = input_nodes.map(&:name)
      raise TestdataException, 'inputs not found' if input_values.empty? \
                                                        or input_names.empty?

      summary = node.element 'summary'
      type, desc = summary.text('type'), summary.text('description')

      xpath = "records/output/summary/*"
      output_nodes = node.xpath(xpath) #[1..-1]
      output_values = output_nodes.map{|x| x.texts.map(&:unescape).join.strip}

      [path_no, input_values, input_names, type, output_values, desc]

    end

    def test_all(x)
      x ||=(0..-1)

      break_on_fail = @doc.root.element('summary/break_on_fail/text()') == 'true'

      @doc.root.xpath("records/test/summary/path/text()")[x].each do |id|

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

          if @debug == true or @debug2 == true then
            
            inputs = input_names.zip(inputs).map{|x| '  ' + x.join(": ")}\
              .join("\n")

            puts "\ninputs: \n" + inputs
            puts "\ntype or description:\n %s: %s" % [type, @desc]
            puts "\nexpected : \n  " + b.inspect
            puts "\nactual : \n  " + a.inspect + "\n"
          end

          result = a == b
          
          if (@debug == true or @debug2 == true) and result == false then

            # diff the expected and actual valuess
            puts Diffy::Diff.new(a.first, b.first)
          end
        else
          result = [raw_actual].compact == expected
        end

      rescue Exception => e  
        err_label = e.message + " :: \n" + e.backtrace.join("\n")
        raise TestdataException,  err_label
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

  class Unit
    
    attr_reader :to_s

    def initialize(s)
      
      super()
      @a = []
    
      buffer, _ = RXFHelper.read(s)

      @doc = Rexle.new(buffer)

      @doc.root.xpath('records/test').map do |test|
        
        path, type, description = test.xpath('summary/*/text()')        
        records = test.element('records')        
        
        inputs = records.xpath('input/summary/*').map\
                                            {|x| [x.name, x.texts.join.strip]}

        outputs = records.xpath('output/summary/*').map\
                                            {|x| [x.name, x.texts.join.strip]}
        
        @a << {type: type, in: inputs, out: outputs}
        
      end
    
    end # end of initialize()
    
    def to_s()
=begin
s = %Q(
require_relative "#{testgem}"
require "test/unit"
 
class #{testclass} < Test::Unit::TestCase
 
  def #{types[i]}
    #{@lines.join("\n    ")}
  end
  
end
)
=end
      #read the .rsf file
      script = @doc.root.element('summary/script/text()')
      raise 'script XML entry not found' unless script
      
      if script then
        filename = script[/[\/]+\.rsf$/] 
        buffer, _ = RXFHelper.read(filename)
      end
      #@a.group_by {|x| x[:type]}
      
      
    end
  end
end