#!env ruby
#--
# Copyright (c) 2009-2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'MusicMaster/Common'
require 'rUtilAnts/Logging'
RUtilAnts::Logging::initializeLogging('', '')
require 'MusicMaster/ConfLoader'

module MusicMaster

  # Execute the delivery of the album
  #
  # Parameters:
  # * *iConf* (<em>map<Symbol,Object></em>): Configuration of the album
  def self.execute(iConf)
    lDeliveries = iConf[:Deliveries]
    if (lDeliveries == nil)
      logWarn 'Configuration does not specify any delivery. Nothing to deliver.'
    else
      lTracksDir = iConf[:TracksDir]
      if (!File.exists?(lTracksDir))
        logErr "Missing directory #{lTracksDir}"
        raise RuntimeError.new("Missing directory #{lTracksDir}")
      else
        iConf[:Tracks].each_with_index do |iTrackInfo, iIdxTrack|
          lBaseFileName = "#{iIdxTrack}_#{iTrackInfo[:TrackID]}"
          lSourceFile = "#{$MusicMasterConf[:Album][:Dir]}/#{lBaseFileName}.wav"
          if (!File.exists?(lSourceFile))
            logErr "Missing file #{lSourceFile}"
          else
            lDeliveries.each do |iDeliveryName, iDeliveryConf|
              lExt = 'wav'
              if ((iDeliveryConf[:FileFormat] != nil) and
                  (iDeliveryConf[:FileFormat] == :MP3))
                lExt = 'mp3'
              end
              MusicMaster::src(lSourceFile, "#{$MusicMasterConf[:AlbumDeliver][:Dir]}/#{iDeliveryName}/#{lBaseFileName}.#{lExt}", iDeliveryConf)
            end
          end
        end
      end
    end
  end

end

rErrorCode = 0
lConfFile = ARGV[0]
if (lConfFile == nil)
  logErr 'Usage: DeliverAlbum <ConfFile>'
  rErrorCode = 1
elsif (!File.exists?(lConfFile))
  logErr "File #{lConfFile} does not exist."
  rErrorCode = 2
else
  FileUtils::mkdir_p($MusicMasterConf[:AlbumDeliver][:Dir])
  lConf = nil
  File.open(lConfFile, 'r') do |iFile|
    lConf = eval(iFile.read)
  end
  MusicMaster::execute(lConf)
  logInfo "===== Album delivered in #{$MusicMasterConf[:AlbumDeliver][:Dir]}"
end

exit rErrorCode
