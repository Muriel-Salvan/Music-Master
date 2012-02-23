#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  module ProcessSourceFiles

    module Processes

      class VolCorrection < ::Test::Unit::TestCase

        # Normal invocation
        def testNormalUsage
          execute_Process_WithConf({
              :WaveFiles => {
                :FilesList => [
                  {
                    :Name => 'Wave.wav',
                    :Processes => [
                      {
                        :Name => 'VolCorrection',
                        :Factor => '1db'
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
                :Params => [ '--coeff', '1db' ],
                :UseWave => 'Empty.wav'
              }
          ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            getFileFromGlob('04_Process/Wave/Wave.0.VolCorrection.????????????????????????????????.wav')
          end
        end

        # Process optimization: VolCorrection addition
        def testOptimization_Add
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
                        :Name => 'VolCorrection',
                        :Factor => '3db'
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
                :Params => [ '--coeff', '6.0db' ],
                :UseWave => 'Empty.wav'
              }
          ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            getFileFromGlob('04_Process/Wave/Wave.0.VolCorrection.????????????????????????????????.wav')
            assert Dir.glob('04_Process/Wave/Wave.1.????????????????????????????????.wav').empty?
          end
        end

        # Process optimization: VolCorrection cancellation
        def testOptimization_Cancel
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
                        :Name => 'VolCorrection',
                        :Factor => '-3db'
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
