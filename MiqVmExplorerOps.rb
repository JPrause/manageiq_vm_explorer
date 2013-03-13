#
# Copyright 2007 ManageIQ, Inc.  All rights reserved.
#

require 'ostruct'
require 'rubygems'

$:.push("#{File.dirname(__FILE__)}/../../lib/util")
require 'miq-option-parser'

$:.push("#{File.dirname(__FILE__)}/../../lib/MiqVm")

require 'MiqVm'
require 'EmsConnection'

class MiqVmExplorerOps
    
    def initialize(vmCfg)
        @vm     = nil
        @vmRoot = nil
        
        @vmSearchPath = initVmSearchPath
        
        return  if !vmCfg
        vmmount(nil, vmCfg)
    end
    
    def vm
        return @vm if @vm
        raise "Current VM has not been set." if !@vm
    end
    
    #
    # Get the VM's root node
    #
    def vmRoot
        return @vmRoot if @vmRoot
        @vmRoot = vm.vmRootTrees
        raise "Could not mount VMs file systems." if !@vmRoot || @vmRoot.length == 0
        @vmRoot = @vmRoot[0]
        return(@vmRoot)
    end
    
    #
    # Cat files from the VM.
    #
    def cat(files)
        shExpand(files).each do |f|
            if vmRoot.fileDirectory?(f)
                $stderr.puts "Skipping directory: #{f}"
                next
            end
            vmRoot.fileOpen(f) do |ffo|
                while (buf = ffo.read(1024))
                    $miqOut.write(buf)
                end
            end
        end # allTargets.each
    end
    
    #
    # Change the current directory
    #
    def cd(dir)
        return if !dir
        vmRoot.chdir(dir)
        $miqOut.puts "Current directory: #{vmRoot.pwd}"
    end
    
    #
    # Copy files and directories from the VM to the host.
    #
    def copyOut(opts, args)
        raise MiqOptionParser::ParseError, "Source and destination are required" if args.length < 2
        vmRoot.copyOut(args[0..-2], args[-1], opts.recursive)
    end
    
    #
    # Display file system information
    #
    def df
        vmRoot.fileSystems.each do |fsd|
            $miqOut.puts "FS: #{fsd.fsSpec}, Mounted on: #{fsd.mountPoint}, Type: #{fsd.fs.fsType}, Free bytes: #{fsd.fs.freeBytes}"
        end
    end
    
    #
    # Exit the program
    #
    def exit
        Kernel.exit(0)
    end
    
    #
    # Extract information from Guest OS:
    #   "accounts"
    #   "services"
    #   "software"
    #
    def extract(categories)
      [categories].flatten.each { |c|
        xml = vm.extract(c)
        xml.write($miqOut, 4)
        $miqOut.puts
      }
    end
    
    #
    # Find files in a directory tree.
    #
    def find(opts, dir)
        raise MiqOptionParser::ParseError, "No source directory given" if dir.length == 0
        raise MiqOptionParser::ParseError, "Multiple source directories not supported" if dir.length > 1
        vmRoot.findEach(dir[0], opts.depth) do |f|
            if opts.ftype
                case opts.ftype
                    when 'd' then next if !vmRoot.fileDirectory?(f)
                    when 'f' then next if !vmRoot.fileFile?(f)
                    when 'l' then next if !vmRoot.fileSymLink?(f)
                    else raise OptionParser::ParseError, "Invalid file type: #{opts.ftype}"
                end
            end
            next if opts.name && !File.fnmatch(opts.name, File.basename(f))

            lsFile(opts, f, f)
        end
    end
    
    #
    # List files and directories
    #
    def ls(opts, targets)
        targets = [ vmRoot.pwd ] if !targets || targets.length == 0
        shExpand(targets).each do |d|
            if vmRoot.fileFile?(d) || opts.dir
                lsFile(opts, d, d)
                next
            end
            $miqOut.puts "#{d}:"
            begin
                vmRoot.dirForeach(d) do |de|
                    next if de == "." || de == ".."
                    fp = File.join(d, de)
                    lsFile(opts, de, fp)
                end
            rescue => err
                puts "Could not access #{d}, #{err}"
            end
        end
    end
    
    def lsFile(opts, de, f)
        if opts.long
            type = 'F' if vmRoot.fileFile?(f)
            type = 'D' if vmRoot.fileDirectory?(f)
            if vmRoot.fileSymLink?(f)
                type = 'L'
                linkInfo = " -> #{vmRoot.getLinkPath(f)}"
            else
                linkInfo = ""
            end
            size = vmRoot.fileSize(f)
            mtime = vmRoot.fileMtime(f)
            
            $miqOut.puts "\t#{type}\t#{size}\t#{mtime}\t#{de}#{linkInfo}"
        else
            $miqOut.puts "\t#{de}"
        end
    end
    
    #
    # Display logical volume information
    #
    def lvdisplay
        if (lva = vm.volumeManager.logicalVolumes).length == 0
            $miqOut.puts "No logical volumes found"
            return
        end
        lva.each do |dobj|
            lvObj = dobj.dInfo.lvObj
            $miqOut.puts "\n#{lvObj.lvName}:"
            $miqOut.puts "\tType:         #{dobj.diskType}"
            $miqOut.puts "\tSize:         #{dobj.size}"
            $miqOut.puts "\tLV Id:        #{lvObj.lvId}"
            $miqOut.puts "\tVolume Group: #{lvObj.vgObj.vgName}"
        end
    end
    
    #
    # Display physical volume information
    #
    def pvdisplay
        if (pva = vm.volumeManager.allPhysicalVolumes).length == 0
            $miqOut.puts "No physical volumes found"
            return
        end
        pva.each do |dobj|
            $miqOut.puts "\n#{dobj.hwId}:"
            $miqOut.puts "\tDisk Type:         #{dobj.diskType}"
            $miqOut.puts "\tPartition:         #{dobj.partNum}"
            $miqOut.puts "\tPartition Type:    #{dobj.partType}"
            $miqOut.puts "\tSize:              #{dobj.size}"
            $miqOut.puts "\tVirtual Disk File: #{dobj.dInfo.fileName}"
            $miqOut.puts "\tOS Specific Name:  #{vmRoot.osNames[dobj.hwId]}" if vmRoot.osNames
            
            if dobj.pvObj
                $miqOut.puts "\tVolume Group:      #{dobj.pvObj.vgObj.vgName}"
                $miqOut.puts "\tPV Id:             #{dobj.pvObj.pvId}"
            end
        end
    end
    
    #
    # Display the current directory
    #
    def pwd
        $miqOut.puts vmRoot.pwd
    end
    
    #
    # Display volume group information
    #
    def vgdisplay
        if (vgh = vm.volumeManager.vgHash).length == 0
            $miqOut.puts "No volume groups found"
            return
        end
        
        vgh.each do |vgn, vgo|
            $miqOut.puts "\n#{vgn}:"
            pext = 0
            lext = 0
            
            $miqOut.puts "\tPhysical Volumes:"
            vgo.physicalVolumes.each do |pvn, pvo|
                $miqOut.puts "\t\t#{pvn}:"
                $miqOut.puts "\t\t\tPV Id:             #{pvo.pvId}"
                $miqOut.puts "\t\t\tHardware Id:       #{pvo.diskObj.hwId}"
                $miqOut.puts "\t\t\tOS Specific Name:  #{pvo.device}"
                $miqOut.puts "\t\t\tPhysical Extents:  #{pvo.peCount}"
                $miqOut.puts "\t\t\tVirtual Disk File: #{pvo.diskObj.dInfo.fileName}"
                pext += pvo.peCount
            end
            
            $miqOut.puts "\n\tLogical Volumes:"
            vgo.logicalVolumes.each do |lvn, lvo|
                $miqOut.puts "\t\t#{lvn}:"
                $miqOut.puts "\t\t\tLV Id: #{lvo.lvId}"
                
                lvo.segments.each { |s| lext += s.extentCount }
            end
            
            $miqOut.puts "\n\tExtent Size:    #{vgo.extentSize} (sectors)"
            $miqOut.puts "\tPhysical Extents: #{pext}"
            $miqOut.puts "\tLogical Extents:  #{lext}"
            $miqOut.puts "\tFree Extents:     #{pext-lext}"
        end
        $miqOut.puts
    end
    
    #
    # Mount the given VM.
    # If a VM is currently mounted, unmount it before mounting the new one.
    #
    def vmmount(opts, cfg)
        cfg = cfg[0] if cfg.kind_of? Array
        raise "No VM given" if !cfg
        
        if $emsConnections.currentConnection
            vmId = $emsConnections.currentConnection.vmsByName[cfg][:path] || cfg
            ost = OpenStruct.new
            ost.miqVim = $emsConnections.currentConnection.connection
            ost.snapId = opts.snapId if opts && opts.snapId
            nvm = MiqVm.new(vmId, ost)
        else
            nvm = MiqVm.new(searchVmCfg(cfg))
        end
        vmunmount if @vm
        @vm = nvm
    end
    
    #
    # Unmount the current VM.
    #
    def vmunmount
        raise "No VM currently mounted" if !@vm
        @vm.unmount
        @vm = nil
        @vmRoot = nil
    end
    
    #
    # vi - For Sammy
    #
    def vi
        puts 'The "vi" command is not available in the "free" demo version of this product.'
        puts 'Please upgrade to the "pro" version ($1650.00) to obtain access to this feature.'
    end
    
    #
    # Display storage volume information, as xml.
    #
    def volumeinfo
        vm.vmRootTrees
        doc = vm.volumeManager.toXml
        doc.write($miqOut, 4)
        $miqOut.puts
    end
    
    #
    # Define an External Management System.
    #
    def addems(opts)
        raise MiqOptionParser::ParseError, "No server given"   if !opts.server
        raise MiqOptionParser::ParseError, "No username given" if !opts.username
        raise MiqOptionParser::ParseError, "No password given" if !opts.password
        
        $emsConnections.addConnection(:server     => opts.server,
                                      :username   => opts.username,
                                      :password   => opts.password,
                                      :type       => opts.etype || "VIM",
                                      :name       => opts.name
        )
    end
    
    #
    # List defined external management systems.
    #
    def lsems
        $emsConnections.connections.each do |c|
            $miqOut.puts "ID: #{c[:cId]},\tserver: #{c[:server]},\ttype: #{c[:type]}" + ($emsConnections.isCurrent?(c) ? ",\t*current" : "")
        end
    end
    
    #
    # Remove the given external management system.
    #
    def rmems(cids)
        raise "No EMS given" if cids.length == 0
        cids.each do |cid|
            $emsConnections.deleteConnection(cid)
        end
    end
    
    #
    # Connect to the given external management system.
    #
    def connect(cids)
        raise "Invalid EMS given" if cids.length != 1
        puts "Connecting to #{cids[0]}..."
        $emsConnections.currentConnection = cids[0]
        puts "done"
    end
    
    #
    # Disconnect from the current external management system.
    #
    def disconnect
        $emsConnections.close
    end
    
    #
    # List the VMs discovered on the current external management system.
    #
    def lsvms(opts)
        raise "No current connection" if !(cc = $emsConnections.currentConnection)
        
        maxNameLen = 0
        maxHostLen = 0
        cc.vmsByName.each_value do |vm|
            maxNameLen = vm[:name].length if vm[:name].length > maxNameLen
            maxHostLen = vm[:host].length if vm[:host].length > maxHostLen
        end
        cc.vmsByName.keys.sort.each do |vmn|
            $miqOut.print cc.vmsByName[vmn][:name].ljust(maxNameLen+4)
            $miqOut.print cc.vmsByName[vmn][:host].ljust(maxHostLen+4) if opts.host
            $miqOut.print cc.vmsByName[vmn][:path] if opts.path
            $miqOut.print "\n"
        end
    end
    
    def saveconfig
        puts "Saving configuration to: #{$configFile}"
        f = File.open($configFile, "w")
        if (cCon = $emsConnections.currentConnection)
            vmsByName = cCon.vmsByName
            cCon.vmsByName = Hash.new
            connection = cCon.connection
            cCon.connection = nil
            $emsConnections.setCc(nil)
        end
        YAML.dump({ :options => $miqVmExplorerOptions, :connections => $emsConnections, :hostConfig => $miqHostCfg }, f)
        f.close
        if cCon
            cCon.vmsByName = vmsByName
            cCon.connection = connection
            $emsConnections.setCc(cCon)
        end
    end
    
    def onlinefleece(args)
        if args.empty?
            puts "Online fleecing: #{$miqHostCfg.forceFleeceDefault ? "enabled" : "disabled"}"
            return
        end
        
        case args[0].downcase
        when /enabled|enable|on|yes|y/
            $miqHostCfg.forceFleeceDefault  = true
            puts "Online fleecing: enabled"
        when /disabled|disable|off|no|n/
            $miqHostCfg.forceFleeceDefault  = false
            puts "Online fleecing: disabled"
        else
            raise MiqOptionParser::ParseError, "Unrecognized onlinefleece directive: #{args[0]}"
        end
    end
    
    def lssnapshots(opts, args)
        raise "No current connection" if !(cc = $emsConnections.currentConnection)
        raise "No VM given" if args.empty?
        
        vmId = $emsConnections.currentConnection.vmsByName[args[0]][:path]
        miqVim = $emsConnections.currentConnection.connection
        miqVimVm = miqVim.getVimVm(vmId)
        ssInfo = miqVimVm.snapshotInfo(true)
        raise "VM has no snapshots" if !ssInfo
        
        printSnapshotTree(ssInfo['rootSnapshotList'], ssInfo['currentSnapshot'], opts)
    end
    
    private
    
    def printSnapshotTree(root, current, opts, indent="")
        $miqOut.print indent
        $miqOut.print root['name']
        $miqOut.print "\t" + root['createTime']
        $miqOut.print "\t" + root['description'] if opts.description
        $miqOut.print "\t*Current" if root['snapshot'] == current
        $miqOut.print "\n"
        
        root['childSnapshotList'].each { |cs| printSnapshotTree(cs, current, opts, indent+"\t") }
    end
    
    def shExpand(targets)
        allTargets = []
        targets.each { |t| allTargets.concat(vmRoot.dirGlob(t)) }
        return allTargets
    end
    
    def initVmSearchPath
        return(nil) if !(sp = ENV['MIQVMPATH'])
        return(sp.split(':'))
    end
    
    def searchVmCfg(p)
        return(p) if !@vmSearchPath
        
        vmc = nil
        if p.index('/')
            return(p) if File.file?(p)
            return(vmc) if File.directory?(p) && (vmc = getVmCfg(p))
            raise "VM: #{p} not found."
        end
        @vmSearchPath.each do |sd|
            sp = File.join(sd, p)
            return(sp) if File.file?(sp)
            return(vmc) if File.directory?(sp) && (vmc = getVmCfg(sp))
        end
        raise "VM: #{p} not found."
    end
    
    def getVmCfg(d)
        return(nil) if !File.directory?(d)
        
        owd = Dir.getwd
        Dir.chdir(d)
        vmca = Dir.glob("*.{vmx,vmc}")
        Dir.chdir(owd)
        
        return(nil) if vmca.length == 0
        raise "Ambiguous match for VM: #{d}" if vmca.length > 1
        
        File.join(d, vmca[0])
        return(File.join(d, vmca[0]))
    end
    
end # class MiqVmExplorerOps