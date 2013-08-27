module MusicMasterTest

  module GenerateSourceFiles

    class Wave < ::Test::Unit::TestCase

      # Test an empty wave files list
      def testNoWaveFiles
        execute_Record_WithConf({
          :WaveFiles => {
            :FilesList => []
          }
        }) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
        end
      end

      # Test an existing wave file
      def testExistingWaveFile
        execute_Record_WithConf({
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
          assert !File.exists?('01_Source/Wave/Wave.wav')
        end
      end

      # Test generating a missing wave file
      def testGeneratingWaveFile
        execute_Record_WithConf({
          :WaveFiles => {
            :FilesList => [
              {
                :Name => 'Wave.wav'
              }
            ]
          },
        },
        :PilotingCode => Proc.new do |oStdIN, iStdOUT, iStdERR, iChildProcess|
          lWaveFileName = '01_Source/Wave/Wave.wav'
          iStdOUT.gets_until("Create Wave file #{lWaveFileName}, and press Enter when done.\n", :time_out_secs => 10)
          FileUtils::mkdir_p(File.dirname(lWaveFileName))
          FileUtils::cp("#{MusicMasterTest::getRootPath}/test/Wave/Empty.wav", lWaveFileName)
          oStdIN.write("\n")
        end) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert File.exists?('01_Source/Wave/Wave.wav')
        end
      end

      # Test generating 2 missing wave files
      def testGenerating2WaveFiles
        execute_Record_WithConf({
          :WaveFiles => {
            :FilesList => [
              {
                :Name => 'Wave1.wav'
              },
              {
                :Name => 'Wave2.wav'
              }
            ]
          },
        },
        :PilotingCode => Proc.new do |oStdIN, iStdOUT, iStdERR, iChildProcess|
          lWave1FileName = '01_Source/Wave/Wave1.wav'
          iStdOUT.gets_until("Create Wave file #{lWave1FileName}, and press Enter when done.\n", :time_out_secs => 10)
          FileUtils::mkdir_p(File.dirname(lWave1FileName))
          FileUtils::cp("#{MusicMasterTest::getRootPath}/test/Wave/Empty.wav", lWave1FileName)
          oStdIN.write("\n")
          lWave2FileName = '01_Source/Wave/Wave2.wav'
          iStdOUT.gets_until("Create Wave file #{lWave2FileName}, and press Enter when done.\n", :time_out_secs => 10)
          FileUtils::mkdir_p(File.dirname(lWave2FileName))
          FileUtils::cp("#{MusicMasterTest::getRootPath}/test/Wave/Sine1s.wav", lWave2FileName)
          oStdIN.write("\n")
        end) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert File.exists?('01_Source/Wave/Wave1.wav')
          assert File.exists?('01_Source/Wave/Wave2.wav')
        end
      end

    end

  end

end
