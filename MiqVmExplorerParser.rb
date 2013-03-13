#
# Copyright 2007 ManageIQ, Inc.  All rights reserved.
#

require 'ostruct'
require 'rubygems'
require 'MiqVmExplorerOps'

$:.push("#{File.dirname(__FILE__)}/../../lib/util")
require 'miq-option-parser'

class MiqVmExplorerParser < MiqOptionParser::MiqCommandParser
	def initialize
		super()
		self.program_name = ""
		self.exit_on_help = false
		
		@ops = MiqVmExplorerOps.new($miqVmExplorerOptions.vm)
		
		self.add_command(MiqVmExplorerParserCmd_cat.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_cd.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_copyout.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_df.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_exit.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_extract.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_ls.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_find.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_lvdisplay.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_pvdisplay.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_pwd.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_vgdisplay.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_vmmount.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_vmunmount.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_vi.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_volumeinfo.new(@ops))
		
		self.add_command(MiqVmExplorerParserCmd_addems.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_rmems.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_lsems.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_connect.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_disconnect.new(@ops))
		
		self.add_command(MiqVmExplorerParserCmd_lsvms.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_lssnapshots.new(@ops))
		self.add_command(MiqVmExplorerParserCmd_saveconfig.new(@ops))
		
		self.add_command(MiqVmExplorerParserCmd_onlinefleece.new(@ops))
	end # def initialize
end # class MiqVmExplorerParser

class MiqVmExplorerParserCmd_cat < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('cat')
		self.short_desc = "cat files"
	end # def initialize

	def execute(args)
	    @ops.cat(args)
	end
end # class MiqVmExplorerParserCmd_cat

class MiqVmExplorerParserCmd_cd < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('cd')
		self.short_desc = "Change current directory"
	end # def initialize

	def execute(args)
	    @ops.cd(args ? args[0] : nil)
	end
end # class MiqVmExplorerParserCmd_cd

class MiqVmExplorerParserCmd_copyout < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
    @opts = OpenStruct.new
	    
		super('copyout')
		self.short_desc = "Copy files and directories from the VM to the host"
		self.option_parser = OptionParser.new do |opt|
			opt.separator "copyout options:"
			opt.on('-r', '--recursive', "Recursively copy directories.") do
				@opts.recursive = true
			end
			opt.on('-h', '--help', 'Display this help message') do
			    @opts.help = true
				show_help
			end
		end
	end # def initialize

	def execute(args)
	    begin
	        return if @opts.help
	        @ops.copyOut(@opts, args)
	    ensure
	        @opts.marshal_load({})
	    end
	end
end # class MiqVmExplorerParserCmd_copyout

class MiqVmExplorerParserCmd_df < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('df')
		self.short_desc = "Display file system free space"
	end # def initialize

	def execute(args)
	    @ops.df
	end
end # class MiqVmExplorerParserCmd_df

class MiqVmExplorerParserCmd_exit < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('exit')
		self.short_desc = "Exit session"
	end # def initialize

	def execute(args)
	    @ops.exit
	end
end # class MiqVmExplorerParserCmd_exit

class MiqVmExplorerParserCmd_extract < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('extract')
		self.short_desc = "Extract information from the guest OS: accounts, software, services system"
	end # def initialize

	def execute(args)
	    @ops.extract(args)
	end
end # class MiqVmExplorerParserCmd_extract

class MiqVmExplorerParserCmd_find < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
    @opts = OpenStruct.new
	    
		super('find')
		self.short_desc = "Find files in a directory tree"
		self.option_parser = OptionParser.new do |opt|
			opt.separator "find options:"
			opt.on('-d=val', '--depth=val', "The number of directory levels to traverse, below the current directory") do |d|
				@opts.depth = d.to_i
			end
			opt.on('-h', '--help', 'Display this help message') do
			    @opts.help = true
				show_help
			end
			opt.on('-l', '--long', "Produce a 'long' listing.") do
				@opts.long = true
			end
			opt.on('-n=val', '--name=val', "Look for files matching the given 'name'") do |n|
				@opts.name = n
			end
			opt.on('-t=val', '--type=val', "Find files of this type (d = directory, f = file, l = symbolic link)") do |t|
				@opts.ftype = t
			end
		end
	end # def initialize

	def execute(args)
	    begin
	        return if @opts.help
	        @ops.find(@opts, args)
	    ensure
	        @opts.marshal_load({})
	    end
	end
