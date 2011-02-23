#!/usr/bin/ruby

# file: testdata.rb

require 'rexle'
require 'rscript'
require 'rexle-builder'
require 'rexml/document'


class Path
  include REXML

  def initialize(doc, log, success) 
    @doc, @log, @success = doc, log, success 
  end

  def tested? description

    stringify = Proc.new {|x| x.text.to_s.gsub(/[\n\s]/,'').length > 0 ? x.text : x.cdatas.join.strip}

    node = XPath.first(@doc.root, "records/test[summary/description='#{description}']")
    raise "Path error: node title not found" unless node
    input_values = XPath.match(node, "records/io/summary[type='input']/*").map(&stringify)
    output_values = XPath.match(node, "records/io/summary[type='output']/*").map(&stringify)

    path_no = node.text('summary/path')

    if @log then
      node_result = XPath.first(@log.root, "records/result[path_no='#{path_no}']")
      actual = XPath.first(node_result, "actual")  
    end

    puts 'path_no : ' + path_no
    
    result = nil
    @success << [nil, path_no.to_i]      
    
    begin

      values = input_values - ['input']
      expected = (output_values - ['output'])
       
      yield

      raw_result =  test(*values)

      if raw_result then
        a = [raw_result].flatten.map(&:strip)
        b = expected.map(&:strip)

        # actual.text is used by the log file
        actual.text = a.join("\n")[/</] ? CData.new("\n%s\n" % a.join("\n")) : a.join("\n") if @log

        #puts 'a : ' + a.inspect + ' : ' + a[0].length.to_s
        #puts 'b : ' + b.inspect + ' b :' + b[0].length.to_s

        result = a == b
      else
        result = [raw_result].compact == expected
      end

    rescue Exception => e  
      err_label = e.message + " :: \n" + e.backtrace.join("\n")

      puts err_label
      XPath.first(node_result, "error").text = err_label
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
 
  def initialize(s, options={})
    #puts 'filex : ' + $0
    #puts 'filez : ' + __FILE__
    #puts 'pwd : ' + Dir.pwd
    #exit

    o = {log: false}.merge(options)

    @filepath = File.dirname s
    buffer = self.send('read_' + (s[/https?:\/\//] ? 'file' : 'url'), s)   
    @doc = Document.new(buffer)
    raise "Testdata error: doc %s not found" % s unless @doc
    @success = []

    @log =  o[:log] == true ? Document.new(tests) : nil
  end

  def paths() 
    yield(path = Path.new(@doc, @log, @success)) 
    File.open(Dir.pwd + '/.test_log.xml','w'){|f| f.write @log } if @log
  end

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

  private

  def tests()
    script_file = XPath.first(@doc.root, "summary/script/text()").to_s

    if script_file[/\/\/job:/] then
      s = RScript.new.read(script_file.split(/\s/)).first
    else

      file_path = File.exists?(script_file) ? script_file : @filepath + '/' + script_file
      s = File.open(file_path,'r').read
    end

    stringify = Proc.new {|x| x.text.to_s.gsub(/[\n\s]/,'').length > 0 ? x.text : x.cdatas.join.strip}

    raw_paths = s[/testdata\.paths(.*)(?=end)/m,1].split(/(?=path\.tested\?)/)
    raw_paths.shift

    content = raw_paths.map do |x|
      title = x[/path\.tested\?\s(.*)\sdo/,1][1..-2]
      path_test = x[/def.*(?=end)/m]
      raw_vars = path_test[/def path.test\(([^\)]+)/,1]
      vars = raw_vars.split(/\s*,\s*/) if raw_vars
      body = path_test[/def path\.test\([^\)]*\)(.*)(?=end)/m,1]
      [title, vars, body]
    end

    r = (0..content.length - 1).map do |i|
      node = XPath.first(@doc.root, "records/test[#{i+1}]")
      input_values = XPath.match(node, "records/io/summary[type='input']/*").map(&stringify)
      path_no = node.text('summary/path').to_s
      output_values = XPath.match(node, "records/io/summary[type='output']/*").map(&stringify)
      raw_output = (output_values - ['output'])
      output = raw_output.join("\n")

      values = input_values - ['input']
      body = content[i][2].strip.gsub("\n      ","\n")
      if content[i][1] then
        content[i][1].zip(values).reverse.each do |keyword, value|
          body.gsub!(/#{keyword}(?!:)/, "'%s'" % value )
        end
      end
      #puts 'xxxxx : ' + body.to_s
      [path_no, content[i][0], body, output]  
    end

    #r.each {|x| x.join("\n")}.join("\n")
    tests_to_dynarex(r)
  end

  def tests_to_dynarex(tests)

    xml = RexleBuilder.new

    a = xml.results do
      xml.summary do
        xml.recordx_type 'dynarex'
        xml.format_mask '[!path_no] [!title] [!test] [!expected] [!actual]'
        xml.schema 'results/result(path_no, title, test, expected, actual)'
      end
      xml.records do
        tests.each do |path_no, title, testx, expected|

          xml.result do
            xml.path_no path_no
            xml.title title

            if testx[/[<>]/] then
              xml.testx do
                xml.cdata!("\n%s\n" % testx)
              end
            else
              xml.testx testx            
            end

            if expected[/</] then
              xml.expected do
                xml.cdata!("\n%s\n" % expected) 
              end
            else
              xml.expected  expected
            end

            xml.actual
            xml.error
          end
        end
      end
    end    

    Rexle.new(a).xml pretty: true
  end

end
