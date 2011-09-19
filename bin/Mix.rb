#!env ruby
#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'MusicMaster/Common'
require 'rUtilAnts/Logging'
RUtilAnts::Logging::initializeLogging('', '')
require 'MusicMaster/ConfLoader'
require 'digest/md5'

module MusicMaster

  # Execute the Mix
  #
  # Parameters:
  # * *iConfig* (<em>map<Symbol,Object></em>): The Mix configuration
  # Return:
  # * _String_: The resulting mix file
  def self.execute(iConfig)
    rPerformMixFile = nil

    lMixInputFile = nil
    lLstMixFiles = []
    lMissingFiles = []
    iConfig[:MixFiles].each do |iMixFileInfo|
      if (!File.exists?(iMixFileInfo[:FileName]))
        logErr "File #{iMixFileInfo[:FileName]} does not exist."
        lMissingFiles << iMixFileInfo[:FileName]
      else
        lResultFileName = executeOperations(iMixFileInfo[:FileName], iMixFileInfo[:Operations])
        if (lMixInputFile == nil)
          lMixInputFile = lResultFileName
        else
          lLstMixFiles << lResultFileName
        end
      end
    end
    if (!lMissingFiles.empty?)
      logErr "Mix will not be performed as some files were missing: #{lMissingFiles.join(', ')}"
    else
      if (lLstMixFiles.empty?)
        logInfo "Single perform file to mix: #{lMixInputFile}"
        rPerformMixFile = lMixInputFile
      else
        rPerformMixFile = "#{$MusicMasterConf[:Mix][:TempDir]}/Perform.Mix.wav"
        wsk(lMixInputFile, rPerformMixFile, 'Mix', "--files \"#{lLstMixFiles.join('|1|')}|1\" ")
      end
      logInfo "Perform mix result in #{rPerformMixFile}"
    end

    return rPerformMixFile
  end

  # Execute operations on a Wave file, then give back the resulting file
  #
  # Parameters:
  # * *iInputFile* (_String_): The input wave file
  # * *iOperations* (<em>list<[String,String]></em>): The list of operations to execute: [Action,Parameters].
  # Return:
  # * _String_: The resulting file name
  def self.executeOperations(iInputFile, iOperations)
    rResultFileName = iInputFile

    lBaseName = "#{$MusicMasterConf[:Mix][:TempDir]}/#{File.basename(iInputFile)[0..-5]}"
    iOperations.each_with_index do |iOperationInfo, iIdxOperation|
      iAction, iParameters = iOperationInfo
      lInputFileName = rResultFileName.clone
      # Compute a unique ID for this operation.
      lOperationID = Digest::MD5.hexdigest("#{iAction}|#{iParameters}")
      rResultFileName = "#{lBaseName}.#{iIdxOperation}.#{iAction}.#{lOperationID}.wav"
      # Call wsk if the file does not exist already
      if (!File.exists?(rResultFileName))
        wsk(lInputFileName, rResultFileName, iAction, iParameters)
      end
    end

    return rResultFileName
  end

end

rErrorCode = 0
lConfigFile = ARGV[0]
if (lConfigFile == nil)
  logErr 'Please specify the configuration file.'
  rErrorCode = 1
elsif (!File.exists?(lConfigFile))
  logErr "File #{lConfigFile} does not exist."
  rErrorCode = 2
else
  FileUtils::mkdir_p($MusicMasterConf[:Mix][:TempDir])
  lConfig = nil
  File.open(lConfigFile, 'r') do |iFile|
    lConfig = eval(iFile.read)
  end
  lMixFile = MusicMaster::execute(lConfig)
  logInfo "===== Mix saved in #{lMixFile}"
end

exit rErrorCode
