require 'fileutils'
require 'MusicMaster/Common'
require 'rUtilAnts/Logging'
RUtilAnts::Logging::initializeLogging('', '')
require 'MusicMaster/ConfLoader'

module MusicMaster

  # Execute the mastering
  #
  # Parameters:
  # * *iConf* (<em>map<Symbol,Object></em>): Configuration of the master
  # * *iWaveFile* (_String_): Wave file to master
  # Return:
  # * _String_: Name of the Wave file containing the result
  def self.execute(iConf, iWaveFile)
    rWaveFileToProcess = "#{$MusicMasterConf[:Master][:Dir]}/#{File.basename(iWaveFile)}"

    # Execute each step of the mastering to the wave file
    if (iConf[:Mastering] != nil)
      self.applyProcesses(iWaveFile, iConf[:Mastering], $MusicMasterConf[:Master][:Dir])
    end
    # Copy it as the Master one
    logInfo 'Writing final Master file ...'
    FileUtils::cp(iWaveFile, rWaveFileToProcess)

    return rWaveFileToProcess
  end

end

rErrorCode = 0
lConfFile, lWaveFile = ARGV[0..1]
if ((lConfFile == nil) or
    (lWaveFile == nil))
  logErr 'Usage: Master <ConfFile> <WaveFile>'
  rErrorCode = 1
elsif (!File.exists?(lConfFile))
  logErr "File #{lConfFile} does not exist."
  rErrorCode = 2
elsif (!File.exists?(lWaveFile))
  logErr "File #{lWaveFile} does not exist."
  rErrorCode = 3
else
  MusicMaster::parsePlugins
  FileUtils::mkdir_p($MusicMasterConf[:Master][:Dir])
  lConf = nil
  File.open(lConfFile, 'r') do |iFile|
    lConf = eval(iFile.read)
  end
  lFinalWave = MusicMaster::execute(lConf, lWaveFile)
  logInfo "===== Mastering finished in #{lFinalWave}"
end

exit rErrorCode
