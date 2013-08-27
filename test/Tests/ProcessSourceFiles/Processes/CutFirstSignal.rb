module MusicMasterTest

  module ProcessSourceFiles

    module Processes

      class CutFirstSignal < ::Test::Unit::TestCase

        # Normal invocation
        def testNormalUsage
          execute_Process_WithConf({
              :WaveFiles => {
                :FilesList => [
                  {
                    :Name => 'Wave.wav',
                    :Processes => [
                      {
                        :Name => 'CutFirstSignal',
                        :SilenceMin => '1s'
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
                :Output => /04_Process\/Wave\/Wave\.0\.CutFirstSignal\.[[:xdigit:]]{32,32}\.wav/,
                :Action => 'CutFirstSignal',
                :Params => [ '--silencethreshold', '0', '--noisefft', 'none', '--silencemin', '1s' ],
                :UseWave => 'Empty.wav'
              }
          ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            getFileFromGlob('04_Process/Wave/Wave.0.CutFirstSignal.????????????????????????????????.wav')
          end
        end

      end

    end

  end

end
