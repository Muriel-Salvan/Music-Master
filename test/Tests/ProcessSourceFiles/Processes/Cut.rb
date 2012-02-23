#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  module ProcessSourceFiles

    module Processes

      class Cut < ::Test::Unit::TestCase

        # Normal invocation
        def testNormalUsage
          execute_Process_WithConf({
              :WaveFiles => {
                :FilesList => [
                  {
                    :Name => 'Wave.wav',
                    :Processes => [
                      {
                        :Name => 'Cut',
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
                :Output => /04_Process\/Wave\/Wave\.0\.Cut\.[[:xdigit:]]{32,32}\.wav/,
                :Action => 'Cut',
                :Params => [ '--begin', '0.1s', '--end', '0.9s' ],
                :UseWave => 'Empty.wav'
              }
          ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            getFileFromGlob('04_Process/Wave/Wave.0.Cut.????????????????????????????????.wav')
          end
        end

      end

    end

  end

end
