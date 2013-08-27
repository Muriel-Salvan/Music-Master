#!env ruby

require 'MusicMaster/Launcher'

module MusicMaster

  class Clean < Launcher

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
      initialize_RakeProcesses
      generateRakeFor_CleanRecordings

      return :CleanRecordings
    end

  end

end

exit MusicMaster::Clean.new.execute(ARGV)
