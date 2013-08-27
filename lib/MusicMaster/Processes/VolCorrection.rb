module MusicMaster

  module Processes

    class VolCorrection

      # Parameters of this process:
      # * *:Factor* (_String_): The volume correction factor, either in ratio ('3/4') or db ('-2db')

      # Execute the process
      #
      # Parameters::
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iOutputFileName* (_String_): File name to write
      # * *iTempDir* (_String_): Temporary directory that can be used
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters
      def execute(iInputFileName, iOutputFileName, iTempDir, iParams)
        wsk(iInputFileName, iOutputFileName, 'Multiply', "--coeff \"#{iParams[:Factor]}\"")
      end

    end

  end

end
