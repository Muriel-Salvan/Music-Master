#!env ruby
#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'fileutils'
require 'MusicMaster/Common'
require 'rUtilAnts/Logging'
RUtilAnts::Logging::install_logger_on_object
require 'MusicMaster/ConfLoader'

module MusicMaster

  # Execute the album
  #
  # Parameters::
  # * *iConf* (<em>map<Symbol,Object></em>): Configuration of the album
  def self.execute(iConf)
    lTracksDir = iConf[:TracksDir]
    if (!File.exists?(lTracksDir))
      log_err "Missing directory #{lTracksDir}"
      raise RuntimeError.new("Missing directory #{lTracksDir}")
    else
      iConf[:Tracks].each_with_index do |iTrackInfo, iIdxTrack|
        log_info "===== Mastering Track #{iIdxTrack}: #{iTrackInfo[:TrackID]} version #{iTrackInfo[:Version]} ====="
        lAlbumFile = "#{@MusicMasterConf[:Album][:Dir]}/#{iIdxTrack}_#{iTrackInfo[:TrackID]}.wav"
        lCancel = false
        if (File.exists?(lAlbumFile))
          puts "File #{lAlbumFile} already exists. Overwrite it by mastering a new one ? [y='yes']"
          lCancel = ($stdin.gets.chomp != 'y')
        end
        if (!lCancel)
          # Find the last Master file for this Track
          lMasterFiles = Dir.glob("#{lTracksDir}/#{iTrackInfo[:TrackID]}*/#{iTrackInfo[:Version]}/#{iConf[:TracksFilesSubDir]}#{@MusicMasterConf[:Master][:Dir]}/*.wav")
          if (lMasterFiles.empty?)
            log_err "No Master files found for Track #{iTrackInfo[:TrackID]} version #{iTrackInfo[:Version]}"
          else
            # Find the last one
            lFinalMasterFileName = lMasterFiles.sort[-1]
            log_info "Found final Master file from Track #{iTrackInfo[:TrackID]} version #{iTrackInfo[:Version]} in #{lFinalMasterFileName}"
            # Copy it
            log_info "Copying Master file to #{lAlbumFile} ..."
            FileUtils::cp(lFinalMasterFileName, lAlbumFile)
            if (iTrackInfo[:AdditionalMastering] != nil)
              lMasterTempDir = "#{@MusicMasterConf[:Album][:TempDir]}/#{iTrackInfo[:TrackID]}.#{iTrackInfo[:Version]}"
              FileUtils::mkdir_p(lMasterTempDir)
              MusicMaster::applyProcesses(iTrackInfo[:AdditionalMastering], lAlbumFile, lMasterTempDir)
            end
            # Done.
            log_info "Setting file #{iIdxTrack} for Track #{iTrackInfo[:TrackID]} from #{lAlbumFile}"          
          end
        end
        log_info ''
      end
    end
  end

end

rErrorCode = 0
lConfFile = ARGV[0]
if (lConfFile == nil)
  log_err 'Usage: Album <ConfFile>'
  rErrorCode = 1
elsif (!File.exists?(lConfFile))
  log_err "File #{lConfFile} does not exist."
  rErrorCode = 2
else
  MusicMaster::parsePlugins
  FileUtils::mkdir_p(@MusicMasterConf[:Album][:Dir])
  FileUtils::mkdir_p(@MusicMasterConf[:Album][:TempDir])
  lConf = nil
  File.open(lConfFile, 'r') do |iFile|
    lConf = eval(iFile.read)
  end
  MusicMaster::execute(lConf)
  log_info "===== Album finished in #{@MusicMasterConf[:Album][:Dir]}"
end

exit rErrorCode
