#
# Copyright 2008 ManageIQ, Inc.  All rights reserved.
#

$:.push("#{File.dirname(__FILE__)}/../../lib/VMwareWebService")

require 'MiqVim'

class EmsConnections
    
    attr_reader :currentConnection
    
    def initialize
        @connections = Hash.new
        @currentConnection = nil
    end
    
    def addConnection(cParms)
        cId = cParms[:name] || cParms[:server]
        cParms[:cId] = cId
        raise "Connection #{cId} already exists" if @connections[cId]
        @connections[cId] = EmsConnection.new(cParms)
    end # def addConnection
    
    def deleteConnection(cId)
        raise "Connection #{cId} doesn't exist"     if !@connections[cId]
        raise "Connection #{cId} is currently open" if @connections[cId] == @currentConnection
        @connections.delete(cId)
    end
    
    def connections
        return @connections.values
    end
    
    def close
        return if !@currentConnection
        @currentConnection.close
        @currentConnection = nil
    end
    
    def currentConnection=(cId)
        raise "Connection #{cId} not found" if !(cc = @connections[cId])
        cc.open
        @currentConnection.close if @currentConnection
        @currentConnection = cc
    end
    
    def setCc(cc)
        @currentConnection = cc
    end
    
    def isCurrent?(c)
        return c == @currentConnection
    end

end # class EmsConnections

class EmsConnection
    
    attr_accessor :vmsByName, :connection
    
    def initialize(cParms)
        @connection = nil
        @vmsByName = Hash.new
        @cParms = cParms.dup
    end
    
    def [](key)
        return @cParms[key]
    end
    
    def open
        return if @connection
        raise "Unknown connection type: #{self[:type]}" if self[:type] != "VIM"
        
        @connection = MiqVim.new(self[:server], self[:username], self[:password])
        
        @connection.virtualMachinesByMor.each_value do |vmObj|
            vm = Hash.new
            vm[:name] = vmObj['summary']['config']['name']
            vm[:host] = vmObj['summary']["runtime"]["hostName"]
            vm[:path] = vmObj['summary']['config']['vmLocalPathName']
            
            @vmsByName[vm[:name]] = vm
        end
    end
    
    def vmsByName
        raise "Connection is not open" if !@connection
        return @vmsByName
    end
    
    def close
        raise "Connection #{self[:cId]} is not open" if !@connection
        @connection.disconnect
        @connection = nil
        @vmsByName = nil
    end
    
    def connection
        return @connection
    end
    
end # class EmsConnection
