#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  module ProcessSourceFiles

    module Processes

      class Compressor < ::Test::Unit::TestCase

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
                          :Name => 'Compressor',
                          :DBUnits => false,
                          :Threshold => 0.8,
                          :Ratio => 2,
                          :AttackDuration => '0.1s',
                          :AttackDamping => '0.05s',
                          :AttackLookAhead => true,
                          :ReleaseDuration => '0.2s',
                          :ReleaseDamping => '0.1s',
                          :ReleaseLookAhead => false,
                          :MinChangeDuration => '0.15s',
                          :RMSRatio => 0.2
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
                  :Action => 'VolumeProfile',
                  :Params => [ '--function', './Wave.ProfileFct.rb', '--begin', '0', '--end', '-1', '--interval', '0.1s', '--rmsratio', '0.2' ],
                  :UseWave => 'Empty.wav',
                  :CopyFiles => { 'Functions/Sine1s.ProfileFct.rb' => 'Wave.ProfileFct.rb' }
                },
                {
                  :Input => 'Wave.wav',
                  :Output => './_Wave_RawDiffProfileDB.wav',
                  :Action => 'DrawFct',
                  :Params => [ '--function', './_Wave_RawDiffProfileDB.fct.rb', '--unitdb', '0' ],
                  :UseWave => '_Sine1s_RawDiffProfileDB.wav',
                },
                {
                  :Input => 'Wave.wav',
                  :Output => './_Wave_SmoothedDiffProfileDB.wav',
                  :Action => 'DrawFct',
                  :Params => [ '--function', './_Wave_SmoothedDiffProfileDB.fct.rb', '--unitdb', '0' ],
                  :UseWave => '_Sine1s_SmoothedDiffProfileDB.wav',
                },
                {
                  :Input => 'Wave.wav',
                  :Output => /04_Process\/Wave\/Wave\.0\.Compressor\.[[:xdigit:]]{32,32}\.wav/,
                  :Action => 'ApplyVolumeFct',
                  :Params => [ '--function', './Wave.VolumeFct.rb', '--begin', '0', '--end', '-1', '--unitdb', '0' ],
                  :UseWave => 'Empty.wav',
                }
            ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
              assert_exitstatus 0, iExitStatus
              getFileFromGlob('04_Process/Wave/Wave.0.Compressor.????????????????????????????????.wav')
              assert_rb_content({
                :FunctionType => WSK::Functions::FCTTYPE_PIECEWISE_LINEAR,
                :Points => [
                  [ 0.0, 1.0 ],
                  [ 44099.0, 1.0]
                ]
              }, '_Wave_RawDiffProfileDB.fct.rb')
              assert_rb_content({
                :FunctionType => WSK::Functions::FCTTYPE_PIECEWISE_LINEAR,
                :Points => [
                  [ 0.0, 1.0 ],
                  [ 44099.0, 1.0]
                ]
              }, '_Wave_SmoothedDiffProfileDB.fct.rb')
              assert_rb_content({
                :FunctionType => WSK::Functions::FCTTYPE_PIECEWISE_LINEAR,
                :Points => [
                  [ Rational(0, 1), Rational(1, 1) ],
                  [ Rational(44099, 1), Rational(1, 1) ]
                ]
              }, 'Wave.VolumeFct.rb')
            end
          end
        end

        # TODO: Add more tests for the Compressor

      end

    end

  end

end
