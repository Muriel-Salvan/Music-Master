#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  module ProcessSourceFiles

    module Processes

      class ApplyVolumeFct < ::Test::Unit::TestCase

        # Normal invocation
        def testNormalUsage
          ensure_wsk_or_skip do
            execute_Process_WithConf({
                :WaveFiles => {
                  :FilesList => [
                    {
                      :Name => 'Wave.wav',
                      :Processes => [
                        {
                          :Name => 'ApplyVolumeFct',
                          :Function => {
                            :FunctionType => WSK::Functions::FCTTYPE_PIECEWISE_LINEAR,
                            :MinValue => 0,
                            :MaxValue => 1,
                            :Points => {
                              0 => 0,
                              1 => 1
                            }
                          },
                          :Begin => '0.1s',
                          :End => '0.9s',
                          :DBUnits => false
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
                  :Output => /04_Process\/Wave\/Wave\.0\.ApplyVolumeFct\.[[:xdigit:]]{32,32}\.wav/,
                  :Action => 'ApplyVolumeFct',
                  :Params => [ '--function', './Wave.fct.rb', '--begin', '0.1s', '--end', '0.9s', '--unitdb', '0' ],
                  :UseWave => 'Sine1s.wav'
                }
            ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
              assert_exitstatus 0, iExitStatus
              getFileFromGlob('04_Process/Wave/Wave.0.ApplyVolumeFct.????????????????????????????????.wav')
              assert_rb_content({
                :MinValue => 0,
                :MaxValue => 1,
                :FunctionType => WSK::Functions::FCTTYPE_PIECEWISE_LINEAR,
                :Points => [
                  [ Rational(0, 1), Rational(0, 1) ],
                  [ Rational(1, 1), Rational(1, 1) ]
                ]
              }, 'Wave.fct.rb')
            end
          end
        end

      end

    end

  end

end
