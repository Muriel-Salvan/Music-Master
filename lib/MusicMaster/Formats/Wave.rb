#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMaster

  module Formats

    # Wave file format.
    # Take the following parameters:
    # * *:Dither* (_Boolean_): Do we apply dither while converting ?
    # * *:SampleRate* (_Integer_): Sample rate in Hz (ie 44100, 192000 ...)
    # * *:BitDepth* (_Integer_): Number of bits used to encode 1 sample on 1 channel (ie 8, 16, 24...)
    class Wave

      # Give the file extension
      #
      # Return::
      # * _String_: The file extension (without .)
      def getFileExt
        return 'wav'
      end

      # Deliver a file.
      # The delivered file can be a shortcut to the source one.
      #
      # Parameters::
      # * *iSrcFileName* (_String_): The source file to deliver from
      # * *iDstFileName* (_String_): The destination file to be delivered
      # * *iFormatConf* (<em>map<Symbol,Object></em>): The format configuration
      # * *iMetadata* (<em>map<Symbol,Object></em>): The metadata that can be used while delivering the file
      def deliver(iSrcFileName, iDstFileName, iFormatConf, iMetadata)
        # Check if we can just make a shortcut
        lShortcut = true
        if (!iFormatConf.empty?)
          if (iFormatConf[:Dither])
            lShortcut = false
          else
            # Need to get the source file attributes (sample rate and bit depth)
            require 'WSK/Common'
            self.class.module_eval('include WSK::Common')
            accessInputWaveFile(iSrcFileName) do |iHeader, iInputData|
              lShortcut = !(((iFormatConf[:SampleRate] != nil) and
                             (iFormatConf[:SampleRate] != iHeader.SampleRate)) or
                            ((iFormatConf[:BitDepth] != nil) and
                             (iFormatConf[:BitDepth] != iHeader.NbrBitsPerSample)))
              next nil
            end
          end
        end
        if (lShortcut)
          # Just create a shortcut
          createShortcut(iSrcFileName, iDstFileName)
        else
          # We need to convert the Wave file: call SSRC
          lTranslatedParams = [ '--profile standard', '--twopass' ]
          iFormatConf.each do |iParam, iValue|
            case iParam
            when :SampleRate
              lTranslatedParams << "--rate #{iValue}"
            when :BitDepth
              lTranslatedParams << "--bits #{iValue}"
            when :Dither
              lTranslatedParams << '--dither 4' if (iValue == true)
            else
              log_warn "Unknown Wave format parameter: #{iParam} (value #{iValue.inspect}). Ignoring it."
            end
          end
          lCmd = "#{@MusicMasterConf[:Formats]['Wave'][:SRCCmdLine]} #{lTranslatedParams.sort.join(' ')} \"#{iSrcFileName}\" \"#{iDstFileName}\""
          log_info "=> #{lCmd}"
          raise "Error while executing SSRC command \"#{lCmd}\": error code #{$?.exitstatus}" if (!system(lCmd)) or ($?.exitstatus != 0)
        end
      end

    end

  end

end
