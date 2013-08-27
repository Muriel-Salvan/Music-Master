module MusicMasterTest

  module CleanRecordings

    class Tracks < ::Test::Unit::TestCase

      # Clean a single track needing DC offset
      def testSingleTrackWithDCOffset
        execute_Clean_WithConf({
          :Recordings => {
            :Tracks => {
              [1] => {
                :Env => :Env1
              }
            }
          }
        },
        :PrepareFiles => getPreparedFiles(:Recorded_Env1_1),
        :FakeWSK => [
          {
            :Input => '01_Source/Record/Env1.1.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env1.1.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env1.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'FFT',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'FFT/Env1.Silence.fftprofile' => 'fft.result' }
          },
          {
            :Input => '01_Source/Record/Env1.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env1.Silence.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env1.1.wav',
            :Output => '02_Clean/Record/Env1.1.01.SilenceRemover.wav',
            :Action => 'SilenceRemover',
            :Params => [ '--silencethreshold', '-3604,3607', '--attack', '0', '--release', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.1.01.SilenceRemover.wav'
          },
          {
            :Input => '02_Clean/Record/Env1.1.01.SilenceRemover.wav',
            :Output => '02_Clean/Record/Env1.1.03.DCShifter.wav',
            :Action => 'DCShifter',
            :Params => [ '--offset', '2' ],
            :UseWave => '02_Clean/Record/Env1.1.03.DCShifter.wav'
          },
          {
            :Input => '02_Clean/Record/Env1.1.03.DCShifter.wav',
            :Output => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
            :Action => 'NoiseGate',
            :Params => [ '--silencethreshold', '-3602,3609', '--attack', '0.1s', '--release', '0.1s', '--silencemin', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.1.04.NoiseGate.wav'
          }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert File.exists?('Analyze/Record/Env1.1.analyze')
          assert File.exists?('Analyze/Record/Env1.Silence.analyze')
          assert File.exists?('Analyze/Record/Env1.Silence.fftprofile')
          assert File.exists?('02_Clean/Record/Env1.1.01.SilenceRemover.wav')
          assert !File.exists?('02_Clean/Record/Env1.1.02.Cut.0.01s_0.16s.wav')
          assert File.exists?('02_Clean/Record/Env1.1.03.DCShifter.wav')
          assert File.exists?('02_Clean/Record/Env1.1.04.NoiseGate.wav')
        end
      end

      # Clean a single track without DC offset
      def testSingleTrackWithoutDCOffset
        execute_Clean_WithConf({
          :Recordings => {
            :Tracks => {
              [2] => {
                :Env => :Env1
              }
            }
          }
        },
        :PrepareFiles => getPreparedFiles(:Recorded_Env1_2),
        :FakeWSK => [
          {
            :Input => '01_Source/Record/Env1.2.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env1.2.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env1.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'FFT',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'FFT/Env1.Silence.fftprofile' => 'fft.result' }
          },
          {
            :Input => '01_Source/Record/Env1.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env1.Silence.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env1.2.wav',
            :Output => '02_Clean/Record/Env1.2.01.SilenceRemover.wav',
            :Action => 'SilenceRemover',
            :Params => [ '--silencethreshold', '-3602,3609', '--attack', '0', '--release', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.2.01.SilenceRemover.wav'
          },
          {
            :Input => '02_Clean/Record/Env1.2.01.SilenceRemover.wav',
            :Output => '02_Clean/Record/Env1.2.04.NoiseGate.wav',
            :Action => 'NoiseGate',
            :Params => [ '--silencethreshold', '-3602,3609', '--attack', '0.1s', '--release', '0.1s', '--silencemin', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.2.04.NoiseGate.wav'
          }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert File.exists?('Analyze/Record/Env1.2.analyze')
          assert File.exists?('Analyze/Record/Env1.Silence.analyze')
          assert File.exists?('Analyze/Record/Env1.Silence.fftprofile')
          assert File.exists?('02_Clean/Record/Env1.2.01.SilenceRemover.wav')
          assert !File.exists?('02_Clean/Record/Env1.2.02.Cut.0.01s_0.16s.wav')
          assert !File.exists?('02_Clean/Record/Env1.2.03.DCShifter.wav')
          assert File.exists?('02_Clean/Record/Env1.2.04.NoiseGate.wav')
        end
      end

      # Clean 2 tracks
      def test2Tracks
        execute_Clean_WithConf({
          :Recordings => {
            :Tracks => {
              [1] => {
                :Env => :Env1
              },
              [2] => {
                :Env => :Env1
              }
            }
          }
        },
        :PrepareFiles => getPreparedFiles(:Recorded_Env1_1, :Recorded_Env1_2),
        :FakeWSK => [
          # Clean Track 1
          {
            :Input => '01_Source/Record/Env1.1.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env1.1.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env1.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'FFT',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'FFT/Env1.Silence.fftprofile' => 'fft.result' }
          },
          {
            :Input => '01_Source/Record/Env1.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env1.Silence.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env1.1.wav',
            :Output => '02_Clean/Record/Env1.1.01.SilenceRemover.wav',
            :Action => 'SilenceRemover',
            :Params => [ '--silencethreshold', '-3604,3607', '--attack', '0', '--release', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.1.01.SilenceRemover.wav'
          },
          {
            :Input => '02_Clean/Record/Env1.1.01.SilenceRemover.wav',
            :Output => '02_Clean/Record/Env1.1.03.DCShifter.wav',
            :Action => 'DCShifter',
            :Params => [ '--offset', '2' ],
            :UseWave => '02_Clean/Record/Env1.1.03.DCShifter.wav'
          },
          {
            :Input => '02_Clean/Record/Env1.1.03.DCShifter.wav',
            :Output => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
            :Action => 'NoiseGate',
            :Params => [ '--silencethreshold', '-3602,3609', '--attack', '0.1s', '--release', '0.1s', '--silencemin', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.1.04.NoiseGate.wav'
          },
          # Clean Track 2
          {
            :Input => '01_Source/Record/Env1.2.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env1.2.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env1.2.wav',
            :Output => '02_Clean/Record/Env1.2.01.SilenceRemover.wav',
            :Action => 'SilenceRemover',
            :Params => [ '--silencethreshold', '-3602,3609', '--attack', '0', '--release', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.2.01.SilenceRemover.wav'
          },
          {
            :Input => '02_Clean/Record/Env1.2.01.SilenceRemover.wav',
            :Output => '02_Clean/Record/Env1.2.04.NoiseGate.wav',
            :Action => 'NoiseGate',
            :Params => [ '--silencethreshold', '-3602,3609', '--attack', '0.1s', '--release', '0.1s', '--silencemin', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.2.04.NoiseGate.wav'
          },
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert File.exists?('Analyze/Record/Env1.1.analyze')
          assert File.exists?('Analyze/Record/Env1.Silence.analyze')
          assert File.exists?('Analyze/Record/Env1.Silence.fftprofile')
          assert File.exists?('02_Clean/Record/Env1.1.01.SilenceRemover.wav')
          assert !File.exists?('02_Clean/Record/Env1.1.02.Cut.0.01s_0.16s.wav')
          assert File.exists?('02_Clean/Record/Env1.1.03.DCShifter.wav')
          assert File.exists?('02_Clean/Record/Env1.1.04.NoiseGate.wav')
          assert File.exists?('Analyze/Record/Env1.2.analyze')
          assert File.exists?('02_Clean/Record/Env1.2.01.SilenceRemover.wav')
          assert !File.exists?('02_Clean/Record/Env1.2.02.Cut.0.01s_0.16s.wav')
          assert !File.exists?('02_Clean/Record/Env1.2.03.DCShifter.wav')
          assert File.exists?('02_Clean/Record/Env1.2.04.NoiseGate.wav')
        end
      end

      # Clean a single track needing DC offset and calibration
      def testSingleTrackWithDCOffsetAndCalibration
        execute_Clean_WithConf({
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
        :PrepareFiles => getPreparedFiles(:Recorded_Env1_1_CalibEnv2),
        :FakeWSK => [
          # Clean Calibration Env1 Env2
          {
            :Input => '01_Source/Record/Calibration.Env1.Env2.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Calibration.Env1.Env2.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env1.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'FFT',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'FFT/Env1.Silence.fftprofile' => 'fft.result' }
          },
          {
            :Input => '01_Source/Record/Env1.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env1.Silence.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Calibration.Env1.Env2.wav',
            :Output => '02_Clean/Record/Calibration.Env1.Env2.01.SilenceRemover.wav',
            :Action => 'SilenceRemover',
            :Params => [ '--silencethreshold', '-3604,3607', '--attack', '0', '--release', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Calibration.Env1.Env2.01.SilenceRemover.wav'
          },
          {
            :Input => '02_Clean/Record/Calibration.Env1.Env2.01.SilenceRemover.wav',
            :Output => '02_Clean/Record/Calibration.Env1.Env2.02.Cut.0.01s_0.16s.wav',
            :Action => 'Cut',
            :Params => [ '--begin', '0.01s', '--end', '0.16s' ],
            :UseWave => '02_Clean/Record/Calibration.Env1.Env2.02.Cut.0.01s_0.16s.wav'
          },
          {
            :Input => '02_Clean/Record/Calibration.Env1.Env2.02.Cut.0.01s_0.16s.wav',
            :Output => '02_Clean/Record/Calibration.Env1.Env2.03.DCShifter.wav',
            :Action => 'DCShifter',
            :Params => [ '--offset', '2' ],
            :UseWave => '02_Clean/Record/Calibration.Env1.Env2.03.DCShifter.wav'
          },
          {
            :Input => '02_Clean/Record/Calibration.Env1.Env2.03.DCShifter.wav',
            :Output => '02_Clean/Record/Calibration.Env1.Env2.04.NoiseGate.wav',
            :Action => 'NoiseGate',
            :Params => [ '--silencethreshold', '-3602,3609', '--attack', '0.1s', '--release', '0.1s', '--silencemin', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Calibration.Env1.Env2.04.NoiseGate.wav'
          },
          # Clean Calibration Env2 Env1
          {
            :Input => '01_Source/Record/Calibration.Env2.Env1.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Calibration.Env2.Env1.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env2.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'FFT',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'FFT/Env2.Silence.fftprofile' => 'fft.result' }
          },
          {
            :Input => '01_Source/Record/Env2.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env2.Silence.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Calibration.Env2.Env1.wav',
            :Output => '02_Clean/Record/Calibration.Env2.Env1.01.SilenceRemover.wav',
            :Action => 'SilenceRemover',
            :Params => [ '--silencethreshold', '-7601,7577', '--attack', '0', '--release', '1s', '--noisefft', 'Analyze/Record/Env2.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Calibration.Env2.Env1.01.SilenceRemover.wav'
          },
          {
            :Input => '02_Clean/Record/Calibration.Env2.Env1.01.SilenceRemover.wav',
            :Output => '02_Clean/Record/Calibration.Env2.Env1.02.Cut.0.01s_0.16s.wav',
            :Action => 'Cut',
            :Params => [ '--begin', '0.01s', '--end', '0.16s' ],
            :UseWave => '02_Clean/Record/Calibration.Env2.Env1.02.Cut.0.01s_0.16s.wav'
          },
          {
            :Input => '02_Clean/Record/Calibration.Env2.Env1.02.Cut.0.01s_0.16s.wav',
            :Output => '02_Clean/Record/Calibration.Env2.Env1.03.DCShifter.wav',
            :Action => 'DCShifter',
            :Params => [ '--offset', '94' ],
            :UseWave => '02_Clean/Record/Calibration.Env2.Env1.03.DCShifter.wav'
          },
          {
            :Input => '02_Clean/Record/Calibration.Env2.Env1.03.DCShifter.wav',
            :Output => '02_Clean/Record/Calibration.Env2.Env1.04.NoiseGate.wav',
            :Action => 'NoiseGate',
            :Params => [ '--silencethreshold', '-7507,7671', '--attack', '0.1s', '--release', '0.1s', '--silencemin', '1s', '--noisefft', 'Analyze/Record/Env2.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Calibration.Env2.Env1.04.NoiseGate.wav'
          },
          # Clean Track 1
          {
            :Input => '01_Source/Record/Env1.1.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env1.1.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env1.1.wav',
            :Output => '02_Clean/Record/Env1.1.01.SilenceRemover.wav',
            :Action => 'SilenceRemover',
            :Params => [ '--silencethreshold', '-3604,3607', '--attack', '0', '--release', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.1.01.SilenceRemover.wav'
          },
          {
            :Input => '02_Clean/Record/Env1.1.01.SilenceRemover.wav',
            :Output => '02_Clean/Record/Env1.1.03.DCShifter.wav',
            :Action => 'DCShifter',
            :Params => [ '--offset', '2' ],
            :UseWave => '02_Clean/Record/Env1.1.03.DCShifter.wav'
          },
          {
            :Input => '02_Clean/Record/Env1.1.03.DCShifter.wav',
            :Output => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
            :Action => 'NoiseGate',
            :Params => [ '--silencethreshold', '-3602,3609', '--attack', '0.1s', '--release', '0.1s', '--silencemin', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.1.04.NoiseGate.wav'
          }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert File.exists?('Analyze/Record/Env1.1.analyze')
          assert File.exists?('Analyze/Record/Env1.Silence.analyze')
          assert File.exists?('Analyze/Record/Env1.Silence.fftprofile')
          assert File.exists?('Analyze/Record/Env2.Silence.analyze')
          assert File.exists?('Analyze/Record/Env2.Silence.fftprofile')
          assert File.exists?('Analyze/Record/Calibration.Env1.Env2.analyze')
          assert File.exists?('Analyze/Record/Calibration.Env2.Env1.analyze')
          assert File.exists?('02_Clean/Record/Calibration.Env1.Env2.01.SilenceRemover.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env1.Env2.02.Cut.0.01s_0.16s.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env1.Env2.03.DCShifter.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env1.Env2.04.NoiseGate.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env2.Env1.01.SilenceRemover.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env2.Env1.02.Cut.0.01s_0.16s.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env2.Env1.03.DCShifter.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env2.Env1.04.NoiseGate.wav')
          assert File.exists?('02_Clean/Record/Env1.1.01.SilenceRemover.wav')
          assert !File.exists?('02_Clean/Record/Env1.1.02.Cut.0.01s_0.16s.wav')
          assert File.exists?('02_Clean/Record/Env1.1.03.DCShifter.wav')
          assert File.exists?('02_Clean/Record/Env1.1.04.NoiseGate.wav')
        end
      end

      # Clean a single track needing DC offset and calibration, but the calibration file does not have any DC offset
      def testSingleTrackWithCalibrationWithoutDCOffset
        execute_Clean_WithConf({
          :Recordings => {
            :EnvCalibration => {
              [ :Env1, :Env3 ] => {
                :CompareCuts => ['0.01s', '0.16s']
              }
            },
            :Tracks => {
              [1] => {
                :Env => :Env1,
                :CalibrateWithEnv => :Env3
              }
            }
          }
        },
        :PrepareFiles => getPreparedFiles(:Recorded_Env1_1_CalibEnv3),
        :FakeWSK => [
          # Clean Calibration Env1 Env3
          {
            :Input => '01_Source/Record/Calibration.Env1.Env3.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Calibration.Env1.Env3.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env1.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'FFT',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'FFT/Env1.Silence.fftprofile' => 'fft.result' }
          },
          {
            :Input => '01_Source/Record/Env1.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env1.Silence.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Calibration.Env1.Env3.wav',
            :Output => '02_Clean/Record/Calibration.Env1.Env3.01.SilenceRemover.wav',
            :Action => 'SilenceRemover',
            :Params => [ '--silencethreshold', '-3602,3609', '--attack', '0', '--release', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Calibration.Env1.Env3.01.SilenceRemover.wav'
          },
          {
            :Input => '02_Clean/Record/Calibration.Env1.Env3.01.SilenceRemover.wav',
            :Output => '02_Clean/Record/Calibration.Env1.Env3.02.Cut.0.01s_0.16s.wav',
            :Action => 'Cut',
            :Params => [ '--begin', '0.01s', '--end', '0.16s' ],
            :UseWave => '02_Clean/Record/Calibration.Env1.Env3.02.Cut.0.01s_0.16s.wav'
          },
          {
            :Input => '02_Clean/Record/Calibration.Env1.Env3.02.Cut.0.01s_0.16s.wav',
            :Output => '02_Clean/Record/Calibration.Env1.Env3.04.NoiseGate.wav',
            :Action => 'NoiseGate',
            :Params => [ '--silencethreshold', '-3602,3609', '--attack', '0.1s', '--release', '0.1s', '--silencemin', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Calibration.Env1.Env3.04.NoiseGate.wav'
          },
          # Clean Calibration Env3 Env1
          {
            :Input => '01_Source/Record/Calibration.Env3.Env1.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Calibration.Env3.Env1.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env3.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'FFT',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'FFT/Env3.Silence.fftprofile' => 'fft.result' }
          },
          {
            :Input => '01_Source/Record/Env3.Silence.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env3.Silence.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Calibration.Env3.Env1.wav',
            :Output => '02_Clean/Record/Calibration.Env3.Env1.01.SilenceRemover.wav',
            :Action => 'SilenceRemover',
            :Params => [ '--silencethreshold', '-7601,7577', '--attack', '0', '--release', '1s', '--noisefft', 'Analyze/Record/Env3.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Calibration.Env3.Env1.01.SilenceRemover.wav'
          },
          {
            :Input => '02_Clean/Record/Calibration.Env3.Env1.01.SilenceRemover.wav',
            :Output => '02_Clean/Record/Calibration.Env3.Env1.02.Cut.0.01s_0.16s.wav',
            :Action => 'Cut',
            :Params => [ '--begin', '0.01s', '--end', '0.16s' ],
            :UseWave => '02_Clean/Record/Calibration.Env3.Env1.02.Cut.0.01s_0.16s.wav'
          },
          {
            :Input => '02_Clean/Record/Calibration.Env3.Env1.02.Cut.0.01s_0.16s.wav',
            :Output => '02_Clean/Record/Calibration.Env3.Env1.03.DCShifter.wav',
            :Action => 'DCShifter',
            :Params => [ '--offset', '94' ],
            :UseWave => '02_Clean/Record/Calibration.Env3.Env1.03.DCShifter.wav'
          },
          {
            :Input => '02_Clean/Record/Calibration.Env3.Env1.03.DCShifter.wav',
            :Output => '02_Clean/Record/Calibration.Env3.Env1.04.NoiseGate.wav',
            :Action => 'NoiseGate',
            :Params => [ '--silencethreshold', '-7507,7671', '--attack', '0.1s', '--release', '0.1s', '--silencemin', '1s', '--noisefft', 'Analyze/Record/Env3.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Calibration.Env3.Env1.04.NoiseGate.wav'
          },
          # Clean Track 1
          {
            :Input => '01_Source/Record/Env1.1.wav',
            :Output => /^.*\/Dummy\.wav$/,
            :Action => 'Analyze',
            :UseWave => 'Empty.wav',
            :CopyFiles => { 'Analysis/Env1.1.analyze' => 'analyze.result' }
          },
          {
            :Input => '01_Source/Record/Env1.1.wav',
            :Output => '02_Clean/Record/Env1.1.01.SilenceRemover.wav',
            :Action => 'SilenceRemover',
            :Params => [ '--silencethreshold', '-3604,3607', '--attack', '0', '--release', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.1.01.SilenceRemover.wav'
          },
          {
            :Input => '02_Clean/Record/Env1.1.01.SilenceRemover.wav',
            :Output => '02_Clean/Record/Env1.1.03.DCShifter.wav',
            :Action => 'DCShifter',
            :Params => [ '--offset', '2' ],
            :UseWave => '02_Clean/Record/Env1.1.03.DCShifter.wav'
          },
          {
            :Input => '02_Clean/Record/Env1.1.03.DCShifter.wav',
            :Output => '02_Clean/Record/Env1.1.04.NoiseGate.wav',
            :Action => 'NoiseGate',
            :Params => [ '--silencethreshold', '-3602,3609', '--attack', '0.1s', '--release', '0.1s', '--silencemin', '1s', '--noisefft', 'Analyze/Record/Env1.Silence.fftprofile' ],
            :UseWave => '02_Clean/Record/Env1.1.04.NoiseGate.wav'
          }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert File.exists?('Analyze/Record/Env1.1.analyze')
          assert File.exists?('Analyze/Record/Env1.Silence.analyze')
          assert File.exists?('Analyze/Record/Env1.Silence.fftprofile')
          assert File.exists?('Analyze/Record/Env3.Silence.analyze')
          assert File.exists?('Analyze/Record/Env3.Silence.fftprofile')
          assert File.exists?('Analyze/Record/Calibration.Env1.Env3.analyze')
          assert File.exists?('Analyze/Record/Calibration.Env3.Env1.analyze')
          assert File.exists?('02_Clean/Record/Calibration.Env1.Env3.01.SilenceRemover.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env1.Env3.02.Cut.0.01s_0.16s.wav')
          assert !File.exists?('02_Clean/Record/Calibration.Env1.Env3.03.DCShifter.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env1.Env3.04.NoiseGate.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env3.Env1.01.SilenceRemover.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env3.Env1.02.Cut.0.01s_0.16s.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env3.Env1.03.DCShifter.wav')
          assert File.exists?('02_Clean/Record/Calibration.Env3.Env1.04.NoiseGate.wav')
          assert File.exists?('02_Clean/Record/Env1.1.01.SilenceRemover.wav')
          assert !File.exists?('02_Clean/Record/Env1.1.02.Cut.0.01s_0.16s.wav')
          assert File.exists?('02_Clean/Record/Env1.1.03.DCShifter.wav')
          assert File.exists?('02_Clean/Record/Env1.1.04.NoiseGate.wav')
        end
      end

    end

  end

end
