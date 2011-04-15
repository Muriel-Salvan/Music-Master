#!env ruby
#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'fileutils'
require 'MusicMaster/Common'
require 'rUtilAnts/Logging'
RUtilAnts::Logging::initializeLogging('', '')
require 'MusicMaster/ConfLoader'

module MusicMaster

  # Execute the album
  #
  # Parameters:
  # * *iConf* (<em>map<Symbol,Object></em>): Configuration of the album
  def self.execute(iConf)
    lTracksDir = iConf[:TracksDir]
    if (!File.exists?(lTracksDir))
      logErr "Missing directory #{lTracksDir}"
      raise RuntimeError.new("Missing directory #{lTracksDir}")
    else
      # Analyze results, per Track
      lAnalyzeResults = []
      iConf[:Tracks].each_with_index do |iTrackInfo, iIdxTrack|
        lTrackFileName = "#{$MusicMasterConf[:Album][:Dir]}/#{iIdxTrack}_#{iTrackInfo[:TrackID]}.wav"
        MusicMaster::wsk(lTrackFileName, 'Dummy.wav', 'Analyze')
        File.unlink('Dummy.wav')
        File.open('analyze.result', 'rb') do |iFile|
          lAnalyzeResults << Marshal.load(iFile.read)
        end
        File.unlink('analyze.result')
      end
      # Display analyze results
      logInfo ''
      logInfo '===== Analyze results:'
      iConf[:Tracks].each_with_index do |iTrackInfo, iIdxTrack|
        lStrDBRMSValues = lAnalyzeResults[iIdxTrack][:DBRMSValues].map do |iValue|
          next sprintf('%.2f', iValue)
        end
        logInfo "[#{iIdxTrack} - #{iTrackInfo[:TrackID]}]: RMS=(#{lStrDBRMSValues.join('db, ')}db) Max=#{sprintf('%.2f', lAnalyzeResults[iIdxTrack][:DBAbsMaxValue])}db Length=#{sprintf('%.2f', lAnalyzeResults[iIdxTrack][:DataLength])}s"
      end
    end
  end

end

rErrorCode = 0
lConfFile = ARGV[0]
if (lConfFile == nil)
  logErr 'Usage: AnalyzeAlbum <ConfFile>'
  rErrorCode = 1
elsif (!File.exists?(lConfFile))
  logErr "File #{lConfFile} does not exist."
  rErrorCode = 2
else
  lConf = nil
  File.open(lConfFile, 'r') do |iFile|
    lConf = eval(iFile.read)
  end
  MusicMaster::execute(lConf)
end

exit rErrorCode
