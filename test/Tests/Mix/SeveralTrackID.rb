#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  module Mix

    class SeveralTrackID < ::Test::Unit::TestCase

      # No process
      def testNoProcess
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
                  'Wave1.wav' => {},
                  'Wave2.wav' => {}
                }
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
              :Output => /05_Mix\/Final\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', 'Wave2.wav|1' ],
              :UseWave => '05_Mix/Wave1.Wave2.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          getFileFromGlob('05_Mix/Final.????????????????????????????????.wav')
          assert_wave_lnk '05_Mix/Wave1.Wave2', '05_Mix/Final/Final.wav'
        end
      end

      # Respect processing order
      def testProcessOrder
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
                        :Name => 'Test',
                        :Param1 => 'TestParam1'
                      }
                    ]
                  },
                  'Wave2.wav' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam2'
                      }
                    ]
                  }
                },
                :Processes => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam3'
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
              :Input => /05_Mix\/Wave1\.0\.Test\.[[:xdigit:]]{32,32}\.wav/,
              :Output => /05_Mix\/Final\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', /05_Mix\/Wave2\.0\.Test\.[[:xdigit:]]{32,32}\.wav\|1/ ],
              :UseWave => '05_Mix/Wave1.Wave2.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave0FileName = getFileFromGlob('05_Mix/Wave1.0.Test.????????????????????????????????.wav')
          lWave1FileName = getFileFromGlob('05_Mix/Wave2.0.Test.????????????????????????????????.wav')
          lWave2FileName = getFileFromGlob('05_Mix/Final.????????????????????????????????.wav')
          lWave3FileName = getFileFromGlob('05_Mix/Final.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave1.wav',
              :OutputFileName => lWave0FileName,
              :Params => {
                :Param1 => 'TestParam1'
              }
            },
            {
              :InputFileName => 'Wave2.wav',
              :OutputFileName => lWave1FileName,
              :Params => {
                :Param1 => 'TestParam2'
              }
            },
            {
              :InputFileName => lWave2FileName,
              :OutputFileName => lWave3FileName,
              :Params => {
                :Param1 => 'TestParam3'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk '05_Mix/Wave1.Wave2', '05_Mix/Final/Final.wav'
        end
      end

      # Respect processing order with a tree
      # Here is the mix tree:
      # Final
      # +-Mix1
      # | +-Wave1
      # | +-Wave2
      # +-Mix2
      #   +-Wave3
      #   +-Wave4
      def testProcessOrderTree
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave1.wav'
                },
                {
                  :Name => 'Wave2.wav'
                },
                {
                  :Name => 'Wave3.wav'
                },
                {
                  :Name => 'Wave4.wav'
                }
              ]
            },
            :Mix => {
              'Mix1' => {
                :Tracks => {
                  'Wave1.wav' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam_Wave1'
                      }
                    ]
                  },
                  'Wave2.wav' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam_Wave2'
                      }
                    ]
                  }
                },
                :Processes => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam_Mix1'
                  }
                ]
              },
              'Mix2' => {
                :Tracks => {
                  'Wave3.wav' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam_Wave3'
                      }
                    ]
                  },
                  'Wave4.wav' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam_Wave4'
                      }
                    ]
                  }
                },
                :Processes => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam_Mix2'
                  }
                ]
              },
              'Final' => {
                :Tracks => {
                  'Mix1' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam_Mix1_2'
                      }
                    ]
                  },
                  'Mix2' => {
                    :Processes => [
                      {
                        :Name => 'Test',
                        :Param1 => 'TestParam_Mix2_2'
                      }
                    ]
                  }
                },
                :Processes => [
                  {
                    :Name => 'Test',
                    :Param1 => 'TestParam_Final'
                  }
                ]
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/01_Source/Wave/Wave1.wav', 'Wave1.wav' ],
            [ 'Wave/01_Source/Wave/Wave2.wav', 'Wave2.wav' ],
            [ 'Wave/01_Source/Wave/Wave3.wav', 'Wave3.wav' ],
            [ 'Wave/01_Source/Wave/Wave4.wav', 'Wave4.wav' ]
          ],
          :FakeWSK => [
            {
              :Input => /05_Mix\/Wave1\.0\.Test\.[[:xdigit:]]{32,32}\.wav/,
              :Output => /05_Mix\/Mix1\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', /05_Mix\/Wave2\.0\.Test\.[[:xdigit:]]{32,32}\.wav\|1/ ],
              :UseWave => '05_Mix/Wave1.Wave2.wav'
            },
            {
              :Input => /05_Mix\/Wave3\.0\.Test\.[[:xdigit:]]{32,32}\.wav/,
              :Output => /05_Mix\/Mix2\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', /05_Mix\/Wave4\.0\.Test\.[[:xdigit:]]{32,32}\.wav\|1/ ],
              :UseWave => '05_Mix/Wave3.Wave4.wav'
            },
            {
              :Input => /05_Mix\/Mix1\.0\.Test\.0\.Test\.[[:xdigit:]]{32,32}\.wav/,
              :Output => /05_Mix\/Final\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', /05_Mix\/Mix2\.0\.Test\.0\.Test\.[[:xdigit:]]{32,32}\.wav\|1/ ],
              :UseWave => '05_Mix/Wave1.Wave2.Wave3.Wave4.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          lWave1ProcessedFileName = getFileFromGlob('05_Mix/Wave1.0.Test.????????????????????????????????.wav')
          lWave2ProcessedFileName = getFileFromGlob('05_Mix/Wave2.0.Test.????????????????????????????????.wav')
          lMix1FileName = getFileFromGlob('05_Mix/Mix1.????????????????????????????????.wav')
          lMix1MixFileName = getFileFromGlob('05_Mix/Mix1.0.Test.????????????????????????????????.wav')
          lWave3ProcessedFileName = getFileFromGlob('05_Mix/Wave3.0.Test.????????????????????????????????.wav')
          lWave4ProcessedFileName = getFileFromGlob('05_Mix/Wave4.0.Test.????????????????????????????????.wav')
          lMix2FileName = getFileFromGlob('05_Mix/Mix2.????????????????????????????????.wav')
          lMix2MixFileName = getFileFromGlob('05_Mix/Mix2.0.Test.????????????????????????????????.wav')
          lMix1ProcessedFileName = getFileFromGlob('05_Mix/Mix1.0.Test.0.Test.????????????????????????????????.wav')
          lMix2ProcessedFileName = getFileFromGlob('05_Mix/Mix2.0.Test.0.Test.????????????????????????????????.wav')
          lFinalFileName = getFileFromGlob('05_Mix/Final.????????????????????????????????.wav')
          lFinalMixFileName = getFileFromGlob('05_Mix/Final.0.Test.????????????????????????????????.wav')
          assert_rb_content [
            {
              :InputFileName => 'Wave1.wav',
              :OutputFileName => lWave1ProcessedFileName,
              :Params => {
                :Param1 => 'TestParam_Wave1'
              }
            },
            {
              :InputFileName => 'Wave2.wav',
              :OutputFileName => lWave2ProcessedFileName,
              :Params => {
                :Param1 => 'TestParam_Wave2'
              }
            },
            {
              :InputFileName => lMix1FileName,
              :OutputFileName => lMix1MixFileName,
              :Params => {
                :Param1 => 'TestParam_Mix1'
              }
            },
            {
              :InputFileName => lMix1MixFileName,
              :OutputFileName => lMix1ProcessedFileName,
              :Params => {
                :Param1 => 'TestParam_Mix1_2'
              }
            },
            {
              :InputFileName => 'Wave3.wav',
              :OutputFileName => lWave3ProcessedFileName,
              :Params => {
                :Param1 => 'TestParam_Wave3'
              }
            },
            {
              :InputFileName => 'Wave4.wav',
              :OutputFileName => lWave4ProcessedFileName,
              :Params => {
                :Param1 => 'TestParam_Wave4'
              }
            },
            {
              :InputFileName => lMix2FileName,
              :OutputFileName => lMix2MixFileName,
              :Params => {
                :Param1 => 'TestParam_Mix2'
              }
            },
            {
              :InputFileName => lMix2MixFileName,
              :OutputFileName => lMix2ProcessedFileName,
              :Params => {
                :Param1 => 'TestParam_Mix2_2'
              }
            },
            {
              :InputFileName => lFinalFileName,
              :OutputFileName => lFinalMixFileName,
              :Params => {
                :Param1 => 'TestParam_Final'
              }
            }
          ], 'Process_Test.rb'
          assert_wave_lnk '05_Mix/Wave1.Wave2', '05_Mix/Final/Mix1.wav'
          assert_wave_lnk '05_Mix/Wave3.Wave4', '05_Mix/Final/Mix2.wav'
          assert_wave_lnk '05_Mix/Wave1.Wave2.Wave3.Wave4', '05_Mix/Final/Final.wav'
        end
      end

      # Useless processing in a tree
      # Here is the mix tree:
      # Final
      # +-Mix1
      # | +-Wave1
      # | +-Wave2
      # +-Mix2
      #   +-Wave3
      #   +-Wave4
      def testUselessProcessOrderTree
        execute_Mix_WithConf({
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave1.wav'
                },
                {
                  :Name => 'Wave2.wav'
                },
                {
                  :Name => 'Wave3.wav'
                },
                {
                  :Name => 'Wave4.wav'
                }
              ]
            },
            :Mix => {
              'Mix1' => {
                :Tracks => {
                  'Wave1.wav' => {
                    :Processes => [
                      {
                        :Name => 'VolCorrection',
                        :Factor => '1db'
                      },
                      {
                        :Name => 'VolCorrection',
                        :Factor => '-1db'
                      }
                    ]
                  },
                  'Wave2.wav' => {
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
                },
                :Processes => [
                  {
                    :Name => 'VolCorrection',
                    :Factor => '3db'
                  },
                  {
                    :Name => 'VolCorrection',
                    :Factor => '-3db'
                  }
                ]
              },
              'Mix2' => {
                :Tracks => {
                  'Wave3.wav' => {
                    :Processes => [
                      {
                        :Name => 'VolCorrection',
                        :Factor => '4db'
                      },
                      {
                        :Name => 'VolCorrection',
                        :Factor => '-4db'
                      }
                    ]
                  },
                  'Wave4.wav' => {
                    :Processes => [
                      {
                        :Name => 'VolCorrection',
                        :Factor => '5db'
                      },
                      {
                        :Name => 'VolCorrection',
                        :Factor => '-5db'
                      }
                    ]
                  }
                },
                :Processes => [
                  {
                    :Name => 'VolCorrection',
                    :Factor => '6db'
                  },
                  {
                    :Name => 'VolCorrection',
                    :Factor => '-6db'
                  }
                ]
              },
              'Final' => {
                :Tracks => {
                  'Mix1' => {
                    :Processes => [
                      {
                        :Name => 'VolCorrection',
                        :Factor => '7db'
                      },
                      {
                        :Name => 'VolCorrection',
                        :Factor => '-7db'
                      }
                    ]
                  },
                  'Mix2' => {
                    :Processes => [
                      {
                        :Name => 'VolCorrection',
                        :Factor => '8db'
                      },
                      {
                        :Name => 'VolCorrection',
                        :Factor => '-8db'
                      }
                    ]
                  }
                },
                :Processes => [
                      {
                        :Name => 'VolCorrection',
                        :Factor => '9db'
                      },
                      {
                        :Name => 'VolCorrection',
                        :Factor => '-9db'
                      }
                ]
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/01_Source/Wave/Wave1.wav', 'Wave1.wav' ],
            [ 'Wave/01_Source/Wave/Wave2.wav', 'Wave2.wav' ],
            [ 'Wave/01_Source/Wave/Wave3.wav', 'Wave3.wav' ],
            [ 'Wave/01_Source/Wave/Wave4.wav', 'Wave4.wav' ]
          ],
          :FakeWSK => [
            {
              :Input => 'Wave1.wav',
              :Output => /05_Mix\/Mix1\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', 'Wave2.wav|1' ],
              :UseWave => '05_Mix/Wave1.Wave2.wav'
            },
            {
              :Input => 'Wave3.wav',
              :Output => /05_Mix\/Mix2\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', 'Wave4.wav|1' ],
              :UseWave => '05_Mix/Wave3.Wave4.wav'
            },
            {
              :Input => /05_Mix\/Mix1\.[[:xdigit:]]{32,32}\.wav/,
              :Output => /05_Mix\/Final\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', /05_Mix\/Mix2\.[[:xdigit:]]{32,32}\.wav\|1/ ],
              :UseWave => '05_Mix/Wave1.Wave2.Wave3.Wave4.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert Dir.glob('05_Mix/Wave1.0.Test.????????????????????????????????.wav').empty?
          assert Dir.glob('05_Mix/Wave2.0.Test.????????????????????????????????.wav').empty?
          getFileFromGlob('05_Mix/Mix1.????????????????????????????????.wav')
          assert Dir.glob('05_Mix/Mix1.0.Test.????????????????????????????????.wav').empty?
          assert Dir.glob('05_Mix/Wave3.0.Test.????????????????????????????????.wav').empty?
          assert Dir.glob('05_Mix/Wave4.0.Test.????????????????????????????????.wav').empty?
          getFileFromGlob('05_Mix/Mix2.????????????????????????????????.wav')
          assert Dir.glob('05_Mix/Mix2.0.Test.????????????????????????????????.wav').empty?
          assert Dir.glob('05_Mix/Mix1.0.Test.0.Test.????????????????????????????????.wav').empty?
          assert Dir.glob('05_Mix/Mix2.0.Test.0.Test.????????????????????????????????.wav').empty?
          getFileFromGlob('05_Mix/Final.????????????????????????????????.wav')
          assert Dir.glob('05_Mix/Final.0.Test.????????????????????????????????.wav').empty?
          assert_wave_lnk '05_Mix/Wave1.Wave2', '05_Mix/Final/Mix1.wav'
          assert_wave_lnk '05_Mix/Wave3.Wave4', '05_Mix/Final/Mix2.wav'
          assert_wave_lnk '05_Mix/Wave1.Wave2.Wave3.Wave4', '05_Mix/Final/Final.wav'
        end
      end

      # Simple cycle
      def testSimpleCycle
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
                  'Wave.wav' => {},
                  'Final' => {}
                }
              }
            }
        }) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 1, iExitStatus
          assert !File.exists?('05_Mix')
        end
      end

      # A twisted cycle:
      # Final
      # +-Mix1
      # | +-Wave1
      # | +-Mix2
      # +-Mix2
      #   +-Wave2
      #   +-Mix1
      def testTwistedCycle
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
                  'Mix1' => {},
                  'Mix2' => {}
                }
              },
              'Mix1' => {
                :Tracks => {
                  'Wave1.wav' => {},
                  'Mix2' => {}
                }
              },
              'Mix2' => {
                :Tracks => {
                  'Wave2.wav' => {},
                  'Mix1' => {}
                }
              }
            }
        }) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 1, iExitStatus
          assert !File.exists?('05_Mix')
        end
      end

      # Specify 1 mix on command line
      def testCommandLine1Mix
        execute_binary_with_conf('Mix', [ '--name', 'Mix2' ], {
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave1.wav'
                },
                {
                  :Name => 'Wave2.wav'
                },
                {
                  :Name => 'Wave3.wav'
                },
                {
                  :Name => 'Wave4.wav'
                }
              ]
            },
            :Mix => {
              'Mix1' => {
                :Tracks => {
                  'Wave1.wav' => {},
                  'Wave2.wav' => {}
                }
              },
              'Mix2' => {
                :Tracks => {
                  'Wave3.wav' => {},
                  'Wave4.wav' => {}
                }
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/01_Source/Wave/Wave3.wav', 'Wave3.wav' ],
            [ 'Wave/01_Source/Wave/Wave4.wav', 'Wave4.wav' ]
          ],
          :FakeWSK => [
            {
              :Input => 'Wave3.wav',
              :Output => /05_Mix\/Mix2\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', 'Wave4.wav|1' ],
              :UseWave => '05_Mix/Wave3.Wave4.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          getFileFromGlob('05_Mix/Mix2.????????????????????????????????.wav')
          assert Dir.glob('05_Mix/Mix1.????????????????????????????????.wav').empty?
          assert_wave_lnk '05_Mix/Wave3.Wave4', '05_Mix/Final/Mix2.wav'
        end
      end

      # Specify 2 mixes on command line
      def testCommandLine2Mixes
        execute_binary_with_conf('Mix', [ '--name', 'Mix3', '--name', 'Mix2' ], {
            :WaveFiles => {
              :FilesList => [
                {
                  :Name => 'Wave1.wav'
                },
                {
                  :Name => 'Wave2.wav'
                },
                {
                  :Name => 'Wave3.wav'
                },
                {
                  :Name => 'Wave4.wav'
                },
                {
                  :Name => 'Wave5.wav'
                },
                {
                  :Name => 'Wave6.wav'
                }
              ]
            },
            :Mix => {
              'Mix1' => {
                :Tracks => {
                  'Wave1.wav' => {},
                  'Wave2.wav' => {}
                }
              },
              'Mix2' => {
                :Tracks => {
                  'Wave3.wav' => {},
                  'Wave4.wav' => {}
                }
              },
              'Mix3' => {
                :Tracks => {
                  'Wave5.wav' => {},
                  'Wave6.wav' => {}
                }
              }
            }
          },
          :PrepareFiles => [
            [ 'Wave/01_Source/Wave/Wave3.wav', 'Wave3.wav' ],
            [ 'Wave/01_Source/Wave/Wave4.wav', 'Wave4.wav' ],
            [ 'Wave/01_Source/Wave/Wave1.wav', 'Wave5.wav' ],
            [ 'Wave/01_Source/Wave/Wave2.wav', 'Wave6.wav' ]
          ],
          :FakeWSK => [
            {
              :Input => 'Wave3.wav',
              :Output => /05_Mix\/Mix2\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', 'Wave4.wav|1' ],
              :UseWave => '05_Mix/Wave3.Wave4.wav'
            },
            {
              :Input => 'Wave5.wav',
              :Output => /05_Mix\/Mix3\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', 'Wave6.wav|1' ],
              :UseWave => '05_Mix/Wave1.Wave2.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          getFileFromGlob('05_Mix/Mix2.????????????????????????????????.wav')
          getFileFromGlob('05_Mix/Mix3.????????????????????????????????.wav')
          assert Dir.glob('05_Mix/Mix1.????????????????????????????????.wav').empty?
          assert_wave_lnk '05_Mix/Wave3.Wave4', '05_Mix/Final/Mix2.wav'
          assert_wave_lnk '05_Mix/Wave1.Wave2', '05_Mix/Final/Mix3.wav'
        end
      end

      # Specify 1 mix on command line with a cycle on another mix
      def testCommandLine1MixWithOtherCycle
        execute_binary_with_conf('Mix', [ '--name', 'Mix2' ], {
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
              'Mix1' => {
                :Tracks => {
                  'Mix1' => {}
                }
              },
              'Mix2' => {
                :Tracks => {
                  'Wave1.wav' => {},
                  'Wave2.wav' => {}
                }
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
              :Output => /05_Mix\/Mix2\.[[:xdigit:]]{32,32}\.wav/,
              :Action => 'Mix',
              :Params => [ '--files', 'Wave2.wav|1' ],
              :UseWave => '05_Mix/Wave1.Wave2.wav'
            }
        ]) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          getFileFromGlob('05_Mix/Mix2.????????????????????????????????.wav')
          assert Dir.glob('05_Mix/Mix1.????????????????????????????????.wav').empty?
          assert_wave_lnk '05_Mix/Wave1.Wave2', '05_Mix/Final/Mix2.wav'
        end
      end

    end

  end

end
