#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  module ProcessSourceFiles

    class Wave < ::Test::Unit::TestCase

      # No processing
      def testNoProcessing
        execute_Process_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert !File.exists?('04_Process/Wave')
        end
      end

      # Processing attached to a specific Wave file
      def testProcessingWave
        execute_Process_WithConf({
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
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('04_Process/Wave/Wave.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
        end
      end

      # Processing attached before a Wave file
      def testProcessingWaveBefore
        execute_Process_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ],
              :GlobalProcesses_Before => [
                {
                  :Name => 'Test',
                  :Param1 => 'TestParam1'
                }
              ]
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('04_Process/Wave/Wave.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
        end
      end

      # Processing attached after a Wave file
      def testProcessingWaveAfter
        execute_Process_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ],
              :GlobalProcesses_After => [
                {
                  :Name => 'Test',
                  :Param1 => 'TestParam1'
                }
              ]
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('04_Process/Wave/Wave.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
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
              ],
              :GlobalProcesses_Before => [
                {
                  :Name => 'Test',
                  :Param1 => 'TestParam0'
                }
              ],
              :GlobalProcesses_After => [
                {
                  :Name => 'Test',
                  :Param1 => 'TestParam2'
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

      # Assign Wave position
      def testPositionWave
        execute_Process_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav',
                  :Position => '0.1s'
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
              :Params => [ '--begin', '0.1s', '--end', '0' ],
              :UseWave => 'Empty.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          getFileFromGlob('04_Process/Wave/Wave.0.SilenceInserter.????????????????????????????????.wav')
        end
      end

      # Assign Wave position with order
      def testPositionWaveOrder
        execute_Process_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav',
                  :Position => '0.1s',
                  :Processes => [
                    {
                      :Name => 'Test',
                      :Param1 => 'TestParam1'
                    }
                  ]
                }
              ],
              :GlobalProcesses_Before => [
                {
                  :Name => 'Test',
                  :Param1 => 'TestParam0'
                }
              ],
              :GlobalProcesses_After => [
                {
                  :Name => 'Test',
                  :Param1 => 'TestParam2'
                }
              ]
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
          ],
          :FakeWSK => [
            {
              :Input => /04_Process\/Wave\/Wave\.1\.Test\.[[:xdigit:]]{32,32}\.wav/,
              :Output => /04_Process\/Wave\/Wave\.2\.SilenceInserter\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'SilenceInserter',
              :Params => [ '--begin', '0.1s', '--end', '0' ],
              :UseWave => 'Empty.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('04_Process/Wave/Wave.0.Test.????????????????????????????????.wav')
          lWave1FileName = getFileFromGlob('04_Process/Wave/Wave.1.Test.????????????????????????????????.wav')
          lWave2FileName = getFileFromGlob('04_Process/Wave/Wave.2.SilenceInserter.????????????????????????????????.wav')
          lWave3FileName = getFileFromGlob('04_Process/Wave/Wave.3.Test.????????????????????????????????.wav')
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
              :InputFileName => lWave2FileName,
              :OutputFileName => lWave3FileName,
              :Params => {
                :Param1 => 'TestParam2'
              }
            }
          ], 'Process_Test.rb'
        end
      end

    end

  end

end
