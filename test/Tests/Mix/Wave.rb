module MusicMasterTest

  module Mix

    class Wave < ::Test::Unit::TestCase

      # No mix
      def testNoMix
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {}
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert !File.exists?('05_Mix')
        end
      end

      # Test mixing a normal Wave file
      def testNormal
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Wave.wav' => {}
                },
                :Processes => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam1'
                  }
                ]
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Test mixing a normal Wave file with an alias
      def testNormalWithAlias
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav',
                  :Alias => 'Track 1'
                }
              ]
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Track 1' => {}
                },
                :Processes => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam1'
                  }
                ]
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Test mixing a normal Wave file with an alias list
      def testNormalWithAliasList
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav',
                  :Alias => [ 'Track 1', 'Track 2' ]
                }
              ]
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Track 2' => {}
                },
                :Processes => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam1'
                  }
                ]
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Test mixing a processed Wave
      def testProcessed
        lProcessID = {
          :Param1 => 'TestParam1'
        }.unique_id
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav',
                  :Processes => [
                    {
                      :Name => 'Test',
                      :Param1 => 'TestParam1'
                    }
                  ]
                }
              ]
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Wave.wav' => {}
                },
                :Processes => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam2'
                  }
                ]
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ],
            [ 'Wave/Empty.wav', "04_Process/Wave/Wave.0.Test.#{lProcessID}.wav" ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => "04_Process/Wave/Wave.0.Test.#{lProcessID}.wav",
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam2'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

    end

  end

end
