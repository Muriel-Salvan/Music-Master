#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  module Mix

    class Tracks < ::Test::Unit::TestCase

      # No mix
      def testNoMix
        execute_Mix_WithConf({
            :Recordings => {
              :Tracks => {
                [1] => {
                  :Env => :Env1
                }
              }
            },
            :Mix => {}
          },
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1, :Cleaned_Env1_1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert !File.exists?('05_Mix')
        end
      end

      # Test mixing a single recorded file
      def testNormalTrack
        execute_Mix_WithConf({
            :Recordings => {
              :Tracks => {
                [1] => {
                  :Env => :Env1
                }
              }
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  [1] => {}
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
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1, :Cleaned_Env1_1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert Dir.glob('05_Mix/Env1.1.Calibrated.0.Test.????????????????????????????????.wav').empty?
          assert_wave_lnk '02_Clean/Record/Env1.1.04.NoiseGate', '05_Mix/Final/Final.wav'
        end
      end

      # Test mixing a single recorded file with a single alias
      def testNormalTrackWithSingleAlias
        execute_Mix_WithConf({
            :Recordings => {
              :Tracks => {
                [1] => {
                  :Env => :Env1,
                  :Alias => 'Track 1'
                }
              }
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
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1, :Cleaned_Env1_1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert Dir.glob('05_Mix/Env1.1.Calibrated.0.Test.????????????????????????????????.wav').empty?
          assert_wave_lnk '02_Clean/Record/Env1.1.04.NoiseGate', '05_Mix/Final/Final.wav'
        end
      end

      # Test mixing a single recorded file with an alias list
      def testNormalTrackWithAliasList
        execute_Mix_WithConf({
            :Recordings => {
              :Tracks => {
                [1] => {
                  :Env => :Env1,
                  :Alias => [ 'Track 1', 'Track 2' ]
                }
              }
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
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1, :Cleaned_Env1_1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert Dir.glob('05_Mix/Env1.1.Calibrated.0.Test.????????????????????????????????.wav').empty?
          assert_wave_lnk '02_Clean/Record/Env1.1.04.NoiseGate', '05_Mix/Final/Final.wav'
        end
      end

      # Test mixing a single recorded file with calibration
      def testCalibratedTrack
        execute_Mix_WithConf({
            :Recordings => {
              :EnvCalibration => {
                [ :Env1, :Env2 ] => {
                  :CompareCuts => ['0.01s', '0.16s']
                }
              },
              :Tracks => {
                [1] => {
                  :Env => :Env1,
                  :CalibrateWithEnv => :Env2
                }
              }
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  [1] => {}
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
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1_CalibEnv2, :Cleaned_Env1_1_CalibEnv2, :Calibrated_Env1_1_CalibEnv2)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Env1.1.Calibrated.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '03_Calibrate/Record/Env1.1.Calibrated.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert Dir.glob('05_Mix/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav').empty?
          assert_wave_lnk '03_Calibrate/Record/Env1.1.Calibrated', '05_Mix/Final/Final.wav'
        end
      end

      # Test mixing a single recorded file with useless calibration
      def testUselessCalibratedTrack
        execute_Mix_WithConf({
            :Recordings => {
              :EnvCalibration => {
                [ :Env1, :Env4 ] => {
                  :CompareCuts => ['0.01s', '0.16s']
                }
              },
              :Tracks => {
                [1] => {
                  :Env => :Env1,
                  :CalibrateWithEnv => :Env4
                }
              }
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  [1] => {}
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
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1_CalibEnv4, :Cleaned_Env1_1_CalibEnv4, :Calibrated_Env1_1_CalibEnv4)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert Dir.glob('05_Mix/Env1.1.Calibrated.0.Test.????????????????????????????????.wav').empty?
          assert_wave_lnk '02_Clean/Record/Env1.1.04.NoiseGate', '05_Mix/Final/Final.wav'
        end
      end

      # Test mixing a single recorded file with processing
      def testProcessedTrack
        lProcessID = {
          :Param1 => 'TestParam1'
        }.unique_id
        execute_Mix_WithConf({
            :Recordings => {
              :Tracks => {
                [1] => {
                  :Env => :Env1,
                  :Processes => [
                    {
                      :Name => 'Test',
                      :Param1 => 'TestParam1'
                    }
                  ]
                }
              }
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  [1] => {}
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
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1, :Cleaned_Env1_1, :Processed_Env1_1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Env1.1.04.NoiseGate.0.Test.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => "04_Process/Record/Env1.1.04.NoiseGate.0.Test.#{lProcessID}.wav",
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam2'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk '02_Clean/Record/Env1.1.04.NoiseGate', '05_Mix/Final/Final.wav'
        end
      end

    end

  end

end
