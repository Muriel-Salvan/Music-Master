#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMaster

  module Processes

    class Custom

      # Execute the process
      #
      # Parameters:
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iOutputFileName* (_String_): File name to write
      # * *iTempDir* (_String_): Temporary directory that can be used
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters
      def execute(iInputFileName, iOutputFileName, iTempDir, iParams)
        logInfo "Copying #{iInputFileName} => #{iOutputFileName} ..."
        FileUtils::cp(iInputFileName, iOutputFileName)
        puts "Apply custom process on file #{iOutputFileName}. Parameters: #{iParams.inspect}"
        puts 'Press Enter when done ...'
        $stdin.gets
      end

    end

  end

end