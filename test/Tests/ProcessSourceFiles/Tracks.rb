#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  module ProcessSourceFiles

    class Tracks < ::Test::Unit::TestCase

      # No processing
      def testNoProcessing
        execute_Process_WithConf({
            :Recordings => {
              :Tracks => {
                [1] => {
                  :Env => :Env1
                }
              }
            }
          },
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1, :Cleaned_Env1_1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert !File.exists?('04_Process/Record')
        end
      end

      # Processing attached to a specific recording
      def testProcessingRecording
        execute_Process_WithConf({
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
            }
          },
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1, :Cleaned_Env1_1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('04_Process/Record/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
        end
      end

      # Processing attached to the recording environment - before
      def testProcessingRecordingEnvBefore
        execute_Process_WithConf({
            :Recordings => {
              :Tracks => {
                [1] => {
                  :Env => :Env1
                }
              },
              :EnvProcesses_Before => {
                :Env1 => [
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
          lWave0FileName = getFileFromGlob('04_Process/Record/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
        end
      end

      # Processing attached to the recording environment - after
      def testProcessingRecordingEnvAfter
        execute_Process_WithConf({
            :Recordings => {
              :Tracks => {
                [1] => {
                  :Env => :Env1
                }
              },
              :EnvProcesses_After => {
                :Env1 => [
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
          lWave0FileName = getFileFromGlob('04_Process/Record/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
        end
      end

      # Processing attached globally before
      def testProcessingRecordingGlobalBefore
        execute_Process_WithConf({
            :Recordings => {
              :Tracks => {
                [1] => {
                  :Env => :Env1
                }
              },
              :GlobalProcesses_Before => [
                {
                  :Name => 'Test',
                  :Param1 => 'TestParam1'
                }
              ]
            }
          },
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1, :Cleaned_Env1_1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('04_Process/Record/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
        end
      end

      # Processing attached globally after
      def testProcessingRecordingGlobalAfter
        execute_Process_WithConf({
            :Recordings => {
              :Tracks => {
                [1] => {
                  :Env => :Env1
                }
              },
              :GlobalProcesses_After => [
                {
                  :Name => 'Test',
                  :Param1 => 'TestParam1'
                }
              ]
            }
          },
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1, :Cleaned_Env1_1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('04_Process/Record/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
        end
      end

      # Otder of processing has to be respected
      def testProcessingOrder
        execute_Process_WithConf({
            :Recordings => {
              :Tracks => {
                [1] => {
                  :Env => :Env1,
                  :Processes => [
                    {
                      :Name => 'Test',
                      :Param1 => 'TestParam2'
                    }
                  ]
                }
              },
              :EnvProcesses_Before => {
                :Env1 => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam1'
                  }
                ]
              },
              :EnvProcesses_After => {
                :Env1 => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam3'
                  }
                ]
              },
              :GlobalProcesses_Before => [
                {
                  :Name => 'Test',
                  :Param1 => 'TestParam0'
                }
              ],
              :GlobalProcesses_After => [
                {
                  :Name => 'Test',
                  :Param1 => 'TestParam4'
                }
              ]
            }
          },
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1, :Cleaned_Env1_1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('04_Process/Record/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav')
          lWave1FileName = getFileFromGlob('04_Process/Record/Env1.1.04.NoiseGate.1.Test.????????????????????????????????.wav')
          lWave2FileName = getFileFromGlob('04_Process/Record/Env1.1.04.NoiseGate.2.Test.????????????????????????????????.wav')
          lWave3FileName = getFileFromGlob('04_Process/Record/Env1.1.04.NoiseGate.3.Test.????????????????????????????????.wav')
          lWave4FileName = getFileFromGlob('04_Process/Record/Env1.1.04.NoiseGate.4.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
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
            },
            {
              :InputFileName => lWave2FileName,
              :OutputFileName => lWave3FileName,
              :Params => {
                :Param1 => 'TestParam3'
              }
            },
            {
              :InputFileName => lWave3FileName,
              :OutputFileName => lWave4FileName,
              :Params => {
                :Param1 => 'TestParam4'
              }
            }
          ], 'Process_Test.rb'
        end
      end

      # Processing attached to a specific recording that was calibrated
      def testProcessingCalibratedRecording
        execute_Process_WithConf({
            :Recordings => {
              :EnvCalibration => {
                [ :Env1, :Env2 ] => {
                  :CompareCuts => ['0.01s', '0.16s']
                }
              },
              :Tracks => {
                [1] => {
                  :Env => :Env1,
                  :CalibrateWithEnv => :Env2,
                  :Processes => [
                    {
                      :Name => 'Test',
                      :Param1 => 'TestParam1'
                    }
                  ]
                }
              }
            }
          },
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1_CalibEnv2, :Cleaned_Env1_1_CalibEnv2, :Calibrated_Env1_1_CalibEnv2)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert Dir.glob('04_Process/Record/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav').empty?
          lWave0FileName = getFileFromGlob('04_Process/Record/Env1.1.Calibrated.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '03_Calibrate/Record/Env1.1.Calibrated.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
        end
      end

      # Processing attached to a specific recording that could have been calibrated but calibration was useless after analysis
      def testProcessingUselessCalibratedRecording
        execute_Process_WithConf({
            :Recordings => {
              :EnvCalibration => {
                [ :Env1, :Env4 ] => {
                  :CompareCuts => ['0.01s', '0.16s']
                }
              },
              :Tracks => {
                [1] => {
                  :Env => :Env1,
                  :CalibrateWithEnv => :Env4,
                  :Processes => [
                    {
                      :Name => 'Test',
                      :Param1 => 'TestParam1'
                    }
                  ]
                }
              }
            }
          },
          :PrepareFiles => getPreparedFiles(:Recorded_Env1_1_CalibEnv4, :Cleaned_Env1_1_CalibEnv4, :Calibrated_Env1_1_CalibEnv4)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert Dir.glob('04_Process/Record/Env1.1.Calibrated.0.Test.????????????????????????????????.wav').empty?
          lWave0FileName = getFileFromGlob('04_Process/Record/Env1.1.04.NoiseGate.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
        end
      end

    end

  end

end
