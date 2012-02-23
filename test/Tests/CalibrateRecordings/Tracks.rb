#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  module CalibrateRecordings

    class Tracks < ::Test::Unit::TestCase

      # Do not calibrate a track not needing it
      def testSingleTrackWithoutCalibration
        execute_Calibrate_WithConf({
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
          assert !File.exists?('03_Calibrate/Record/Env1.1.Calibrated.wav')
        end
      end

      # Calibrate a single track that needs calibration
      def testSingleTrack
        execute_Calibrate_WithConf({
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
          }
        },
        :PrepareFiles => getPreparedFiles(:Recorded_Env1_1_CalibEnv2, :Cleaned_Env1_1_CalibEnv2),
        :FakeWSK => [
          {
            :Input => '02_Clean/Record/Calibration.Env1.Env2.04.NoiseGate.wav',
            :Output => 'PrepareMixTemp/Dummy.wav',
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Calibration.Env1.Env2.04.NoiseGate.analyze' => 'analyze.result' }
          },
          {
            :Input => '02_Clean/Record/Calibration.Env2.Env1.04.NoiseGate.wav',
            :Output => 'PrepareMixTemp/Dummy.wav',
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Calibration.Env2.Env1.04.NoiseGate.analyze' => 'analyze.result' }
          },
          {
            :Input => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
            :Output => '03_Calibrate/Record/Env1.1.Calibrated.wav',
            :Action => 'Multiply',
            :Params => [ '--coeff', '11707/16496' ],
            :UseWave => '03_Calibrate/Record/Env1.1.Calibrated.wav'
          }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert File.exists?('Analyze/Record/Calibration.Env1.Env2.04.NoiseGate.analyze')
          assert File.exists?('Analyze/Record/Calibration.Env2.Env1.04.NoiseGate.analyze')
          assert File.exists?('03_Calibrate/Record/Env1.1.Calibrated.wav')
        end
      end

      # Calibrate a single track that does not need calibration
      def testSingleTrackWithUselessCalibration
        execute_Calibrate_WithConf({
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
          }
        },
        :PrepareFiles => getPreparedFiles(:Recorded_Env1_1_CalibEnv4, :Cleaned_Env1_1_CalibEnv4),
        :FakeWSK => [
          {
            :Input => '02_Clean/Record/Calibration.Env1.Env4.04.NoiseGate.wav',
            :Output => 'PrepareMixTemp/Dummy.wav',
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Calibration.Env1.Env4.04.NoiseGate.analyze' => 'analyze.result' }
          },
          {
            :Input => '02_Clean/Record/Calibration.Env4.Env1.04.NoiseGate.wav',
            :Output => 'PrepareMixTemp/Dummy.wav',
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Calibration.Env4.Env1.04.NoiseGate.analyze' => 'analyze.result' }
          }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert File.exists?('Analyze/Record/Calibration.Env1.Env4.04.NoiseGate.analyze')
          assert File.exists?('Analyze/Record/Calibration.Env4.Env1.04.NoiseGate.analyze')
          assert !File.exists?('03_Calibrate/Record/Env1.1.Calibrated.wav')
        end
      end

    end

  end

end
