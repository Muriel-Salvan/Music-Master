#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMaster

  module Processes

    class SilenceInserter

      # Parameters of this process:
      # * *:Begin* (_String_): Length of silence to insert in samples or in float seconds (ie. '234' or '25.3s') at the beginning of the file
      # * *:End* (_String_): Length of silence to insert in samples or in float seconds (ie. '234' or '25.3s') at the end of the file

      # Execute the process
      #
      # Parameters::
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iOutputFileName* (_String_): File name to write
      # * *iTempDir* (_String_): Temporary directory that can be used
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters
      def execute(iInputFileName, iOutputFileName, iTempDir, iParams)
        wsk(iInputFileName, iOutputFileName, 'SilenceInserter', "--begin \"#{iParams[:Begin]}\" --end \"#{iParams[:End]}\"")
      end

    end

  end

end