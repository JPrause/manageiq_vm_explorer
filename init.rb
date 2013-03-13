initStr = ENV.fetch("MIQ_INIT_STR", nil).unpack('m').join
ENV["MIQ_INIT_STR"] = "XXXX"
$: << "#{File.dirname(__FILE__)}/lib/encryption"
eval(initStr)
require "MiqLoad"

$0 = ENV.fetch("MIQ_EXE_NAME", $0).chomp(".exe")

$stdout.print "Hit <return> to continue: "
$stdout.flush
rv = $stdin.gets


require "#{File.dirname(__FILE__)}/tools/MiqVmExplorer/MiqVmExplorer.rb"