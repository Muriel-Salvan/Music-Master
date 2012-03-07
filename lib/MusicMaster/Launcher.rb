#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'fileutils'
require 'optparse'
require 'rUtilAnts/Logging'
RUtilAnts::Logging::install_logger_on_object(:no_dialogs => true)
require 'MusicMaster/Utils'
require 'MusicMaster/FilesNamer'
require 'MusicMaster/RakeProcesses'

module MusicMaster

  class Launcher

    include MusicMaster::Utils

    # Constructor
    def initialize
      parsePlugins
      @DisplayHelp = false
      @Debug = false

      require 'optparse'
      @Options = OptionParser.new
      @Options.banner = "#{$0} [--help] [--debug] #{getOptionsBanner} <ConfigFile>"
      @Options.on( '--help',
        'Display help') do
        @DisplayHelp = true
      end
      @Options.on( '--debug',
        'Activate debug logs') do
        @Debug = true
      end
      completeOptionParser(@Options)
    end

    # Execute the process
    #
    # Parameters::
    # * *iArgs* (<em>list<String></em>): The list of arguments
    # Return::
    # * _Integer_: The error code
    def execute(iArgs)
      rErrorCode = 0

      lError = nil
      lConfFileName = nil
      begin
        lRemainingArgs = @Options.parse(iArgs)
        if (lRemainingArgs.size != 1)
          lError = RuntimeError.new("Please specify 1 config file (specified: \"#{lRemainingArgs.join(' ')}\"")
        end
        lConfFileName = lRemainingArgs.first
      rescue Exception
        lError = $!
      end
      if (lError == nil)
        if (@DisplayHelp)
          puts @Options
        else
          if (@Debug)
            activate_log_debug(true)
          end
          # Read the MusicMaster configuration
          begin
            @MusicMasterConf = get_musicmaster_conf
          rescue Exception
            lError = $!
          end
          if (lError == nil)
            # Read configuration
            lError, lRecordConf = readConf(lConfFileName)
            if (lError == nil)
              # Check the conf. This is dependent on the process
              lError = checkConf(lRecordConf)
              if (lError == nil)
                @RecordConf = lRecordConf
                initialize_Utils
                begin
                  lRakeTarget = getRakeTarget
                rescue
                  lError = $!
                end
                if (lError == nil)
                  if debug_activated?
                    Rake::application.options.trace = true
                    displayRakeTasks
                  end
                  begin
                    Rake::Task[lRakeTarget].invoke
                  rescue
                    lError = $!
                  end
                  log_info 'Processed finished successfully.' if (lError == nil)
                end
              end
            end
          end
        end
      end
      if (lError != nil)
        log_err "#{lError}#{(debug_activated? and lError.backtrace) ? "\n#{lError.backtrace.join("\n")}" : ''}"
        rErrorCode = 1
      end

      return rErrorCode
    end

    protected

    # Give additional command line options banner
    #
    # Return::
    # * _String_: Options banner
    def getOptionsBanner
      return ''
    end

    # Complete options with the specific ones of this binary
    #
    # Parameters::
    # * *ioOptionParser* (_OptionParser_): The options parser to complete
    def completeOptionParser(ioOptionParser)
    end

    # Check configuration.
    #
    # Parameters::
    # * *iConf* (<em>map<Symbol,Object></em>): The configuration
    # Return::
    # * _Exception_: Error, or nil in case of success
    def checkConf(iConf)
      return nil
    end

    # Initialize Rake processes and return the task to be built
    #
    # Return::
    # * _Symbol_: Rake target to execute
    def getRakeTarget
      return nil
    end

    private

    include FilesNamer
    include RakeProcesses
    include Utils

    # Get the global MusicMaster configuration
    # Read it from:
    # 1. The environment variable MUSICMASTER_CONF_PATH
    # 2. The installed MusicMaster directory
    # 3. The current directory
    #
    # Return::
    # * <em>map<Symbol,Object></em>: The MusicMaster configuration
    def get_musicmaster_conf
      rMusicMasterConf = nil

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
        raise "No MusicMaster configuration file could be found. You can set it by setting MUSICMASTER_CONF_PATH environment variable, or create a musicmaster.conf.rb file either in #{File.dirname(__FILE__)} or the current directory."
      else
        if (File.exists?(lConfigFileName))
          File.open(lConfigFileName, 'r') do |iFile|
            begin
              rMusicMasterConf = eval(iFile.read)
            rescue Exception
              raise "Invalid configuration file #{lConfigFileName} specified in #{lConfSource}: #{$!}"
              rMusicMasterConf = nil
            end
          end
        else
          raise "Missing file #{lConfigFileName}, specified in #{lConfSource}"
        end
      end

      return rMusicMasterConf
    end

    # Parse plugins
    def parsePlugins
      require 'rUtilAnts/Plugins'
      RUtilAnts::Plugins::install_plugins_on_object
      lLibDir = File.expand_path(File.dirname(__FILE__))
      parse_plugins_from_dir('Processes', "#{lLibDir}/Processes", 'MusicMaster::Processes')
      parse_plugins_from_dir('Formats', "#{lLibDir}/Formats", 'MusicMaster::Formats')
    end

    # Read configuration.
    # Perform basic checks on it, independent of the process reading it.
    #
    # Parameters::
    # * *iConfFile* (_String_): Configuration file
    # Return::
    # * _Exception_: Error, or nil in case of success
    # * <em>map<Symbol,Object></em>: The configuration
    def readConf(iConfFile)
      rError = nil
      rConf = nil

      if (!File.exists?(iConfFile))
        rError = RuntimeError.new("Missing configuration file: #{iConfFile}")
      else
        File.open(iConfFile, 'r') do |iFile|
          rConf = eval(iFile.read)
        end
      end

      return rError, rConf
    end

  end

end
