#!env ruby
#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'MusicMaster/Common'
require 'rUtilAnts/Plugins'
RUtilAnts::Plugins::initializePlugins
require 'rUtilAnts/Logging'
RUtilAnts::Logging::initializeLogging('', '')
require 'MusicMaster/ConfLoader'

module MusicMaster

  def self.val2db(iRatio)
    if (iRatio == 0)
      return -1.0/0
    else
      return (6*Math.log(iRatio))/Math.log(2.0)
    end
  end

  # Read a ratio or db, and get back the corresponding ratio in db
  #
  # Parameters:
  # * *iStrValue* (_String_): The value to read
  # Return:
  # * _Float_: The corresponding ratio in db
  def self.readStrRatio(iStrValue)
    rRatio = nil

    lMatch = iStrValue.match(/^(.*)db$/)
    if (lMatch == nil)
      # The argument is a ratio
      rRatio = val2db(iStrValue.to_f)
    else
      # The argument is already in db
      rRatio = iStrValue.to_f
    end

    return rRatio
  end

  # Get the configuration
  #
  # Parameters:
  # * *iRecordConf* (<em>map<Symbol,Object></em>): The record configuration
  # Return:
  # * <em>map<Symbol,Object></em>: The configuration
  def self.getConfig(iRecordConf)
    rConfig = {
      :MixFiles => []
    }

    # Check all needed files are present
    lError = false
    if (iRecordConf[:Patches] != nil)
      iRecordConf[:Patches].each do |iIdxTrack, iTrackConf|
        if (!File.exists?("Patch.#{iIdxTrack}.wav"))
          logErr "Missing file Patch.#{iIdxTrack}.wav"
          lError = true
        end
        if (!File.exists?("Patch.#{iIdxTrack}.Silence.wav"))
          logErr "Missing file Patch.#{iIdxTrack}.Silence.wav"
          lError = true
        end
        if (iTrackConf[:VolCorrection] == nil)
          if (!File.exists?("Patch.#{iIdxTrack}.VolOriginal.wav"))
            logErr "Missing file Patch.#{iIdxTrack}.VolOriginal.wav"
            lError = true
          end
          if (!File.exists?("Patch.#{iIdxTrack}.VolReference.wav"))
            logErr "Missing file Patch.#{iIdxTrack}.VolReference.wav"
            lError = true
          end
        end
      end
    end
    if (iRecordConf[:Performs] != nil)
      iRecordConf[:Performs].each do |iLstPerform|
        if (!File.exists?("Perform.#{iLstPerform.join(' ')}.wav"))
          logErr "Missing file Perform.#{iLstPerform.join(' ')}.wav"
          lError = true
        end
      end
    end
    if (!File.exists?('Perform.Silence.wav'))
      logErr 'Missing file Perform.Silence.wav'
      lError = true
    end

    if (lError)
      logErr 'Some errors were found during files parsing. Aborting.'
    else
      # Generate the configuration
      lPerformSilenceThresholds = getSilenceThresholds('Perform')
      lLstStrPerformSilenceThresholds = []
      lPerformSilenceThresholds.each do |iSilenceThresholdInfo|
        lLstStrPerformSilenceThresholds << iSilenceThresholdInfo.join(',')
      end
      lPerformFFTProfile = genSilenceFFTProfile('Perform')
      # Perform files
      if (iRecordConf[:Performs] != nil)
        iRecordConf[:Performs].each do |iLstPerform|
          lFileName = "Perform.#{iLstPerform.join(' ')}.wav"
          # Check if there is a DC offset to apply first
          lAnalyze = analyzeFile(lFileName)
          lDCOffsets = []
          lOffset = false
          lAnalyze[:MoyValues].each do |iMoyValue|
            lDCOffset = iMoyValue.round
            lDCOffsets << lDCOffset
            if (lDCOffset != 0)
              lOffset = true
            end
          end
          lSilenceThresholdsWithDC = getDCThresholds(lDCOffsets, lPerformSilenceThresholds)
          # Build the list of parameters to give to wsk
          lLstStrSilenceThresholdsWithDC = []
          lSilenceThresholdsWithDC.each do |iSilenceThresholdInfo|
            lLstStrSilenceThresholdsWithDC << iSilenceThresholdInfo.join(',')
          end
          # The list of operations to perform
          # list< [ String, String ] >
          lOperations = [
            [ 'SilenceRemover', "--silencethreshold \"#{lLstStrSilenceThresholdsWithDC.join('|')}\" --attack 0 --release #{$MusicMasterConf[:NoiseGate][:SilenceMin]} --noisefft \"#{lPerformFFTProfile}\"" ]
          ]
          if (lOffset)
            logInfo "DC offset to correct: #{lDCOffsets.join(', ')}"
            lOperations << [ 'DCShifter', "--offset \"#{lDCOffsets.map { |iValue| -iValue }.join('|')}\"" ]
          else
            logInfo 'No DC offset to correct'
          end
          lOperations << [ 'NoiseGate', "--silencethreshold \"#{lLstStrPerformSilenceThresholds.join('|')}\" --attack #{$MusicMasterConf[:NoiseGate][:Attack]} --release #{$MusicMasterConf[:NoiseGate][:Release]} --silencemin #{$MusicMasterConf[:NoiseGate][:SilenceMin]} --noisefft \"#{lPerformFFTProfile}\"" ]
          # Register this file
          rConfig[:MixFiles] << {
            :FileName => lFileName,
            :Operations => lOperations
          }
        end
      end
      # Patch files
      if (iRecordConf[:Patches] != nil)
        iRecordConf[:Patches].each do |iIdxTrack, iTrackConf|
          # Measure the volume differences between Perform and Patch
          lPatchSilenceThresholds = getSilenceThresholds("Patch.#{iIdxTrack}")
          lLstStrPatchSilenceThresholds = []
          lPatchSilenceThresholds.each do |iSilenceThresholdInfo|
            lLstStrPatchSilenceThresholds << iSilenceThresholdInfo.join(',')
          end
          lPatchFFTProfile = genSilenceFFTProfile("Patch.#{iIdxTrack}")
          # Check if there is a DC offset to apply first
          lFileName = "Patch.#{iIdxTrack}.wav"
          lAnalyze = analyzeFile(lFileName)
          lDCOffsets = []
          lOffset = false
          lAnalyze[:MoyValues].each do |iMoyValue|
            lDCOffset = iMoyValue.round
            lDCOffsets << lDCOffset
            if (lDCOffset != 0)
              lOffset = true
            end
          end
          lSilenceThresholdsWithDC = getDCThresholds(lDCOffsets, lPatchSilenceThresholds)
          # Build the list of parameters to give to wsk
          lLstStrSilenceThresholdsWithDC = []
          lSilenceThresholdsWithDC.each do |iSilenceThresholdInfo|
            lLstStrSilenceThresholdsWithDC << iSilenceThresholdInfo.join(',')
          end
          lVolCorrection = nil
          if (iTrackConf[:VolCorrection] == nil)
            # We use recorded previews to indicate volume corrections
            lVolReference_Framed = genFramedWave("Patch.#{iIdxTrack}.VolReference.wav", lLstStrPerformSilenceThresholds, iTrackConf[:VolCompareCuts][0], iTrackConf[:VolCompareCuts][1], lPerformFFTProfile)
            lVolOriginal_Framed = genFramedWave("Patch.#{iIdxTrack}.VolOriginal.wav", lLstStrPatchSilenceThresholds, iTrackConf[:VolCompareCuts][0], iTrackConf[:VolCompareCuts][1], lPatchFFTProfile)
            lVolReference_Analyze = analyzeFile(lVolReference_Framed)
            lVolOriginal_Analyze = analyzeFile(lVolOriginal_Framed)
            lRMSReference = 0
            lVolReference_Analyze[:RMSValues].each do |iValue|
              lRMSReference += iValue
            end
            lRMSReference = lRMSReference / lVolReference_Analyze[:RMSValues].size
            lRMSOriginal = 0
            lVolOriginal_Analyze[:RMSValues].each do |iValue|
              lRMSOriginal += iValue
            end
            lRMSOriginal = lRMSOriginal / lVolOriginal_Analyze[:RMSValues].size
            # Show RMS difference
            logInfo "Track #{iIdxTrack} - Reference sample RMS: #{lRMSReference} (#{lVolReference_Analyze[:RMSValues].join(', ')})"
            logInfo "Track #{iIdxTrack} - Patch sample RMS: #{lRMSOriginal} (#{lVolOriginal_Analyze[:RMSValues].join(', ')})"
            # If the Patch is louder, apply a volume reduction
            if (lRMSOriginal != lRMSReference)
              if (lRMSOriginal < lRMSReference)
                # Here we are loosing quality: we need to increase the volume
                lDBValue, lPCValue = val2db(lRMSReference-lRMSOriginal, lAnalyze[:MinPossibleValue].abs)
                logWarn "Patch Track #{iIdxTrack} should be recorded louder (at least #{lDBValue} db <=> #{lPCValue} %)."
              end
              lVolCorrection = "#{lRMSReference}/#{lRMSOriginal}"
            end
          else
            lVolCorrection = iTrackConf[:VolCorrection]
          end
          # The list of operations to perform
          # list< [ String, String ] >
          lOperations = [
            [ 'SilenceRemover', "--silencethreshold \"#{lLstStrSilenceThresholdsWithDC.join('|')}\" --attack 0 --release #{$MusicMasterConf[:NoiseGate][:SilenceMin]} --noisefft \"#{lPatchFFTProfile}\"" ]
          ]
          if (lOffset)
            logInfo "DC offset to correct: #{lDCOffsets.join(', ')}"
            lOperations << [ 'DCShifter', "--offset \"#{lDCOffsets.map { |iValue| -iValue }.join('|')}\"" ]
          else
            logInfo 'No DC offset to correct'
          end
          lOperations << [ 'NoiseGate', "--silencethreshold \"#{lLstStrPatchSilenceThresholds.join('|')}\" --attack #{$MusicMasterConf[:NoiseGate][:Attack]} --release #{$MusicMasterConf[:NoiseGate][:Release]} --silencemin #{$MusicMasterConf[:NoiseGate][:SilenceMin]} --noisefft \"#{lPatchFFTProfile}\"" ]
          if (lVolCorrection != nil)
            lOperations << [ 'Multiply', "--coeff \"#{lVolCorrection}\"" ]
          end
          # Register this file
          rConfig[:MixFiles] << {
            :FileName => lFileName,
            :Operations => lOperations
          }
        end
      end
      # Now treat additional WAV files
      if (iRecordConf[:WaveFiles] != nil)
        # Check if there is a global ratio to apply
        lGlobalRatio = nil
        if (iRecordConf[:WaveFiles][:VolCorrection] != nil)
          lGlobalRatio = readStrRatio(iRecordConf[:WaveFiles][:VolCorrection])
        end
        iRecordConf[:WaveFiles][:FilesList].each do |iWaveInfo|
          lLstFileNames = Dir.glob("#{$MusicMasterConf[:Record][:WaveDir]}/#{iWaveInfo[:Name]}")
          if (lLstFileNames.empty?)
            logWarn "No Wave file found as \"#{$MusicMasterConf[:Record][:WaveDir]}/#{iWaveInfo[:Name]}\"."
          else
            lLstFileNames.each do |iWaveFileName|
              lOperations = []
              if (iWaveInfo[:VolCorrection] != nil)
                lRatio = readStrRatio(iWaveInfo[:VolCorrection])
                if (lGlobalRatio != nil)
                  lRatio += lGlobalRatio
                end
                if (lRatio != 0)
                  lOperations << [ 'Multiply', "--coeff \"#{lRatio}\"db" ]
                end
              elsif (lGlobalRatio != nil)
                lOperations << [ 'Multiply', "--coeff \"#{lGlobalRatio}\"db" ]
              end
              if (iWaveInfo[:Position] != nil)
                lOperations << [ 'SilenceInserter', "--begin \"#{iWaveInfo[:Position]}\" --end 0" ]
              end
              rConfig[:MixFiles] << {
                :FileName => iWaveFileName,
                :Operations => lOperations
              }
            end
          end
        end
      end
    end

    return rConfig
  end

  # Convert a value to its db notation and % notation
  #
  # Parameters:
  # * *iValue* (_Integer_): The value
  # * *iMaxValue* (_Integer_): The maximal possible value
  # Return:
  # * _Float_: Its corresponding db
  # * _Float_: Its corresponding percentage
  def self.val2db(iValue, iMaxValue)
    if (iValue == 0)
      return -1.0/0, 0.0
    else
      if (defined?(@Log2) == nil)
        @Log2 = Math.log(2.0)
      end
      return -6*(Math.log(Float(iMaxValue))-Math.log(Float(iValue.abs)))/@Log2, (Float(iValue.abs)*100)/Float(iMaxValue)
    end
  end

  # Get thresholds shifted by a DC offset.
  #
  # Parameters:
  # * *iDCOffsets* (<em>list<Integer></em>): The DC offsets
  # * *iThresholds* (<em>list<[Integer,Integer]></em>): The thresholds to shift
  # Return:
  # * <em>list<[Integer,Integer]></em>: The shifted thresholds
  # * _Boolean_: Has an offset really been applied ?
  def self.getDCThresholds(iDCOffsets, iThresholds)
    rCorrectedSilenceThresholds = []

    # Compute the silence thresholds with DC offset applied
    iThresholds.each do |iThresholdInfo|
      lCorrectedThresholdInfo = []
      iThresholdInfo.each_with_index do |iValue, iIdxChannel|
        lCorrectedThresholdInfo << iValue + iDCOffsets[iIdxChannel]
      end
      rCorrectedSilenceThresholds << lCorrectedThresholdInfo
    end

    return rCorrectedSilenceThresholds
  end

  # Analyze a given wav file
  #
  # Parameters:
  # * *iWaveFile* (_String_): The wav file to analyze
  # Return:
  # * <em>map<Symbol,Object></em>: The analyze result
  def self.analyzeFile(iWaveFile)
    rResult = nil

    lAnalyzeFile = "#{$MusicMasterConf[:PrepareMix][:TempDir]}/#{File.basename(iWaveFile)}.analyze"
    if (!File.exists?(lAnalyzeFile))
      lDummyFile = "#{$MusicMasterConf[:PrepareMix][:TempDir]}/Dummy.wav"
      wsk(iWaveFile, lDummyFile, 'Analyze')
      File.unlink(lDummyFile)
      FileUtils::mv('analyze.result', lAnalyzeFile)
    end
    File.open(lAnalyzeFile, 'rb') do |iFile|
      rResult = Marshal.load(iFile.read)
    end

    return rResult
  end

  # Get the silence threshold of a given record type.
  # Remove the DC offset in the returned thresholds.
  #
  # Parameters:
  # * *iRecordType* (_String_): The record type
  # Return:
  # * <em>list<[Integer,Integer]></em>: Silence thresholds, per channel
  def self.getSilenceThresholds(iRecordType)
    rSilenceThresholds = []

    # Read the silence file
    lSilenceThresholdFile = "#{$MusicMasterConf[:PrepareMix][:TempDir]}/#{iRecordType}.Silence.threshold"
    if (!File.exists?(lSilenceThresholdFile))
      lResult = analyzeFile("#{iRecordType}.Silence.wav")
      # Compute the DC offsets
      lDCOffsets = lResult[:MoyValues].map { |iValue| iValue.round }
      lSilenceThresholds = []
      lResult[:MaxValues].each_with_index do |iMaxValue, iIdxChannel|
        # Remove DC Offset
        lCorrectedMinValue = lResult[:MinValues][iIdxChannel] - lDCOffsets[iIdxChannel]
        lCorrectedMaxValue = iMaxValue - lDCOffsets[iIdxChannel]
        # Compute the silence threshold by adding the margin
        lSilenceThresholds << [(lCorrectedMinValue-lCorrectedMinValue.abs*$MusicMasterConf[:PrepareMix][:MarginSilenceThresholds]).to_i, (lCorrectedMaxValue+lCorrectedMaxValue.abs*$MusicMasterConf[:PrepareMix][:MarginSilenceThresholds]).to_i]
      end
      # Write them
      File.open(lSilenceThresholdFile, 'wb') do |oFile|
        oFile.write(Marshal.dump(lSilenceThresholds))
      end
    end
    File.open(lSilenceThresholdFile, 'rb') do |iFile|
      rSilenceThresholds = Marshal.load(iFile.read)
    end
    logInfo "#{iRecordType} silence thresholds: #{rSilenceThresholds.join(', ')}"

    return rSilenceThresholds
  end

  # Generate the silence FFT profile of a record type.
  #
  # Parameters:
  # * *iRecordType* (_String_): The record type
  # Return:
  # * _String_: Name of the file containing the FFT profile
  def self.genSilenceFFTProfile(iRecordType)
    rFFTProfileFileName = "#{$MusicMasterConf[:PrepareMix][:TempDir]}/#{iRecordType}.Silence.fftprofile"

    if (!File.exists?(rFFTProfileFileName))
      lDummyFile = "#{$MusicMasterConf[:PrepareMix][:TempDir]}/Dummy.wav"
      wsk("#{iRecordType}.Silence.wav", lDummyFile, 'FFT')
      File.unlink(lDummyFile)
      FileUtils::mv('fft.result', rFFTProfileFileName)
    end

    return rFFTProfileFileName
  end

  # Generate the framed wave file corresponding to a specified wave file.
  # Framed wave removes silence at the beginning and end of the file, and then cut a specific section of the file
  # If the framed file already exists, it does nothing.
  #
  # Parameters:
  # * *iInputFile* (_String_): The file we want to frame
  # * *iStrSilenceThresholds* (_String_): The silence thresholds parameter
  # * *iBeginCut* (_String_): The begin marker to cut
  # * *iEndCut* (_String_): The end marker to cut
  # * *iSilenceFFTProfile* (_String_): Name of the file containing the silence FFT profile
  # Return:
  # * _String_: Name of the framed file
  def self.genFramedWave(iInputFile, iStrSilenceThresholds, iBeginCut, iEndCut, iSilenceFFTProfile)
    lBaseName = File.basename(iInputFile)[0..-5]
    lFileName_Framed = "#{$MusicMasterConf[:PrepareMix][:TempDir]}/#{lBaseName}_Framed.wav"
    if (File.exists?(lFileName_Framed))
      logInfo "File #{lFileName_Framed} already exists. Skipping its generation."
    else
      wsk(iInputFile, lFileName_Framed, 'SilenceRemover', "--silencethreshold \"#{iStrSilenceThresholds}\" --attack 0 --release 0 --noisefft \"#{iSilenceFFTProfile}\"")
    end
    # Cut the specific region
    lFileName_Cut = "#{$MusicMasterConf[:PrepareMix][:TempDir]}/#{lBaseName}_Cut.wav"
    if (File.exists?(lFileName_Cut))
      logInfo "File #{lFileName_Cut} already exists. Skipping its generation."
    else
      wsk(lFileName_Framed, lFileName_Cut, 'Cut', "--begin \"#{iBeginCut}\" --end \"#{iEndCut}\"")
    end
    # Remove its DC offset if needed
    lAnalyze = analyzeFile(lFileName_Cut)
    lDCOffsets = []
    lOffset = false
    lAnalyze[:MoyValues].each do |iValue|
      lDCOffset = iValue.round
      lDCOffsets << lDCOffset
      if (lDCOffset != 0)
        lOffset = true
      end
    end
    lFileName_DCOffset = nil
    if (lOffset)
      lFileName_DCOffset = "#{$MusicMasterConf[:PrepareMix][:TempDir]}/#{lBaseName}_DCOffset.wav"
      if (File.exists?(lFileName_DCOffset))
        logInfo "File #{lFileName_DCOffset} already exists. Skipping its generation."
      else
        wsk(lFileName_Cut, lFileName_DCOffset, 'DCShifter', "--offset \"#{lDCOffsets.map { |iValue| -iValue }.join('|')}\"")
      end
    else
      lFileName_DCOffset = lFileName_Cut
    end
    rFileName_NoiseGate = "#{$MusicMasterConf[:PrepareMix][:TempDir]}/#{lBaseName}_NoiseGate.wav"
    if (File.exists?(rFileName_NoiseGate))
      logInfo "File #{rFileName_NoiseGate} already exists. Skipping its generation."
    else
      wsk(lFileName_DCOffset, rFileName_NoiseGate, 'NoiseGate', "--silencethreshold \"#{iStrSilenceThresholds}\" --attack #{$MusicMasterConf[:NoiseGate][:Attack]} --release #{$MusicMasterConf[:NoiseGate][:Release]} --silencemin #{$MusicMasterConf[:NoiseGate][:SilenceMin]} --noisefft \"#{iSilenceFFTProfile}\"")
    end

    return rFileName_NoiseGate
  end

end

rErrorCode = 0
lRecordConfFile, lConfigFile = ARGV[0..1]
if ((lRecordConfFile == nil) or
    (lConfigFile == nil))
  puts 'Usage: PrepareMix <RecordConfFile> <MixConfFile>'
  rErrorCode = 1
elsif (File.exists?(lConfigFile))
  logErr "File #{lConfigFile} already exist."
  rErrorCode = 2
else
  lError, lRecordConf = MusicMaster::readRecordConf(lRecordConfFile)
  if (lError == nil)
    FileUtils::mkdir_p($MusicMasterConf[:PrepareMix][:TempDir])
    lConfig = MusicMaster::getConfig(lRecordConf)
    require 'pp'
    File.open(lConfigFile, 'w') do |oFile|
      oFile.write(lConfig.pretty_inspect)
    end
    logInfo "===== config saved in #{lConfigFile}"
  else
    logErr "Error: #{lError}"
    rErrorCode = 3
  end
end

exit rErrorCode
