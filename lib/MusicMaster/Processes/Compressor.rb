module MusicMaster

  module Processes

    class Compressor

      # Execute the process
      #
      # Parameters:
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iOutputFileName* (_String_): File name to write
      # * *iTempDir* (_String_): Temporary directory that can be used
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters
      def execute(iInputFileName, iOutputFileName, iTempDir, iParams)
        # TODO: Implement an automated one
        logInfo "Copying #{iInputFileName} => #{iOutputFileName} ..."
        FileUtils::cp(iInputFileName, iOutputFileName)
        puts "Apply Compressor on file #{iOutputFileName}"
        puts 'Press Enter when done ...'
        $stdin.gets
      end

    end

  end

end