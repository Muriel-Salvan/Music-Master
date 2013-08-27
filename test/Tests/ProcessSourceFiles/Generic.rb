module MusicMasterTest

  module ProcessSourceFiles

    # Tests of processes processing only. Those tests test functionnalities of every process' chain, wherever it is used.
    # For simplicity, tests will be conducted on simple Wave files.
    class Generic < ::Test::Unit::TestCase

      # Process sequencing
      def testSequence
        execute_Process_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav',
                  :Processes => [
                    {
                      :Name => 'Test',
                      :Param1 => 'TestParam0'
                    },
                    {
                      :Name => 'Test',
                      :Param1 => 'TestParam1'
                    },
                    {
                      :Name => 'Test',
                      :Param1 => 'TestParam2'
                    }
                  ]
                }
              ]
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('04_Process/Wave/Wave.0.Test.????????????????????????????????.wav')
          lWave1FileName = getFileFromGlob('04_Process/Wave/Wave.1.Test.????????????????????????????????.wav')
          lWave2FileName = getFileFromGlob('04_Process/Wave/Wave.2.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam0'
              }
            },
            {
              :InputFileName => lWave0FileName,
              :OutputFileName => lWave1FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            },
            {
              :InputFileName => lWave1FileName,
              :OutputFileName => lWave2FileName,
              :Params => {
                :Param1 => 'TestParam2'
              }
            }
          ], 'Process_Test.rb'
        end
      end

      # Processes are not optimized when the chain is interrupted
      def testOptimizationInterrupted
        execute_Process_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav',
                  :Processes => [
                    {
                      :Name => 'VolCorrection',
                      :Factor => '1db'
                    },
                    {
                      :Name => 'VolCorrection',
                      :Factor => '2db'
                    },
                    {
                      :Name => 'Test',
                      :Param1 => 'TestParam1'
                    },
                    {
                      :Name => 'VolCorrection',
                      :Factor => '4db'
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
              :Output => /04_Process\/Wave\/Wave\.0\.VolCorrection\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Multiply',
              :Params => [ '--coeff', '3.0db' ],
              :UseWave => 'Empty.wav'
            },
            {
              :Input => /04_Process\/Wave\/Wave\.1\.Test\.[[:xdigit:]]{32,32}\.wav/,
              :Output => /04_Process\/Wave\/Wave\.2\.VolCorrection\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Multiply',
              :Params => [ '--coeff', '4db' ],
              :UseWave => 'Empty.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('04_Process/Wave/Wave.0.VolCorrection.????????????????????????????????.wav')
          lWave1FileName = getFileFromGlob('04_Process/Wave/Wave.1.Test.????????????????????????????????.wav')
          getFileFromGlob('04_Process/Wave/Wave.2.VolCorrection.????????????????????????????????.wav')
          assert Dir.glob('04_Process/Wave/Wave.3.????????????????????????????????.wav').empty?
          assert_rb_content [
            {
              :InputFileName => lWave0FileName,
              :OutputFileName => lWave1FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
        end
      end

      # Processes are optimized recursively
      def testOptimizationRecursive
        execute_Process_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav',
                  :Processes => [
                    {
                      :Name => 'VolCorrection',
                      :Factor => '1db'
                    },
                    {
                      :Name => 'VolCorrection',
                      :Factor => '2db'
                    },
                    {
                      :Name => 'DCShifter',
                      :Offset => 5
                    },
                    {
                      :Name => 'DCShifter',
                      :Offset => -4
                    },
                    {
                      :Name => 'VolCorrection',
                      :Factor => '10db'
                    },
                    {
                      :Name => 'VolCorrection',
                      :Factor => '-10db'
                    },
                    {
                      :Name => 'DCShifter',
                      :Offset => -1
                    },
                    {
                      :Name => 'VolCorrection',
                      :Factor => '4db'
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
              :Output => /04_Process\/Wave\/Wave\.0\.VolCorrection\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Multiply',
              :Params => [ '--coeff', '7.0db' ],
              :UseWave => 'Empty.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          getFileFromGlob('04_Process/Wave/Wave.0.VolCorrection.????????????????????????????????.wav')
          assert Dir.glob('04_Process/Wave/Wave.1.????????????????????????????????.wav').empty?
        end
      end

    end

  end

end
