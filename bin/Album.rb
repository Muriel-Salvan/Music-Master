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
      iConf[:Tracks].each_with_index do |iTrackInfo, iIdxTrack|
        # Find the last Master file for this Track
        lMasterFiles = Dir.glob("#{lTracksDir}/#{iTrackInfo[:TrackID]}*/#{iTrackInfo[:Version]}/#{iConf[:TracksFilesSubDir]}#{$MusicMasterConf[:Master][:Dir]}/*.wav")
        if (lMasterFiles.empty?)
          logErr "No Master files found for Track #{iTrackInfo[:TrackID]} version #{iTrackInfo[:Version]}"
        else
          # Find the last one
          lFinalMasterFileName = lMasterFiles.sort[-1]
          logInfo "Found final Master file from Track #{iTrackInfo[:TrackID]} version #{iTrackInfo[:Version]} in #{lFinalMasterFileName}"
          lResultingFile = nil
          if (iTrackInfo[:AdditionalMastering] != nil)
            lMasterTempDir = "#{$MusicMasterConf[:Album][:TempDir]}/#{iTrackInfo[:TrackID]}.#{iTrackInfo[:Version]}"
            FileUtils::mkdir_p(lMasterTempDir)
            lResultingFile = MusicMaster::applyMasteringProcesses(lFinalMasterFileName, iTrackInfo[:AdditionalMastering], lMasterTempDir)
          else
            lResultingFile = lFinalMasterFileName
          end
          # Copy it
          logInfo "Setting file #{iIdxTrack} for Track #{iTrackInfo[:TrackID]}"
          FileUtils::cp(lResultingFile, "#{$MusicMasterConf[:Album][:Dir]}/#{iIdxTrack}_#{iTrackInfo[:TrackID]}.wav")
        end
      end
    end
  end

end

rErrorCode = 0
lConfFile = ARGV[0]
if (lConfFile == nil)
  logErr 'Usage: Album <ConfFile>'
  rErrorCode = 1
elsif (!File.exists?(lConfFile))
  logErr "File #{lConfFile} does not exist."
  rErrorCode = 2
else
  FileUtils::mkdir_p($MusicMasterConf[:Album][:Dir])
  FileUtils::mkdir_p($MusicMasterConf[:Album][:TempDir])
  lConf = nil
  File.open(lConfFile, 'r') do |iFile|
    lConf = eval(iFile.read)
  end
  MusicMaster::execute(lConf)
  logInfo "===== Album finished in #{$MusicMasterConf[:Album][:Dir]}"
end

exit rErrorCode
