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

  # Execute the mastering
  #
  # Parameters::
  # * *iConf* (<em>map<Symbol,Object></em>): Configuration of the master
  # * *iWaveFile* (_String_): Wave file to master
  # Return::
  # * _String_: Name of the Wave file containing the result
  def self.execute(iConf, iWaveFile)
    rWaveFileToProcess = "#{$MusicMasterConf[:Master][:Dir]}/#{File.basename(iWaveFile)}"
    
    log_info 'Copying Master file ...'
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
  log_err 'Usage: Master <FctFile> <InputWaveFile> <OutputWaveFile> [--unitdb]'
  rErrorCode = 1
elsif (!File.exists?(lFctFile))
  log_err "File #{lFctFile} does not exist."
  rErrorCode = 2
elsif (!File.exists?(lInputWaveFile))
  log_err "File #{lInputWaveFile} does not exist."
  rErrorCode = 3
else
  lStrUnitDB = '0'
  if (lUnitDB == '--unitdb')
    lStrUnitDB = '1'
  end
  wsk(lInputWaveFile, lOutputWaveFile, 'DrawFct', "--function \"#{lFctFile}\" --unitdb #{lStrUnitDB}")
end

exit rErrorCode
