module MusicMasterTest

  module ProcessSourceFiles

    module Processes

      class Normalize < ::Test::Unit::TestCase

        # Normal invocation
        def testNormalUsage
          execute_Process_WithConf({
              :WaveFiles => {
                :FilesList => [
                  {
                    :Name => 'Wave.wav',
                    :Processes => [
                      {
                        :Name => 'Normalize'
                      }
                    ]
                  }
                ]
              }
            },
            :PrepareFiles => [
              [ 'Wave/Sine1s.wav', 'Wave.wav' ]
            ],
            :FakeWSK => [
              {
                :Input => 'Wave.wav',
                :Output => './Dummy.wav',
                :Action => 'Analyze',
                :UseWave => 'Empty.wav',
                :CopyFiles => { 'Analysis/Sine1s.analyze' => 'analyze.result' }
              },
              {
                :Input => 'Wave.wav',
                :Output => /04_Process\/Wave\/Wave\.0\.Normalize\.[[:xdigit:]]{32,32}\.wav/,
                :Action => 'Multiply',
                :Params => [ '--coeff', '32768/26223' ],
                :UseWave => 'Empty.wav',
              }
          ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            getFileFromGlob('04_Process/Wave/Wave.0.Normalize.????????????????????????????????.wav')
            assert File.exists?('Wave.wav.analyze')
          end
        end

        # Normalize a file already at its peak
        def testAlreadyPeak
          execute_Process_WithConf({
              :WaveFiles => {
                :FilesList => [
                  {
                    :Name => 'Wave.wav',
                    :Processes => [
                      {
                        :Name => 'Normalize'
                      }
                    ]
                  }
                ]
              }
            },
            :PrepareFiles => [
              [ 'Wave/Peak1s.wav', 'Wave.wav' ]
            ],
            :FakeWSK => [
              {
                :Input => 'Wave.wav',
                :Output => './Dummy.wav',
                :Action => 'Analyze',
                :UseWave => 'Empty.wav',
                :CopyFiles => { 'Analysis/Peak1s.analyze' => 'analyze.result' }
              },
              {
                :Input => 'Wave.wav',
                :Output => /04_Process\/Wave\/Wave\.0\.Normalize\.[[:xdigit:]]{32,32}\.wav/,
                :Action => 'Multiply',
                :Params => [ '--coeff', '1/1' ],
                :UseWave => 'Empty.wav',
              }
          ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            getFileFromGlob('04_Process/Wave/Wave.0.Normalize.????????????????????????????????.wav')
            assert File.exists?('Wave.wav.analyze')
          end
        end

      end

    end

  end

end
