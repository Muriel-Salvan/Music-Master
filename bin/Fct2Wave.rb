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
    
    logInfo 'Copying Master file ...'
    FileUtils::cp(iWaveFile, rWaveFileToProcess)
    # Execute each step of the mastering to the wave file
    if (iConf[:Mastering] != nil)
      self.applyProcesses(iConf[:Mastering], rWaveFileToProcess, $MusicMasterConf[:Master][:Dir])
    end

    return rWaveFileToProcess
  end

end

rErrorCode = 0
lFctFile, lInputWaveFile, lOutputWaveFile, lUnitDB = ARGV[0..4]
if ((lFctFile == nil) or
    (lInputWaveFile == nil) or
    (lOutputWaveFile == nil))
  logErr 'Usage: Master <FctFile> <InputWaveFile> <OutputWaveFile> [--unitdb]'
  rErrorCode = 1
elsif (!File.exists?(lFctFile))
  logErr "File #{lFctFile} does not exist."
  rErrorCode = 2
elsif (!File.exists?(lInputWaveFile))
  logErr "File #{lInputWaveFile} does not exist."
  rErrorCode = 3
else
  lStrUnitDB = '0'
  if (lUnitDB == '--unitdb')
    lStrUnitDB = '1'
  end
  MusicMaster::wsk(lInputWaveFile, lOutputWaveFile, 'DrawFct', "--function \"#{lFctFile}\" --unitdb #{lStrUnitDB}")
end

exit rErrorCode
