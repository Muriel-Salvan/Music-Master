#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  module Mix

    class SingleTrackID < ::Test::Unit::TestCase

      # No mix
      def testNoMix
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Wave.wav' => {}
                }
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert Dir.glob('05_Mix/*.wav').empty?
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Apply a process at the source track
      def testProcessSource
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Wave.wav' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam1'
                      }
                    ]
                  }
                }
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Apply a process on the mix
      def testProcessMix
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Wave.wav' => {}
                },
                :Processes => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam1'
                  }
                ]
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Processes order on 1 track
      def testProcessesOrder1Track
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Wave.wav' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam1'
                      }
                    ]
                  }
                },
                :Processes => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam2'
                  }
                ]
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.????????????????????????????????.wav')
          lWave1FileName = getFileFromGlob('05_Mix/Wave.1.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            },
            {
              :InputFileName => lWave0FileName,
              :OutputFileName => lWave1FileName,
              :Params => {
                :Param1 => 'TestParam2'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Processes are optimized between source processes and mix processes when there is just 1 track
      def testOptimizeProcessesOn1Track
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave1.wav'
                }
              ]
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Wave1.wav' => {
                    :Processes => [
                      {
                        :Name => 'VolCorrection',
                        :Factor => '1db'
                      }
                    ]
                  }
                },
                :Processes => [
                  {
                    :Name => 'VolCorrection',
                    :Factor => '2db'
                  }
                ]
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/01_Source/Wave/Wave1.wav', 'Wave1.wav' ]
          ],
          :FakeWSK => [
            {
              :Input => 'Wave1.wav',
              :Output => /05_Mix\/Wave1\.0\.VolCorrection\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Multiply',
              :Params => [ '--coeff', '3.0db' ],
              :UseWave => '05_Mix/Wave1.0.VolCorrection.3db.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          getFileFromGlob('05_Mix/Wave1.0.VolCorrection.????????????????????????????????.wav')
          assert_wave_lnk '05_Mix/Wave1.0.VolCorrection.3db', '05_Mix/Final/Final.wav'
        end
      end

      # Processes are not optimized between source processes and mix processes when there is more than 1 track
      def testDontOptimizeProcessesOn2Tracks
        execute_Mix_WithConf({
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
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Wave1.wav' => {
                    :Processes => [
                      {
                        :Name => 'VolCorrection',
                        :Factor => '1db'
                      }
                    ]
                  },
                  'Wave2.wav' => {
                    :Processes => [
                      {
                        :Name => 'VolCorrection',
                        :Factor => '2db'
                      }
                    ]
                  }
                },
                :Processes => [
                  {
                    :Name => 'VolCorrection',
                    :Factor => '3db'
                  }
                ]
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/01_Source/Wave/Wave1.wav', 'Wave1.wav' ],
            [ 'Wave/01_Source/Wave/Wave2.wav', 'Wave2.wav' ]
          ],
          :FakeWSK => [
            {
              :Input => 'Wave1.wav',
              :Output => /05_Mix\/Wave1\.0\.VolCorrection\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Multiply',
              :Params => [ '--coeff', '1db' ],
              :UseWave => '05_Mix/Wave1.0.VolCorrection.1db.wav'
            },
            {
              :Input => 'Wave2.wav',
              :Output => /05_Mix\/Wave2\.0\.VolCorrection\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Multiply',
              :Params => [ '--coeff', '2db' ],
              :UseWave => '05_Mix/Wave2.0.VolCorrection.2db.wav'
            },
            {
              :Input => /05_Mix\/Wave1\.0\.VolCorrection\.[[:xdigit:]]{32,32}\.wav/,
              :Output => /05_Mix\/Final\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', /05_Mix\/Wave2\.0\.VolCorrection\.[[:xdigit:]]{32,32}\.wav\|1/ ],
              :UseWave => '05_Mix/Wave1.1db.Wave2.2db.wav'
            },
            {
              :Input => /05_Mix\/Final\.[[:xdigit:]]{32,32}\.wav/,
              :Output => /05_Mix\/Final\.0\.VolCorrection\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Multiply',
              :Params => [ '--coeff', '3db' ],
              :UseWave => '05_Mix/Wave1.1db.Wave2.2db.3db.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          getFileFromGlob('05_Mix/Wave1.0.VolCorrection.????????????????????????????????.wav')
          getFileFromGlob('05_Mix/Wave2.0.VolCorrection.????????????????????????????????.wav')
          getFileFromGlob('05_Mix/Final.????????????????????????????????.wav')
          getFileFromGlob('05_Mix/Final.0.VolCorrection.????????????????????????????????.wav')
          assert_wave_lnk '05_Mix/Wave1.1db.Wave2.2db.3db', '05_Mix/Final/Final.wav'
        end
      end

      # Useless processes on source files
      def testUselessProcessesSourceFiles
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Wave.wav' => {
                    :Processes => [
                      {
                        :Name => 'VolCorrection',
                        :Factor => '2db'
                      },
                      {
                        :Name => 'VolCorrection',
                        :Factor => '-2db'
                      }
                    ]
                  }
                }
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert Dir.glob('05_Mix/*.wav').empty?
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Useless processes on mix
      def testUselessProcessesMix
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Final' => {
                :Tracks => {
                  'Wave.wav' => {}
                },
                :Processes => [
                  {
                    :Name => 'VolCorrection',
                    :Factor => '2db'
                  },
                  {
                    :Name => 'VolCorrection',
                    :Factor => '-2db'
                  }
                ]
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert Dir.glob('05_Mix/*.wav').empty?
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Reuse a mix
      def testReuseMix
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Mix1' => {
                :Tracks => {
                  'Wave.wav' => {}
                }
              },
              'Final' => {
                :Tracks => {
                  'Mix1' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam1'
                      }
                    ]
                  }
                }
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Empty', '05_Mix/Final/Mix1.wav'
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Reuse a mix with an alias
      def testReuseMixWithAlias
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Mix1' => {
                :Tracks => {
                  'Wave.wav' => {}
                },
                :Alias => 'First mix'
              },
              'Final' => {
                :Tracks => {
                  'First mix' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam1'
                      }
                    ]
                  }
                }
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Empty', '05_Mix/Final/Mix1.wav'
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Reuse a mix with an alias list
      def testReuseMixWithAliasList
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Mix1' => {
                :Tracks => {
                  'Wave.wav' => {}
                },
                :Alias => [ 'First mix', 'Second mix' ]
              },
              'Final' => {
                :Tracks => {
                  'Second mix' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam1'
                      }
                    ]
                  }
                }
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Empty', '05_Mix/Final/Mix1.wav'
          assert_wave_lnk 'Empty', '05_Mix/Final/Final.wav'
        end
      end

      # Reuse a mix that had a process on source files
      def testReuseMixWithSourceFilesProcessed
        lProcessID = {
          :Param1 => 'TestParam1'
        }.unique_id
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Mix1' => {
                :Tracks => {
                  'Wave.wav' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam1'
                      }
                    ]
                  }
                }
              },
              'Final' => {
                :Tracks => {
                  'Mix1' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam2'
                      }
                    ]
                  }
                }
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ],
            [ 'Wave/Noise1s.wav', "05_Mix/Wave.0.Test.#{lProcessID}.wav" ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => "05_Mix/Wave.0.Test.#{lProcessID}.wav",
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam2'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Noise1s', '05_Mix/Final/Mix1.wav'
          assert_wave_lnk 'Noise1s', '05_Mix/Final/Final.wav'
        end
      end

      # Reuse a mix that had a process on the mix
      def testReuseMixWithMixProcessed
        lProcessID = {
          :Param1 => 'TestParam1'
        }.unique_id
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave.wav'
                }
              ]
            },
            :Mix => {
              'Mix1' => {
                :Tracks => {
                  'Wave.wav' => {}
                },
                :Processes => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam1'
                  }
                ]
              },
              'Final' => {
                :Tracks => {
                  'Mix1' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam2'
                      }
                    ]
                  }
                }
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/Empty.wav', 'Wave.wav' ],
            [ 'Wave/Noise1s.wav', "05_Mix/Wave.0.Test.#{lProcessID}.wav" ]
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave.0.Test.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => "05_Mix/Wave.0.Test.#{lProcessID}.wav",
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam2'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk 'Noise1s', '05_Mix/Final/Mix1.wav'
          assert_wave_lnk 'Noise1s', '05_Mix/Final/Final.wav'
        end
      end

      # Test missing TrackID
      def testMissingTrackID
        execute_Mix_WithConf({
            :Mix => {
              'Final' => {
                :Tracks => {
                  'MissingTrackID' => {}
                }
              }
            }
        }) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 1, iExitStatus
          assert !File.exists?('05_Mix')
        end
      end

    end

  end

end
