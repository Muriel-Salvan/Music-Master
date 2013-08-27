module MusicMasterTest

  module ProcessSourceFiles

    module Processes

      class Custom < ::Test::Unit::TestCase

        # Normal invocation
        def testNormalUsage
          lProcessID = {
            :CustomParam1 => 'Param1Value'
          }.unique_id
          execute_Process_WithConf({
              :WaveFiles => {
                :FilesList => [
                  {
                    :Name => 'Wave.wav',
                    :Processes => [
                      {
                        :Name => 'Custom',
                        :CustomParam1 => 'Param1Value'
                      }
                    ]
                  }
                ]
              }
            },
            :PrepareFiles => [
              [ 'Wave/Empty.wav', 'Wave.wav' ]
            ],
            :PilotingCode => Proc.new do |oStdIN, iStdOUT, iStdERR, iChildProcess|
              lLstLines = iStdOUT.gets_until("Press Enter when done ...\n", :time_out_secs => 10)
              assert_equal "Apply custom process on file 04_Process/Wave/Wave.0.Custom.#{lProcessID}.wav. Parameters: {:CustomParam1=>\"Param1Value\"}\n", lLstLines[-2]
              assert_raise(Timeout::Error) do
                iStdOUT.gets(:time_out_secs => 2)
              end
              oStdIN.write("\n")
              iStdOUT.gets_until("Processed finished successfully.\n", :time_out_secs => 10)
            end) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            getFileFromGlob('04_Process/Wave/Wave.0.Custom.????????????????????????????????.wav')
          end
        end

      end

    end

  end

end
