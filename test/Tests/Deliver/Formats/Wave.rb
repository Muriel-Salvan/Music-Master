module MusicMasterTest

  module Deliver

    module Formats

      class Wave < ::Test::Unit::TestCase

        # Test delivering a normal wave using SSRC
        def testSSRC
          # On this test, WSK needs to be installed
          ensure_wsk_or_skip do
            execute_Deliver_WithConf({
                :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
                :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
                :Deliver => {
                  :Formats => {
                    'Test' => {
                      :FileFormat => 'Wave',
                      :BitDepth => 24,
                      :SampleRate => 192000
                    }
                  },
                  :Deliverables => {
                    'Deliverable' => {
                      :Mix => 'Mix1',
                      :Format => 'Test'
                    }
                  }
                }
              },
              :PrepareFiles => getPreparedFiles(:Mixed_Wave1),
              :FakeSSRC => [
                {
                  :Input => 'Wave1.wav',
                  :Output => '06_Deliver/Deliverable/Track.wav',
                  :Params => [ '--bits', '24', '--profile', 'standard', '--rate', '192000', '--twopass' ],
                  :UseWave => 'Empty.wav'
                }
              ]
            ) do |iStdOUTLog, iStdERRLog, iExitStatus|
              assert_exitstatus 0, iExitStatus
              assert_wave 'Empty', '06_Deliver/Deliverable/Track.wav'
            end
          end
        end

        # Test delivering a normal wave using SSRC with dither
        def testSSRCWithDither
          execute_Deliver_WithConf({
              :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
              :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
              :Deliver => {
                :Formats => {
                  'Test' => {
                    :FileFormat => 'Wave',
                    :BitDepth => 24,
                    :SampleRate => 192000,
                    :Dither => true
                  }
                },
                :Deliverables => {
                  'Deliverable' => {
                    :Mix => 'Mix1',
                    :Format => 'Test'
                  }
                }
              }
            },
            :PrepareFiles => getPreparedFiles(:Mixed_Wave1),
            :FakeSSRC => [
              {
                :Input => 'Wave1.wav',
                :Output => '06_Deliver/Deliverable/Track.wav',
                :Params => [ '--bits', '24', '--dither', '4', '--profile', 'standard', '--rate', '192000', '--twopass' ],
                :UseWave => 'Empty.wav'
              }
            ]
          ) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            assert_wave 'Empty', '06_Deliver/Deliverable/Track.wav'
          end
        end

        # Test delivering with default values but with dither
        def testSSRCDefaultWithDither
          execute_Deliver_WithConf({
              :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
              :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
              :Deliver => {
                :Formats => {
                  'Test' => {
                    :FileFormat => 'Wave',
                    :Dither => true
                  }
                },
                :Deliverables => {
                  'Deliverable' => {
                    :Mix => 'Mix1',
                    :Format => 'Test'
                  }
                }
              }
            },
            :PrepareFiles => getPreparedFiles(:Mixed_Wave1),
            :FakeSSRC => [
              {
                :Input => 'Wave1.wav',
                :Output => '06_Deliver/Deliverable/Track.wav',
                :Params => [ '--dither', '4', '--profile', 'standard', '--twopass' ],
                :UseWave => 'Empty.wav'
              }
            ]
          ) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            assert_wave 'Empty', '06_Deliver/Deliverable/Track.wav'
          end
        end

        # Test delivering a shortcut
        def testShortcut
          execute_Deliver_WithConf({
              :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
              :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
              :Deliver => {
                :Formats => {
                  'Test' => {
                    :FileFormat => 'Wave'
                  }
                },
                :Deliverables => {
                  'Deliverable' => {
                    :Mix => 'Mix1',
                    :Format => 'Test'
                  }
                }
              }
            },
            :PrepareFiles => getPreparedFiles(:Mixed_Wave1)
          ) do |iStdOUTLog, iStdERRLog, iExitStatus|
            assert_exitstatus 0, iExitStatus
            assert_wave_lnk '01_Source/Wave/Wave1', '06_Deliver/Deliverable/Track.wav'
          end
        end

      end

    end

  end

end
