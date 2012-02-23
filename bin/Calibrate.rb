#!env ruby
#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'MusicMaster/Launcher'

module MusicMaster

  class Calibrate < Launcher

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
    # Parameters::
    # * *iConf* (<em>map<Symbol,Object></em>): The configuration
    # Return::
    # * _Symbol_: Rake target to execute
    def getRakeTarget(iConf)
      initialize_RakeProcesses
      generateRakeFor_CalibrateRecordings(iConf)

      return :CalibrateRecordings
    end

  end

end

exit MusicMaster::Calibrate.new.execute(ARGV)
