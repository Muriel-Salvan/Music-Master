#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMaster

  module Processes

    class DCShifter

      # Parameters of this process:
      # * *:Offset* (_Integer_): The DC offset to apply (can be negative). The value's effect depends on the bit depth. A value of 64 in a 8 bits file will shift 50%. A value of 64 in a 16 bits file will shift 0.2%.

      # Execute the process
      #
      # Parameters::
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iOutputFileName* (_String_): File name to write
      # * *iTempDir* (_String_): Temporary directory that can be used
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters
      def execute(iInputFileName, iOutputFileName, iTempDir, iParams)
        wsk(iInputFileName, iOutputFileName, 'DCShifter', "--offset \"#{iParams[:Offset]}\"")
      end

    end

  end

end