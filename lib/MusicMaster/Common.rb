#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

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
    require 'rUtilAnts/Plugins'
    RUtilAnts::Plugins::initializePlugins
    lLibDir = File.expand_path(File.dirname(__FILE__))
    parsePluginsFromDir('Processes', "#{lLibDir}/Processes", 'MusicMaster::Processes')
  end

  # Apply given record effects on a Wave file.
  # It modifies the given Wave file.
  # It saves original and intermediate Wave files before modifications.
  #
  # Parameters:
  # * *iEffects* (<em>list<map<Symbol,Object>></em>): List of effects to apply
  # * *iFileName* (_String_): File name to apply effects to
  # * *iDir* (_String_): The directory where temporary files are stored
  def self.applyProcesses(iEffects, iFileName, iDir)
    lFileNameNoExt = File.basename(iFileName[0..-5])
    iEffects.each_with_index do |iEffectInfo, iIdxEffect|
      begin
        accessPlugin('Processes', iEffectInfo[:Name]) do |ioActionPlugin|
          # Save the file before using the plugin
          lSave = true
          lSaveFileName = "#{iDir}/#{lFileNameNoExt}.Before_#{iIdxEffect}_#{iEffectInfo[:Name]}.wav"
          if (File.exists?(lSaveFileName))
            puts "!!! File #{lSaveFileName} already exists. Overwrite and apply effect ? [y='yes']"
            lSave = ($stdin.gets.chomp == 'y')
          end
          if (lSave)
            logInfo "Saving file #{iFileName} to #{lSaveFileName} ..."
            FileUtils::mv(iFileName, lSaveFileName)
            logInfo "===== Apply Effect #{iEffectInfo[:Name]} to #{iFileName} ====="
            ioActionPlugin.execute(lSaveFileName, iFileName, iDir, iEffectInfo.clone.delete_if{|iKey, iValue| next (iKey == :Name)})
          end
        end
      rescue Exception
        logErr "An error occurred while processing #{iFileName} with process #{iEffectInfo[:Name]}: #{$!}."
        raise
      end
    end
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
              logWarn "Track #{iIdxTrack+1} is never recorded."
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

end
