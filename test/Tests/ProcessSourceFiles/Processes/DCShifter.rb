#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  module ProcessSourceFiles

    module Processes

      class DCShifter < ::Test::Unit::TestCase

        # Normal invocation
        def testNormalUsage
          execute_Process_WithConf({
              :WaveFiles => {
                :FilesList => [
                  {
                    :Name => 'Wave.wav',
                    :Processes => [
                      {
                        :Name => 'DCShifter',
                        :Offset => 1
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
                :Output => /04_Process\/Wave\/Wave\.0\.DCShifter\.[[:xdigit:]]{32,32}\.wav/,
                :Action => 'DCShifter',
                :Params => [ '--offset', '1' ],
                :UseWave => 'Empty.wav'
              }
          ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            getFileFromGlob('04_Process/Wave/Wave.0.DCShifter.????????????????????????????????.wav')
          end
        end

        # Process optimization: DCShifter addition
        def testOptimization_Add
          execute_Process_WithConf({
              :WaveFiles => {
                :FilesList => [
                  {
                    :Name => 'Wave.wav',
                    :Processes => [
                      {
                        :Name => 'DCShifter',
                        :Offset => 5
                      },
                      {
                        :Name => 'DCShifter',
                        :Offset => 7
                      },
                      {
                        :Name => 'DCShifter',
                        :Offset => 12
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
                :Output => /04_Process\/Wave\/Wave\.0\.DCShifter\.[[:xdigit:]]{32,32}\.wav/,
                :Action => 'DCShifter',
                :Params => [ '--offset', '24' ],
                :UseWave => 'Empty.wav'
              }
          ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            getFileFromGlob('04_Process/Wave/Wave.0.DCShifter.????????????????????????????????.wav')
            assert Dir.glob('04_Process/Wave/Wave.1.????????????????????????????????.wav').empty?
          end
        end

        # Process optimization: DCShifter cancellation
        def testOptimization_Cancel
          execute_Process_WithConf({
              :WaveFiles => {
                :FilesList => [
                  {
                    :Name => 'Wave.wav',
                    :Processes => [
                      {
                        :Name => 'DCShifter',
                        :Offset => 5
                      },
                      {
                        :Name => 'DCShifter',
                        :Offset => 7
                      },
                      {
                        :Name => 'DCShifter',
                        :Offset => -12
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
            assert !File.exists?('04_Process/Wave')
          end
        end

      end

    end

  end

end
