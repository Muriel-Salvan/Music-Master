module MusicMaster

  module Processes

    class GVerb

      # Execute the process
      #
      # Parameters:
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iOutputFileName* (_String_): File name to write
      # * *iTempDir* (_String_): Temporary directory that can be used
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters
      def execute(iInputFileName, iOutputFileName, iTempDir, iParams)
        puts "===> Apply GVerb from Audacity to file #{iInputFileName} and write file #{iOutputFileName}"
        puts "===> Parameters: #{iParams.inspect}"
        puts 'Press Enter when done.'
        $stdin.gets
      end

    end

  end

end