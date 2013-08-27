module MusicMaster

  module Processes

    class Test

      # Execute the process
      #
      # Parameters::
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iOutputFileName* (_String_): File name to write
      # * *iTempDir* (_String_): Temporary directory that can be used
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters
      def execute(iInputFileName, iOutputFileName, iTempDir, iParams)
        log_info "Copying #{iInputFileName} => #{iOutputFileName} for testing purposes ..."
        FileUtils::cp(iInputFileName, iOutputFileName)
        # Dump parameters in a file
        # list<map<Symbol,Object>>
        lProcesses = (File.exists?('Process_Test.rb')) ? eval(File.read('Process_Test.rb')) : []
        lProcesses << {
          :InputFileName => iInputFileName,
          :OutputFileName => iOutputFileName,
          :Params => iParams
        }
        File.open('Process_Test.rb', 'w') do |oFile|
          oFile.write(lProcesses.inspect)
        end
      end

    end

  end

end
