module MusicMaster

  module Processes

    class AddSilence

      # Execute the process
      #
      # Parameters:
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iOutputFileName* (_String_): File name to write
      # * *iTempDir* (_String_): Temporary directory that can be used
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters
      def execute(iInputFileName, iOutputFileName, iTempDir, iParams)
        MusicMaster::wsk(iInputFileName, iOutputFileName, 'SilenceInserter', "--begin \"#{iParams[:Begin]}\" --end \"#{iParams[:End]}\"")
      end

    end

  end

end