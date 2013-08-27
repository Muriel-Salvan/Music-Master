module MusicMasterTest

  module ProcessSourceFiles

    module Processes

      class SilenceInserter < ::Test::Unit::TestCase

        # Normal invocation
        def testNormalUsage
          execute_Process_WithConf({
              :WaveFiles => {
                :FilesList => [
                  {
                    :Name => 'Wave.wav',
                    :Processes => [
                      {
                        :Name => 'SilenceInserter',
                        :Begin => '0.1s',
                        :End => '0.9s'
                      }
                    ]
                  }
                ]
              }
            },
            :PrepareFiles => [
              [ 'Wave/Empty.wav', 'Wave.wav' ]
            ],
            :FakeWSK => [
              {
                :Input => 'Wave.wav',
                :Output => /04_Process\/Wave\/Wave\.0\.SilenceInserter\.[[:xdigit:]]{32,32}\.wav/,
                :Action => 'SilenceInserter',
                :Params => [ '--begin', '0.1s', '--end', '0.9s' ],
                :UseWave => 'Empty.wav'
              }
          ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            getFileFromGlob('04_Process/Wave/Wave.0.SilenceInserter.????????????????????????????????.wav')
          end
        end

      end

    end

  end

end
