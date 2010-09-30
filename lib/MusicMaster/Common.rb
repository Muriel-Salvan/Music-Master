require 'fileutils'
require 'rational'

module MusicMaster

  # Call WSK
  #
  # Parameters:
  # * *iInputFile* (_String_): The input file
  # * *iOutputFile* (_String_): The output file
  # * *iAction* (_String_): The action
  # * *iParams* (_String_): Action parameters [optional = '']
  def self.wsk(iInputFile, iOutputFile, iAction, iParams = '')
    logInfo ''
    logInfo "========== Processing #{iInputFile} ==#{iAction}==> #{iOutputFile} | #{iParams} ..."
    system("#{$MusicMasterConf[:WSKCmdLine]} --input \"#{iInputFile}\" --output \"#{iOutputFile}\" --action #{iAction} -- #{iParams}")
    lErrorCode = $?.exitstatus
    if (lErrorCode == 0)
      logInfo "========== Processing #{iInputFile} ==#{iAction}==> #{iOutputFile} | #{iParams} ... OK"
    else
      logErr "========== Processing #{iInputFile} ==#{iAction}==> #{iOutputFile} | #{iParams} ... ERROR #{lErrorCode}"
      raise RuntimeError, "Processing #{iInputFile} ==#{iAction}==> #{iOutputFile} | #{iParams} ... ERROR #{lErrorCode}"
    end
    logInfo ''
  end

  # Parse plugins
  def self.parsePlugins
    lLibDir = File.expand_path(File.dirname(__FILE__))
    parsePluginsFromDir('RecordEffects', "#{lLibDir}/RecordEffects", 'MusicMaster::RecordEffects')
  end

  # Read record configuration.
  # Perform basic checks on it.
  #
  # Parameters:
  # * *iConfFile* (_String_): Configuration file
  # Return:
  # * _Exception_: Error, or nil in case of success
  # * <em>map<Symbol,Object></em>: The configuration
  def self.readRecordConf(iConfFile)
    rError = nil
    rConf = nil

    if (!File.exists?(iConfFile))
      rError = RuntimeError.new("Missing configuration file: #{iConfFile}")
    else
      File.open(iConfFile, 'r') do |iFile|
        rConf = eval(iFile.read)
      end
      # Check that all tracks are assigned somewhere, just once
      lLstTracks = nil
      if (rConf[:Patches] != nil)
        lLstTracks = rConf[:Patches].keys.clone
      else
        lLstTracks = []
      end
      if (rConf[:Performs] != nil)
        rConf[:Performs].each do |iLstPerform|
          lLstTracks.concat(iLstPerform)
        end
      end
      lAssignedTracks = {}
      lLstTracks.each do |iIdxTrack|
        if (lAssignedTracks.has_key?(iIdxTrack))
          rError = RuntimeError.new("Track #{iIdxTrack} is recorded twice.")
          break
        else
          lAssignedTracks[iIdxTrack] = nil
        end
      end
      if (rError == nil)
        if (rConf[:Patches] != nil)
          rConf[:Patches].each do |iIdxTrack, iTrackConf|
            if ((iTrackConf.has_key?(:VolCorrection)) and
                (iTrackConf.has_key?(:VolCompareCuts)))
              rError = RuntimeError.new("Patch track #{iIdxTrack} has both :VolCorrection and :VolCompareCuts values defined.")
            elsif ((!iTrackConf.has_key?(:VolCorrection)) and
                   (!iTrackConf.has_key?(:VolCompareCuts)))
              rError = RuntimeError.new("Patch track #{iIdxTrack} has neither :VolCorrection nor :VolCompareCuts values defined.")
            end
          end
        end
        if (rError == nil)
          lAssignedTracks.size.times do |iIdxTrack|
            if (!lAssignedTracks.has_key?(iIdxTrack+1))
              puts "Track #{iIdxTrack+1} is never recorded. Continue ? y='yes'"
              lContinue = ($stdin.gets.chomp == 'y')
              if (!lContinue)
                rError = RuntimeError.new("Track #{iIdxTrack+1} is never recorded.")
                break
              end
            end
          end
        end
      end
    end

    return rError, rConf
  end

  # Convert a Wave file to another
  #
  # Parameters:
  # * *iSrcFile* (_String_): Source WAVE file
  # * *iDstFile* (_String_): Destination WAVE file
  # * *iParams* (<em>map<Symbol,Object></em>): The parameters:
  # ** *:SampleRate* (_Integer_): The new sample rate in Hz
  # ** *:BitDepth* (_Integer_): The new bit depth (only for Wave) [optional = nil]
  # ** *:Dither* (_Boolean_): Do we apply dither (only for Wave) ? [optional = false]
  # ** *:BitRate* (_Integer_): Bit rate in kbps (only for MP3) [optional = 320]
  # ** *:FileFormat* (_Symbol_); File format. Here are the possible values: [optional = :Wave]
  # *** *:Wave*: Uncompressed PCM Wave file
  # *** *:MP3*: MP3 file
  def self.src(iSrcFile, iDstFile, iParams)
    if ((iParams[:FileFormat] != nil) and
        (iParams[:FileFormat] == :MP3))
      # MP3 conversion
      lTranslatedParams = []
      iParams.each do |iParam, iValue|
        case iParam
        when :SampleRate
          lTranslatedParams << "Sample rate: #{iValue} Hz"
        when :BitRate
          lTranslatedParams << "Bit rate: #{iValue} kbps"
        when :FileFormat
          # Nothing to do
        else
          logErr "Unknown MP3 parameter: #{iParam} (value #{iValue.inspect}). Ignoring it."
        end
      end
      puts "Convert file #{iSrcFile} into file #{iDstFile} in MP3 format with following parameters: #{lTranslatedParams.join(', ')}"
      puts 'Press Enter when done.'
      $stdin.gets
    else
      # Wave conversion
      lTranslatedParams = [ '--profile standard', '--twopass' ]
      iParams.each do |iParam, iValue|
        case iParam
        when :SampleRate
          lTranslatedParams << "--rate #{iValue}"
        when :BitDepth
          lTranslatedParams << "--bits #{iValue}"
        when :Dither
          if (iValue == true)
            lTranslatedParams << '--dither 4'
          end
        when :FileFormat
          # Nothing to do
        else
          logErr "Unknown Wave parameter: #{iParam} (value #{iValue.inspect}). Ignoring it."
        end
      end
      FileUtils::mkdir_p(File.dirname(iDstFile))
      lCmd = "#{$MusicMasterConf[:SRCCmdLine]} #{lTranslatedParams.join(' ')} \"#{iSrcFile}\" \"#{iDstFile}\""
      logInfo "=> #{lCmd}"
      system(lCmd)
    end
  end

  # Apply a list of Mastering processes to a file
  #
  # Parameters:
  # * *iWaveFileName* (_String_): Name of the wave file
  # * *iMasteringProcesses* (<em>list<[Symbol,...]></em>): List of mastering processes with their parameters
  # * *iDir* (_String_): Directory to be used to store generated files
  # Return:
  # * _String_: Name of the resulting file
  def self.applyMasteringProcesses(iWaveFileName, iMasteringProcesses, iDir)
    rWaveFileToProcess = iWaveFileName

    lRealBaseName = File.basename(iWaveFileName)[0..-5]
    iMasteringProcesses.each_with_index do |iProcessInfo, iIdxProcess|
      lSymProcess = iProcessInfo[0]
      lNewFile = "#{iDir}/#{lRealBaseName}_#{iIdxProcess}_#{lSymProcess.to_s}.wav"
      self.process(rWaveFileToProcess, lNewFile, lSymProcess, iProcessInfo[1..-1], iDir)
      rWaveFileToProcess = lNewFile
    end

    return rWaveFileToProcess
  end

  # Process a wave file with a mastering process
  #
  # Parameters:
  # * *iInputWaveFile* (_String_): Wave file to process
  # * *iOutputWaveFile* (_String_): Wave file to be written
  # * *iSymProcess* (_Symbol_): Symbol identifying the process
  # * *iProcessParams* (<em>list<Object></em>): The process parameters
  # * *iDir* (_String_): Directory to be used to store generated files
  def self.process(iInputWaveFile, iOutputWaveFile, iSymProcess, iProcessParams, iDir)
    if (File.exists?(iOutputWaveFile))
      logWarn "File #{iOutputWaveFile} already exists. Will not overwrite it."
    else
      case iSymProcess
      when :CutFirstSignal
        wsk(iInputWaveFile, iOutputWaveFile, 'CutFirstSignal', "--silencethreshold 0 --noisefft none --silencemin \"#{$MusicMasterConf[:PrepareMix][:NoiseGate_SilenceMin]}\"")
      when :Normalize
        # First, analyze
        lAnalyzeResultFileName = "#{iDir}/#{File.basename(iInputWaveFile)}.analyze"
        if (File.exists?(lAnalyzeResultFileName))
          logWarn "File #{lAnalyzeResultFileName} already exists. Will not overwrite it."
        else
          wsk(iInputWaveFile, "#{iDir}/Dummy.wav", 'Analyze')
          File.unlink("#{iDir}/Dummy.wav")
          FileUtils::mv('analyze.result', lAnalyzeResultFileName)
        end
        lAnalyzeResult = nil
        File.open(lAnalyzeResultFileName, 'rb') do |iFile|
          lAnalyzeResult = Marshal.load(iFile.read)
        end
        lMaxDataValue = lAnalyzeResult[:MaxValues].sort[-1]
        lMinDataValue = lAnalyzeResult[:MinValues].sort[0]
        lMaxPossibleValue = (2**(lAnalyzeResult[:SampleSize]-1)) - 1
        lMinPossibleValue = -(2**(lAnalyzeResult[:SampleSize]-1))
        lCoeffNormalizeMax = Rational(lMaxPossibleValue, lMaxDataValue)
        lCoeffNormalizeMin = Rational(lMinPossibleValue, lMinDataValue)
        lCoeff = lCoeffNormalizeMax
        if (lCoeffNormalizeMin < lCoeff)
          lCoeff = lCoeffNormalizeMin
        end
        logInfo "Maximal value: #{lMaxDataValue}/#{lMaxPossibleValue}. Minimal value: #{lMinDataValue}/#{lMinPossibleValue}. Volume correction: #{lCoeff}."
        wsk(iInputWaveFile, iOutputWaveFile, 'Multiply', "--coeff \"#{lCoeff.numerator}/#{lCoeff.denominator}\"")
      when :VolCorrection
        wsk(iInputWaveFile, iOutputWaveFile, 'Multiply', "--coeff \"#{iProcessParams[0]}\"")
      when :Compressor
        logInfo "Copying #{iInputWaveFile} => #{iOutputWaveFile} ..."
        FileUtils::cp(iInputWaveFile, iOutputWaveFile)
        puts "Apply Compressor on file #{iOutputWaveFile}"
        puts 'Press Enter when done ...'
        $stdin.gets
      when :AddEndingSilence
        wsk(iInputWaveFile, iOutputWaveFile, 'SilenceInserter', "--silence \"#{iProcessParams[0]}\" --endoffile 1")
      when :AddBeginningSilence
        wsk(iInputWaveFile, iOutputWaveFile, 'SilenceInserter', "--silence \"#{iProcessParams[0]}\" --endoffile 0")
      else
        logErr "Unknown Mastering process: #{iSymProcess.to_s}"
      end
    end
  end

end