end # class MiqVmExplorerParserCmd_find

class MiqVmExplorerParserCmd_ls < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
    @opts = OpenStruct.new
	    
		super('ls')
		self.short_desc = "List files in the current or named directory"
		self.option_parser = OptionParser.new do |opt|
			opt.separator "ls options:"
			opt.on('-l', '--long', "Produce a 'long' listing.") do
				@opts.long = true
			end
			opt.on('-d', "If target is a directory, list its attributes, not its contents") do
				@opts.dir = true
			end
			opt.on('-h', '--help', 'Display this help message') do
			    @opts.help = true
				show_help
			end
		end
	end # def initialize

	def execute(args)
	    begin
	        return if @opts.help
	        @ops.ls(@opts, args)
	    ensure
	        @opts.marshal_load({})
	    end
	end
end # class MiqVmExplorerParserCmd_ls

class MiqVmExplorerParserCmd_lvdisplay < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('lvdisplay')
		self.short_desc = "Display logical volume information"
	end # def initialize

	def execute(args)
	    @ops.lvdisplay
	end
end # class MiqVmExplorerParserCmd_lvdisplay

class MiqVmExplorerParserCmd_pvdisplay < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('pvdisplay')
		self.short_desc = "Display physical volume information"
	end # def initialize

	def execute(args)
	    @ops.pvdisplay
	end
end # class MiqVmExplorerParserCmd_pvdisplay

class MiqVmExplorerParserCmd_pwd < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('pwd')
		self.short_desc = "Display the current directory"
	end # def initialize

	def execute(args)
	    @ops.pwd
	end
end # class MiqVmExplorerParserCmd_pwd

class MiqVmExplorerParserCmd_vgdisplay < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('vgdisplay')
		self.short_desc = "Display volume group information"
	end # def initialize

	def execute(args)
	    @ops.vgdisplay
	end
end # class MiqVmExplorerParserCmd_vgdisplay

class MiqVmExplorerParserCmd_vmmount < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
    @opts = OpenStruct.new
	    
		super('vmmount')
		self.short_desc = "Mount the given VM"
		self.option_parser = OptionParser.new do |opt|
			opt.separator "vmmount options:"
			opt.on('-s=val', '--snapshot=val', "Mount the given snapshot of the VM") do |sid|
				@opts.snapId = sid
			end
			opt.on('-h', '--help', 'Display this help message') do
			    @opts.help = true
				show_help
			end
		end
	end # def initialize

	def execute(args)
	    begin
	        return if @opts.help
	        @ops.vmmount(@opts, args)
	    ensure
	        @opts.marshal_load({})
	    end
	end
end # class MiqVmExplorerParserCmd_vmmount

class MiqVmExplorerParserCmd_vmunmount < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('vmunmount')
		self.short_desc = "Unmount the current VM"
	end # def initialize

	def execute(args)
	    @ops.vmunmount
	end
end # class MiqVmExplorerParserCmd_vmunmount

class MiqVmExplorerParserCmd_vi < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('vi')
		self.short_desc = "The vi editor"
	end # def initialize

	def execute(args)
	    @ops.vi
	end
end # class MiqVmExplorerParserCmd_vi

class MiqVmExplorerParserCmd_volumeinfo < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('volumeinfo')
		self.short_desc = "Display storage volume information as xml"
	end # def initialize

	def execute(args)
	    @ops.volumeinfo
	end
end # class MiqVmExplorerParserCmd_volumeinfo

