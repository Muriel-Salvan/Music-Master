#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMaster

  module Processes

    class CutFirstSignal

      # Execute the process
      #
      # Parameters::
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iOutputFileName* (_String_): File name to write
      # * *iTempDir* (_String_): Temporary directory that can be used
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters
      def execute(iInputFileName, iOutputFileName, iTempDir, iParams)
        wsk(iInputFileName, iOutputFileName, 'CutFirstSignal', "--silencethreshold 0 --noisefft none --silencemin \"#{$MusicMasterConf[:NoiseGate][:SilenceMin]}\"")
      end

    end

  end

end