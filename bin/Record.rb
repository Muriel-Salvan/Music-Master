#!env ruby

require 'MusicMaster/Launcher'

module MusicMaster

  class Record < Launcher

    protected

    # Give additional command line options banner
    #
    # Return::
    # * _String_: Options banner
    def getOptionsBanner
      return '[--recordedfilesprepared] [--env <RecordingEnv>]*'
    end

    # Complete options with the specific ones of this binary
    #
    # Parameters::
    # * *ioOptionParser* (_OptionParser_): The options parser to complete
    def completeOptionParser(ioOptionParser)
      @RecordedFilesPrepared = false
      ioOptionParser.on( '--recordedfilesprepared',
        'Recorded files are already prepared: no need to wait for user input while recording.') do
        @RecordedFilesPrepared = true
      end
      @LstEnvToRecord = []
      ioOptionParser.on( '--env <RecordingEnv>', String,
        'Specify the recording environment to record. Can be used several times. If none specified, all environments will be recorded.') do |iArg|
        @LstEnvToRecord << iArg.to_sym
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

      # Check that all tracks are assigned somewhere, just once
      if ((iConf[:Recordings] != nil) and
          (iConf[:Recordings][:Tracks] != nil))
        lLstTracks = []
        iConf[:Recordings][:Tracks].keys.each do |iLstTracks|
          lLstTracks.concat(iLstTracks)
        end
        lAssignedTracks = {}
        lLstTracks.each do |iIdxTrack|
          if (lAssignedTracks.has_key?(iIdxTrack))
            rError = RuntimeError.new("Track #{iIdxTrack} is recorded twice.")
            break
          else
            lAssignedTracks[iIdxTrack] = nil
          end
        end
        if (rError == nil)
          lAssignedTracks.size.times do |iIdxTrack|
            if (!lAssignedTracks.has_key?(iIdxTrack+1))
              log_warn "Track #{iIdxTrack+1} is never recorded."
            end
          end
        end
      end

      return rError
    end

    # Initialize Rake processes and return the task to be built
    #
    # Return::
    # * _Symbol_: Rake target to execute
    def getRakeTarget
      initialize_RakeProcesses(:RecordedFilesPrepared => @RecordedFilesPrepared, :LstEnvToRecord => @LstEnvToRecord)
      generateRakeFor_GenerateSourceFiles

      return :GenerateSourceFiles
    end

  end

end

exit MusicMaster::Record.new.execute(ARGV)
