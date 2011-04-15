#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# This file is required by MusicMaster binaries to load the MusicMaster configuration.
# This sets the $MusicMasterConf object that can then be accessed from anywhere.

module MusicMaster

  def self.loadConf
    $MusicMasterConf = nil
    lConfSource = nil
    # 1. Find from the environment
    lConfigFileName = ENV['MUSICMASTER_CONF_PATH']
    if (lConfigFileName == nil)
      # 2. Find from the MusicMaster directory
      lConfigFileName = "#{File.dirname(__FILE__)}/musicmaster.conf.rb"
      if (File.exists?(lConfigFileName))
        lConfSource = 'MusicMaster package local libraries'
      else
        # 3. Find from the current directory
        lConfigFileName = "musicmaster.conf.rb"
        if (File.exists?(lConfigFileName))
          lConfSource = 'current directory'
        else
          # 4. Failure
        end
      end
    else
      lConfSource = 'MUSICMASTER_CONF_PATH environment variable'
    end

    # Check the configuration
    if (lConfSource == nil)
      logErr "No MusicMaster configuration file could be found. You can set it by setting MUSICMASTER_CONF_PATH environment variable, or create a musicmaster.conf.rb file either in #{File.dirname(__FILE__)} or the current directory."
    else
      if (File.exists?(lConfigFileName))
        File.open(lConfigFileName, 'r') do |iFile|
          begin
            $MusicMasterConf = eval(iFile.read)
          rescue Exception
            logErr "Invalid configuration file #{lConfigFileName} specified in #{lConfSource}: #{$!}"
            $MusicMasterConf = nil
          end
        end
      else
        logErr "Missing file #{lConfigFileName}, specified in #{lConfSource}"
      end
    end

  end

end

MusicMaster::loadConf
