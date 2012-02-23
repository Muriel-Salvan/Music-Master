#!env ruby
#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'MusicMaster/Launcher'

module MusicMaster

  class Deliver < Launcher

    protected

    # Give additional command line options banner
    #
    # Return::
    # * _String_: Options banner
    def getOptionsBanner
      return '[--name <DeliverableName>]*'
    end

    # Complete options with the specific ones of this binary
    #
    # Parameters::
    # * *ioOptionParser* (_OptionParser_): The options parser to complete
    def completeOptionParser(ioOptionParser)
      @LstDeliverableNames = []
      ioOptionParser.on( '--name <DeliverableName>', String,
        'Specify the name of the deliverable to produce. Can be used several times. If not specified, all deliverables will be produced.') do |iArg|
        @LstDeliverableNames << iArg
      end
    end

    # Check configuration.
    #
    # Parameters::
    # * *iConf* (<em>map<Symbol,Object></em>): The configuration
    # Return::
    # * _Exception_: Error, or nil in case of success
    def checkConf(iConf)
      rError = nil

      # Check that all formats referenced correspond to a given format
      if ((iConf[:Deliver] != nil) and
          (iConf[:Deliver][:Deliverables] != nil))
        iConf[:Deliver][:Deliverables].each do |iDeliverableName, iDeliverableConf|
          if (iDeliverableConf[:Format] != nil)
            raise "Unknown format #{iDeliverableConf[:Format]} needed to deliver #{iDeliverableName}" if (iConf[:Deliver][:Formats][iDeliverableConf[:Format]] == nil)
          end
          raise "No mix specified for deliverable #{iDeliverableName}" if (iDeliverableConf[:Mix] == nil)
        end
      end

      return rError
    end

    # Initialize Rake processes and return the task to be built
    #
    # Parameters::
    # * *iConf* (<em>map<Symbol,Object></em>): The configuration
    # Return::
    # * _Symbol_: Rake target to execute
    def getRakeTarget(iConf)
      initialize_RakeProcesses(:LstDeliverableNames => @LstDeliverableNames)
      generateRakeFor_Deliver(iConf)

      return :Deliver
    end

  end

end

exit MusicMaster::Deliver.new.execute(ARGV)
