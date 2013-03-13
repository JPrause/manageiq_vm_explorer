#
# Copyright 2007 ManageIQ, Inc.  All rights reserved.
#

$:.push("#{File.dirname(__FILE__)}/../../lib")
require 'bundler_setup'

require 'ostruct'
require 'rubygems'
require 'log4r'
require 'shellwords'
require 'yaml'

$:.push("#{File.dirname(__FILE__)}/../../lib/util")
require 'miq-option-parser'

include Shellwords

begin
    $haveReadline = true
    require 'readline'
    include Readline
rescue LoadError => err
    $haveReadline = false
end

$: << File.dirname(__FILE__)

require 'MiqVmExplorerParser'
require 'EmsConnection'

#
# Main command setup.
#
class MiqVmExplorerOptions < MiqOptionParser::MiqCommandParser
	def initialize
		super()
		self.program_name      = $0
		self.handle_exceptions = true
		
		$log = Log4r::Logger.new 'toplog'
		$miqVmExplorerOptions.logLevel = Log4r::ERROR

    #
    # Main command options.
    #
    self.option_parser = OptionParser.new do |opt|
        opt.separator "Global options:"
        opt.on('-v=val', '--vm=val', 'Virtual machine config file') do |v|
            $miqVmExplorerOptions.vm = v
        end
        
        opt.on('--loglevel=val', 'Set the log level (debug, info, warn or error)') do |v|
            $miqVmExplorerOptions.logLevel = case
            when v == 'debug'  then Log4r::DEBUG
            when v == 'info'   then Log4r::INFO
            when v == 'warn'   then Log4r::WARN
            when v == 'error'  then Log4r::ERROR
            else
              $stderr.puts "Unrecognized log level: #{v}"
              exit(1)
            end
        end
    end
		
		self.add_command(MiqVmExplorerDo.new, true)
	end # def initialize
end # MiqVmExplorerOptions

class MiqVmExplorerDo < MiqOptionParser::MiqCommand
	def initialize
		super('do')
	end # def initialize

	def execute(args)
    Log4r::StderrOutputter.new('err_console', :level=>$miqVmExplorerOptions.logLevel, :formatter=>ConsoleFormatter)
    $log.add 'err_console'
      
    if args.length == 0
        #
        # No command supplied, enter interactive mode.
        #
        puts "MiqVmExplorer, interactive mode."
        cmdLoop
    else
        #
        # Run single command then exit.
        #
        puts "MiqVmExplorer, executing: #{args.inspect}"
        miqvep = MiqVmExplorerParser.new
        miqvep.parse(args)
        exit(0)
    end
	end
	
	private
	
	#
	# Interactive command loop processing.
	#
	def cmdLoop
        miqvep = MiqVmExplorerParser.new
        trap("INT") { raise "Interrupt" }
        begin
            while true
                if $haveReadline
                    input = readline("MiqExplorer: ", true)
                else
                    $stderr.print "MiqExplorer: "
                    input = $stdin.gets.chomp
                end
        
                #
                # Skip empty commands and comments.
                #
                next if input.length == 0
                next if input =~ /^\s*#/
        
                #
                # Process the command.
                #
                miqvep.parse(shellParse(input))
            
                #
                # If I/O was redirected, set it back to the console.
                #
                if $miqOut != $stdout
                    $miqOut.close
                    $miqOut = $stdout
                end
            end
        rescue  MiqOptionParser::ParseError,OptionParser::ParseError => perr
            $stderr.puts perr.message
            $log.debug perr.backtrace.join("\n")
            retry
        rescue => err
            $stderr.puts err.backtrace.join("\n")
            $stderr.puts err.to_s
            $log.debug err.backtrace.join("\n")
            retry
        end
    end
    
    #
    # Handle shell-like things, like I/O redirection and pipes.
    #
    def shellParse(input)
        #input.gsub!("\\", "\\\\\\") # Allows '\' chars in windows paths to be handled properly in shellwords
        argv = shellwords(input)
        return(argv) if !(rdi = argv.index('|') || argv.index('>>') || argv.index('>'))
        
        rda = argv.slice!(rdi..-1)
        begin
            if rda[0] == '|'
                raise MiqRedirectError.new(), "Missing pipe target command" if rda.length < 2
                $miqOut = IO.popen(rda[1..-1].join(" "), "w")
            else
                raise MiqRedirectError.new(), "\"#{rda.join(' ')}\"" if rda.length != 2
                $miqOut = File.new(rda[1], rda[0] == '>' ? "w" : "a")
            end
        rescue => err
            raise MiqRedirectError.new(), err.to_s
        end
        return(argv)
    end
end # class MiqVmExplorerDo

class MiqRedirectError < MiqOptionParser::ParseError
    reason 'Invalid I/O redirection'
end

#
# Formatter to output log messages to the console.
#
class ConsoleFormatter < Log4r::Formatter
	def format(event)
		(event.data.kind_of?(String) ? event.data : event.data.inspect) + "\n"
	end
end

$miqOut = $stdout

$configFile = File.join(ENV["HOME"] ? ENV["HOME"] : ENV["HOMEPATH"], "miqvme.yaml")

if File.exists? $configFile
    puts "Loading config file: #{$configFile}"
    cfg = YAML.load_file($configFile)
    $miqVmExplorerOptions           = cfg[:options]     || OpenStruct.new
    $emsConnections                 = cfg[:connections] || EmsConnections.new
    $miqHostCfg                     = cfg[:hostConfig]  || OpenStruct.new
else
    $miqVmExplorerOptions           = OpenStruct.new
    $emsConnections                 = EmsConnections.new
    $miqHostCfg                     = OpenStruct.new
    $miqHostCfg.forceFleeceDefault  = false
end

miqveo = MiqVmExplorerOptions.new
miqveo.parse
