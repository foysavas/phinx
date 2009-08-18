require 'rubygems'
require 'erubis'

DIR = File.dirname(__FILE__)

class Phinx
  attr_accessor :port
  attr_accessor :conf
  attr_accessor :php_pid

  def initialize
    @port = 4000
    @conf = "default"
  end

  def prepare_dirs
    system("mkdir -p pid; mkdir -p tmp; mkdir -p logs")
  end

  def create_config
    system("rm nginx_tmp.conf")
    input = File.read("#{DIR}/confs/#{conf}.conf.erb")
    eruby = Erubis::Eruby.new(input)
    result = eruby.result(:port => @port, :conf => @conf, :pwd => Dir.pwd)
    out = File.new("nginx_tmp.conf","w+")
    out.puts result
    out.close
    # erb template for nginx.conf
  end

  def start_nginx
    system("nginx -c $PWD/nginx_tmp.conf -p $PWD/")
  end

  def start_php
    @php_pid = Process.fork do 
      exec("php-cgi -e -b #{@port+1}")
    end
  end

  def stop_php
    Process.kill("HUP", @php_pid)
    Process.wait
  end

  def stop_nginx
    system("nginx -s stop -c $PWD/nginx_tmp.conf -p $PWD/")
  end

  def clean_dirs
    system("rm -rf client_body_temp; rm -rf fastcgi_temp; rm -rf proxy_temp; rm -rf pid")
  end

  def start
    prepare_dirs
    create_config
    start_nginx
    start_php
  end

  def stop
    stop_php
    stop_nginx
    clean_dirs
  end
end

phinx = Phinx.new
if ARGV[0]
  phinx.port = ARGV[0].to_i
end
if ARGV[1]
  phinx.conf = ARGV[1]
end

puts "Starting Phinx with #{phinx.conf} config on port #{phinx.port}..."
phinx.start

interrupted = false

while !interrupted
  trap("INT") { interrupted = true }
end

puts
puts "Stoping Phinx..."
phinx.stop
exit
