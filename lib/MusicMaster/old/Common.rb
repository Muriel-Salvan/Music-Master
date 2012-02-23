#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMaster

  # Apply given record effects on a Wave file.
  # It modifies the given Wave file.
  # It saves original and intermediate Wave files before modifications.
  #
  # Parameters::
  # * *iEffects* (<em>list<map<Symbol,Object>></em>): List of effects to apply
  # * *iFileName* (_String_): File name to apply effects to
  # * *iDir* (_String_): The directory where temporary files are stored
  def self.applyProcesses(iEffects, iFileName, iDir)
    lFileNameNoExt = File.basename(iFileName[0..-5])
    iEffects.each_with_index do |iEffectInfo, iIdxEffect|
      begin
        access_plugin('Processes', iEffectInfo[:Name]) do |ioActionPlugin|
          # Save the file before using the plugin
          lSave = true
          lSaveFileName = "#{iDir}/#{lFileNameNoExt}.Before_#{iIdxEffect}_#{iEffectInfo[:Name]}.wav"
          if (File.exists?(lSaveFileName))
            puts "!!! File #{lSaveFileName} already exists. Overwrite and apply effect ? [y='yes']"
            lSave = ($stdin.gets.chomp == 'y')
          end
          if (lSave)
            log_info "Saving file #{iFileName} to #{lSaveFileName} ..."
            FileUtils::mv(iFileName, lSaveFileName)
            log_info "===== Apply Effect #{iEffectInfo[:Name]} to #{iFileName} ====="
            ioActionPlugin.execute(lSaveFileName, iFileName, iDir, iEffectInfo.clone.delete_if{|iKey, iValue| next (iKey == :Name)})
          end
        end
      rescue Exception
        log_err "An error occurred while processing #{iFileName} with process #{iEffectInfo[:Name]}: #{$!}."
        raise
      end
    end
  end

  # Convert a Wave file to another music file
  #
  # Parameters::
  # * *iSrcFile* (_String_): Source WAVE file
  # * *iDstFile* (_String_): Destination file
  # * *iParams* (<em>map<Symbol,Object></em>): The parameters:
  #   * *:SampleRate* (_Integer_): The new sample rate in Hz
  #   * *:BitDepth* (_Integer_): The new bit depth (only for Wave) [optional = nil]
  #   * *:Dither* (_Boolean_): Do we apply dither (only for Wave) ? [optional = false]
  #   * *:BitRate* (_Integer_): Bit rate in kbps (only for MP3) [optional = 320]
  #   * *:FileFormat* (_Symbol_): File format. Here are the possible values: [optional = :Wave]
  #     * *:Wave*: Uncompressed PCM Wave file
  #     * *:MP3*: MP3 file
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
          log_err "Unknown MP3 parameter: #{iParam} (value #{iValue.inspect}). Ignoring it."
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
          log_err "Unknown Wave parameter: #{iParam} (value #{iValue.inspect}). Ignoring it."
        end
      end
      FileUtils::mkdir_p(File.dirname(iDstFile))
      lCmd = "#{$MusicMasterConf[:SRCCmdLine]} #{lTranslatedParams.join(' ')} \"#{iSrcFile}\" \"#{iDstFile}\""
      log_info "=> #{lCmd}"
      system(lCmd)
    end
  end

end