class MiqVmExplorerParserCmd_addems < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
    @opts = OpenStruct.new
	    
		super('addems')
		self.short_desc = "Define an external management system"
		self.option_parser = OptionParser.new do |opt|
			opt.separator "addems options:"
			opt.on('-s=val', '--server=val', "The hostname or IP address of the EMS server") do |s|
				@opts.server = s
			end
			opt.on('-h', '--help', 'Display this help message') do
			    @opts.help = true
				show_help
			end
			opt.on('-u=val', '--username=val', "User name for authentication") do |u|
				@opts.username = u
			end
			opt.on('-p=val', '--passowrd=val', "Password for authentication") do |p|
				@opts.password = p
			end
			opt.on('-t=val', '--type=val', "EMS type (VIM)") do |t|
				@opts.etype = t
			end
			opt.on('-n=val', '--name=val', "User defined EMS name") do |n|
				@opts.name = n
			end
		end
	end # def initialize

	def execute(args)
	    begin
	        return if @opts.help
	        @ops.addems(@opts)
	    ensure
	        @opts.marshal_load({})
	    end
	end
end # class MiqVmExplorerParserCmd_addems

class MiqVmExplorerParserCmd_lsems < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('lsems')
		self.short_desc = "Display the currently defined external management systems"
	end # def initialize

	def execute(args)
	    @ops.lsems
	end
end # class MiqVmExplorerParserCmd_lsems

class MiqVmExplorerParserCmd_rmems < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('rmems')
		self.short_desc = "Remove the given external management system"
	end # def initialize

	def execute(args)
	    @ops.rmems(args)
	end
end # class MiqVmExplorerParserCmd_rmems

class MiqVmExplorerParserCmd_connect < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('connect')
		self.short_desc = "Connect to the given external management system"
	end # def initialize

	def execute(args)
	    @ops.connect(args)
	end
end # class MiqVmExplorerParserCmd_connect

class MiqVmExplorerParserCmd_disconnect < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('disconnect')
		self.short_desc = "Disconnect from the current external management system"
	end # def initialize

	def execute(args)
	    @ops.disconnect
	end
end # class MiqVmExplorerParserCmd_disconnect

class MiqVmExplorerParserCmd_lsvms < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
    @opts = OpenStruct.new
	    
		super('lsvms')
		self.short_desc = "List the VMs discovered on the current external management system"
		self.option_parser = OptionParser.new do |opt|
			opt.separator "lsvms options:"
			opt.on('--host', "Include the VM's host in the listing") do
				@opts.host = true
			end
			opt.on('-h', '--help', 'Display this help message') do
			    @opts.help = true
				show_help
			end
			opt.on('--path', "Include the VM's path in the listing") do
				@opts.path = true
			end
			opt.on('-l', "List all of the information for the VM") do
				@opts.host = true
				@opts.path = true
			end
		end
	end # def initialize

	def execute(args)
	    begin
	        return if @opts.help
	        @ops.lsvms(@opts)
	    ensure
	        @opts.marshal_load({})
	    end
	end
end # class MiqVmExplorerParserCmd_lsvms


class MiqVmExplorerParserCmd_saveconfig < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('saveconfig')
		self.short_desc = "Save the current configuration"
	end # def initialize

	def execute(args)
	    @ops.saveconfig
	end
end # class MiqVmExplorerParserCmd_saveconfig

class MiqVmExplorerParserCmd_onlinefleece < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
		super('onlinefleece')
		self.short_desc = "Enable fleecing of online VMs"
	end # def initialize

	def execute(args)
	    @ops.onlinefleece(args)
	end
end # class MiqVmExplorerParserCmd_onlinefleece

class MiqVmExplorerParserCmd_lssnapshots < MiqOptionParser::MiqCommand
	def initialize(ops)
    @ops = ops
    @opts = OpenStruct.new
	    
		super('lssnapshots')
		self.short_desc = "List snapshots of the given VM"
		self.option_parser = OptionParser.new do |opt|
			opt.separator "lssnapshots options:"
			opt.on('-d', '--description', "Include the snapshot's description in the listing") do
				@opts.description = true
			end
			opt.on('-h', '--help', 'Display this help message') do
			    @opts.help = true
				show_help
			end
		end
	end # def initialize

	def execute(args)
	    begin
	        return if @opts.help
	        @ops.lssnapshots(@opts, args)
	    ensure
	        @opts.marshal_load({})
	    end
	end
end # class MiqVmExplorerParserCmd_ls
