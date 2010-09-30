require 'fileutils'
require 'optparse'
require 'rUtilAnts/Plugins'
RUtilAnts::Plugins::initializePlugins
require 'rUtilAnts/Logging'
RUtilAnts::Logging::initializeLogging('', '')
require 'MusicMaster/Common'
require 'MusicMaster/ConfLoader'

module MusicMaster

  class Record

    # Constructor
    def initialize
      # List of perform partitions
      # list< list< Integer > >
      @LstPerforms = []
      # List of patch tracks
      # list< Integer >
      @LstPatches = []
      @WaveFiles = false
      MusicMaster::parsePlugins
    end

    # Execute the recordings
    #
    # Parameters:
    # * *iArgs* (<em>list<String></em>): The list of arguments
    # Return:
    # * _Integer_: The error code
    def execute(iArgs)
      rErrorCode = 0

      lError = nil
      # Read the arguments
      if (iArgs.size != 1)
        lError = RuntimeError.new('Usage: Record <ConfFile>')
      else
        # Read configuration
        lError, lConf = MusicMaster::readRecordConf(iArgs[0])
        if (lError == nil)
          if (lConf[:Performs] != nil)
            if (!lConf[:Performs].empty?)
              # Record performances
              lConf[:Performs].each do |iLstPerform|
                puts "===== Record Perform partition #{iLstPerform.join(', ')} ====="
                record("Perform.#{iLstPerform.join(' ')}.wav")
              end
              puts '===== Record Perform silence ====='
              record('Perform.Silence.wav')
            end
          end
          if (lConf[:Patches] != nil)
            lConf[:Patches].each do |iIdxTrack, iTrackConf|
              # If the track has already a volume correction to be applied, ignore this step
              if (iTrackConf[:VolCorrection] == nil)
                puts "===== Record Perform volume preview for track #{iIdxTrack} ====="
                record("Patch.#{iIdxTrack}.VolReference.wav")
                puts "===== Measure the volume cuts from file Patch.#{iIdxTrack}.VolReference.wav and set them in the record conf file ====="
                puts 'Enter when done.'
                $stdin.gets
              end
            end
            # Now we don't need anymore the volume setting for Perform.
            lConf[:Patches].each do |iIdxTrack, iTrackConf|
              lTryAgain = true
              while (lTryAgain)
                puts "===== Record the Patch track #{iIdxTrack} ====="
                record("Patch.#{iIdxTrack}.wav")
                puts 'Is the file correct ? (No peak limit reached ?) \'y\'=yes.'
                lTryAgain = ($stdin.gets.chomp != 'y')
              end
              if (iTrackConf[:Effects] != nil)
                applyEffects(iTrackConf[:Effects], "Patch.#{iIdxTrack}.wav")
              end
              puts "===== Record Patch silence for track #{iIdxTrack} ====="
              record("Patch.#{iIdxTrack}.Silence.wav")
              if (iTrackConf[:Effects] != nil)
                applyEffects(iTrackConf[:Effects], "Patch.#{iIdxTrack}.Silence.wav")
              end
              if (iTrackConf[:VolCorrection] == nil)
                puts "===== Record Patch volume preview for track #{iIdxTrack} ====="
                record("Patch.#{iIdxTrack}.VolOriginal.wav")
                if (iTrackConf[:Effects] != nil)
                  applyEffects(iTrackConf[:Effects], "Patch.#{iIdxTrack}.VolOriginal.wav")
                end
              end
            end
          end
          if (lConf[:WaveFiles])
            puts '===== Generate Wave in Wave.*.wav files ====='
            puts 'Press Enter to continue once done.'
            $stdin.gets
          end
          logInfo 'Finished recording ok. Ready to use PrepareMix.rb and Mix.rb.'
        end
      end
      if (lError != nil)
        puts "!!! Error: #{lError}"
        rErrorCode = 1
      end

      return rErrorCode
    end

    # Apply given record effects on a wav file
    #
    # Parameters:
    # * *iEffects* (<em>list<map<Symbol,Object>></em>): List of effects to apply
    # * *iFileName* (_String_): File name to apply effects to
    def applyEffects(iEffects, iFileName)
      lFileNameNoExt = iFileName[0..-5]
      iEffects.each_with_index do |iEffectInfo, iIdxEffect|
        accessPlugin('RecordEffects', iEffectInfo[:Name]) do |ioActionPlugin|
          # Save the file before using the plugin
          lSave = true
          lSaveFileName = "#{lFileNameNoExt}.Before_#{iIdxEffect}_#{iEffectInfo[:Name]}.wav"
          if (File.exists?(lSaveFileName))
            puts "!!! File #{lSaveFileName} already exists. Overwrite and apply effect ? [y='yes']"
            lSave = ($stdin.gets.chomp == 'y')
          end
          if (lSave)
            logInfo "Saving file #{iFileName} to #{lSaveFileName} ..."
            FileUtils::cp(iFileName, lSaveFileName)
            logInfo "===== Apply Effect #{iEffectInfo[:Name]} to #{iFileName} ====="
            ioActionPlugin.execute(iFileName, iEffectInfo)
          end
        end
      end
    end

    # Record into a given file
    #
    # Parameters:
    # * *iFileName* (_String_): File name to record into
    def record(iFileName)
      lTryAgain = true
      if (File.exists?(iFileName))
        puts "File \"#{iFileName}\" already exists. Overwrite ? ['y' = yes]"
        lTryAgain = ($stdin.gets.chomp == 'y')
      end
      while (lTryAgain)
        puts "Record file \"#{iFileName}\""
        puts 'Press Enter to continue once done. Type \'s\' to skip it.'
        lSkip = ($stdin.gets.chomp == 's')
        if (lSkip)
          lTryAgain = false
        else
          # Get the last file that has been recorded
          lFileName = $MusicMasterConf[:Record][:RecordedFileGetter].call
          if (!File.exists?(lFileName))
            logErr "File #{lFileName} does not exist. Could not get recorded file."
          else
            logInfo "Getting recorded file: #{lFileName} => #{iFileName}"
            FileUtils::mv(lFileName, iFileName)
            lTryAgain = false
          end
        end
      end
    end

  end

end

exit MusicMaster::Record.new.execute(ARGV)
