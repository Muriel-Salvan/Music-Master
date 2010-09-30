module MusicMaster

  module RecordEffects

    class GVerb

      # Execute
      #
      # Parameters:
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters written in the configuration file
      def execute(iInputFileName, iParams)
        puts "===> Apply GVerb from Audacity to file #{iInputFileName}"
        puts 'Press Enter when done.'
        $stdin.gets
      end

    end

  end

end