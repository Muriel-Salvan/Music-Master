module MusicMasterTest

  module Deliver

    class Generic < ::Test::Unit::TestCase

      # Nothing to deliver
      def testNoDeliverable
        execute_Deliver_WithConf({
            :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
            :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } }
          },
          :PrepareFiles => getPreparedFiles(:Mixed_Wave1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert !File.exists?('06_Deliver')
        end
      end

      # Simple delivery
      def testSimple
        execute_Deliver_WithConf({
            :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
            :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
            :Deliver => {
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test'
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
          assert_rb_content({
            :SrcFileName => 'Wave1.wav',
            :DstFileName => '06_Deliver/Deliverable/Track.test.rb',
            :FormatConf => {},
            :Metadata => { :FileName => 'Track' }
          }, '06_Deliver/Deliverable/Track.test.rb')
        end
      end

      # Simple delivery with a name not fitting on the file system
      def testNotFSName
        execute_Deliver_WithConf({
            :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
            :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
            :Deliver => {
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test'
                }
              },
              :Deliverables => {
                'Deliverable/With/Bad/Characters' => {
                  :Mix => 'Mix1',
                  :Format => 'Test'
                }
              }
            }
          },
          :PrepareFiles => getPreparedFiles(:Mixed_Wave1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert_rb_content({
            :SrcFileName => 'Wave1.wav',
            :DstFileName => '06_Deliver/Deliverable_With_Bad_Characters/Track.test.rb',
            :FormatConf => {},
            :Metadata => { :FileName => 'Track' }
          }, '06_Deliver/Deliverable_With_Bad_Characters/Track.test.rb')
        end
      end

      # Check format parameters
      def testFormatParameters
        execute_Deliver_WithConf({
            :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
            :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
            :Deliver => {
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test',
                  :Param1 => 'FormatParam1'
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
          assert_rb_content({
            :SrcFileName => 'Wave1.wav',
            :DstFileName => '06_Deliver/Deliverable/Track.test.rb',
            :FormatConf => {
              :Param1 => 'FormatParam1'
            },
            :Metadata => { :FileName => 'Track' }
          }, '06_Deliver/Deliverable/Track.test.rb')
        end
      end

      # Global metadata
      def testGlobalMetadata
        execute_Deliver_WithConf({
            :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
            :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
            :Deliver => {
              :Metadata => {
                :MDParam1 => 'MDValue1'
              },
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test'
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
          assert_rb_content({
            :SrcFileName => 'Wave1.wav',
            :DstFileName => '06_Deliver/Deliverable/Track.test.rb',
            :FormatConf => {},
            :Metadata => {
              :FileName => 'Track',
              :MDParam1 => 'MDValue1'
            }
          }, '06_Deliver/Deliverable/Track.test.rb')
        end
      end

      # Local metadata
      def testLocalMetadata
        execute_Deliver_WithConf({
            :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
            :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
            :Deliver => {
              :Metadata => {
                :MDParam1 => 'MDValue1',
                :MDParam2 => 'MDValue2.1'
              },
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test'
                }
              },
              :Deliverables => {
                'Deliverable' => {
                  :Mix => 'Mix1',
                  :Format => 'Test',
                  :Metadata => {
                    :MDParam2 => 'MDValue2.2',
                    :MDParam3 => 'MDValue3'
                  }
                }
              }
            }
          },
          :PrepareFiles => getPreparedFiles(:Mixed_Wave1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert_rb_content({
            :SrcFileName => 'Wave1.wav',
            :DstFileName => '06_Deliver/Deliverable/Track.test.rb',
            :FormatConf => {},
            :Metadata => {
              :FileName => 'Track',
              :MDParam1 => 'MDValue1',
              :MDParam2 => 'MDValue2.2',
              :MDParam3 => 'MDValue3'
            }
          }, '06_Deliver/Deliverable/Track.test.rb')
        end
      end

      # Specific file name using metadata
      def testChangeFileName
        execute_Deliver_WithConf({
            :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
            :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
            :Deliver => {
              :Metadata => {
                :MDParam1 => 'MDValue1',
                :FileName => 'NewFileName - %{MDParam1}'
              },
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test'
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
          assert_rb_content({
            :SrcFileName => 'Wave1.wav',
            :DstFileName => '06_Deliver/Deliverable/NewFileName - MDValue1.test.rb',
            :FormatConf => {},
            :Metadata => {
              :FileName => 'NewFileName - %{MDParam1}',
              :MDParam1 => 'MDValue1'
            }
          }, '06_Deliver/Deliverable/NewFileName - MDValue1.test.rb')
        end
      end

      # Specific file name using metadata and a variable form local metadata
      def testChangeFileNameWithVarFromLocal
        execute_Deliver_WithConf({
            :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
            :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
            :Deliver => {
              :Metadata => {
                :MDParam1 => 'MDValue1.1',
                :FileName => 'NewFileName - %{MDParam1} - %{MDParam2}'
              },
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test'
                }
              },
              :Deliverables => {
                'Deliverable' => {
                  :Mix => 'Mix1',
                  :Format => 'Test',
                  :Metadata => {
                    :MDParam1 => 'MDValue1.2',
                    :MDParam2 => 'MDValue2'
                  }
                }
              }
            }
          },
          :PrepareFiles => getPreparedFiles(:Mixed_Wave1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert_rb_content({
            :SrcFileName => 'Wave1.wav',
            :DstFileName => '06_Deliver/Deliverable/NewFileName - MDValue1.2 - MDValue2.test.rb',
            :FormatConf => {},
            :Metadata => {
              :FileName => 'NewFileName - %{MDParam1} - %{MDParam2}',
              :MDParam1 => 'MDValue1.2',
              :MDParam2 => 'MDValue2'
            }
          }, '06_Deliver/Deliverable/NewFileName - MDValue1.2 - MDValue2.test.rb')
        end
      end

      # Specific file name using local metadata
      def testChangeFileNameFromLocal
        execute_Deliver_WithConf({
            :WaveFiles => { :FilesList => [ { :Name => 'Wave1.wav' } ] },
            :Mix => { 'Mix1' => { :Tracks => { 'Wave1.wav' => {} } } },
            :Deliver => {
              :Metadata => {
                :MDParam1 => 'MDValue1',
                :FileName => 'NewFileName - %{MDParam1}'
              },
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test'
                }
              },
              :Deliverables => {
                'Deliverable' => {
                  :Mix => 'Mix1',
                  :Format => 'Test',
                  :Metadata => {
                    :FileName => 'NewNewFileName - %{MDParam1}'
                  }
                }
              }
            }
          },
          :PrepareFiles => getPreparedFiles(:Mixed_Wave1)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert_rb_content({
            :SrcFileName => 'Wave1.wav',
            :DstFileName => '06_Deliver/Deliverable/NewNewFileName - MDValue1.test.rb',
            :FormatConf => {},
            :Metadata => {
              :FileName => 'NewNewFileName - %{MDParam1}',
              :MDParam1 => 'MDValue1'
            }
          }, '06_Deliver/Deliverable/NewNewFileName - MDValue1.test.rb')
        end
      end

      # Test delivering several
      def testSeveral
        execute_Deliver_WithConf({
            :WaveFiles => {
              :FilesList => [
                { :Name => 'Wave1.wav' },
                { :Name => 'Wave2.wav' }
              ] },
            :Mix => {
              'Mix1' => { :Tracks => { 'Wave1.wav' => {} } },
              'Mix2' => { :Tracks => { 'Wave2.wav' => {} } }
            },
            :Deliver => {
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test'
                }
              },
              :Deliverables => {
                'Deliverable1' => {
                  :Mix => 'Mix1',
                  :Format => 'Test'
                },
                'Deliverable2' => {
                  :Mix => 'Mix2',
                  :Format => 'Test'
                }
              }
            }
          },
          :PrepareFiles => getPreparedFiles(:Mixed_Wave1, :Mixed_Wave2)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert_rb_content({
            :SrcFileName => 'Wave1.wav',
            :DstFileName => '06_Deliver/Deliverable1/Track.test.rb',
            :FormatConf => {},
            :Metadata => { :FileName => 'Track' }
          }, '06_Deliver/Deliverable1/Track.test.rb')
          assert_rb_content({
            :SrcFileName => 'Wave2.wav',
            :DstFileName => '06_Deliver/Deliverable2/Track.test.rb',
            :FormatConf => {},
            :Metadata => { :FileName => 'Track' }
          }, '06_Deliver/Deliverable2/Track.test.rb')
        end
      end

      # Test delivering several with 1 --name command
      def testSeveralWith1Specified
        execute_binary_with_conf('Deliver', [ '--name', 'Deliverable2' ], {
            :WaveFiles => {
              :FilesList => [
                { :Name => 'Wave1.wav' },
                { :Name => 'Wave2.wav' }
              ] },
            :Mix => {
              'Mix1' => { :Tracks => { 'Wave1.wav' => {} } },
              'Mix2' => { :Tracks => { 'Wave2.wav' => {} } }
            },
            :Deliver => {
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test'
                }
              },
              :Deliverables => {
                'Deliverable1' => {
                  :Mix => 'Mix1',
                  :Format => 'Test'
                },
                'Deliverable2' => {
                  :Mix => 'Mix2',
                  :Format => 'Test'
                }
              }
            }
          },
          :PrepareFiles => getPreparedFiles(:Mixed_Wave1, :Mixed_Wave2)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert !File.exists?('06_Deliver/Deliverable1')
          assert_rb_content({
            :SrcFileName => 'Wave2.wav',
            :DstFileName => '06_Deliver/Deliverable2/Track.test.rb',
            :FormatConf => {},
            :Metadata => { :FileName => 'Track' }
          }, '06_Deliver/Deliverable2/Track.test.rb')
        end
      end

      # Test delivering several with 2 --name commands
      def testSeveralWith2Specified
        execute_binary_with_conf('Deliver', [ '--name', 'Deliverable3', '--name', 'Deliverable2' ], {
            :WaveFiles => {
              :FilesList => [
                { :Name => 'Wave1.wav' },
                { :Name => 'Wave2.wav' },
                { :Name => 'Wave3.wav' }
              ] },
            :Mix => {
              'Mix1' => { :Tracks => { 'Wave1.wav' => {} } },
              'Mix2' => { :Tracks => { 'Wave2.wav' => {} } },
              'Mix3' => { :Tracks => { 'Wave3.wav' => {} } }
            },
            :Deliver => {
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test'
                }
              },
              :Deliverables => {
                'Deliverable1' => {
                  :Mix => 'Mix1',
                  :Format => 'Test'
                },
                'Deliverable2' => {
                  :Mix => 'Mix2',
                  :Format => 'Test'
                },
                'Deliverable3' => {
                  :Mix => 'Mix3',
                  :Format => 'Test'
                }
              }
            }
          },
          :PrepareFiles => getPreparedFiles(:Mixed_Wave1, :Mixed_Wave2, :Mixed_Wave3)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert !File.exists?('06_Deliver/Deliverable1')
          assert_rb_content({
            :SrcFileName => 'Wave2.wav',
            :DstFileName => '06_Deliver/Deliverable2/Track.test.rb',
            :FormatConf => {},
            :Metadata => { :FileName => 'Track' }
          }, '06_Deliver/Deliverable2/Track.test.rb')
          assert_rb_content({
            :SrcFileName => 'Wave3.wav',
            :DstFileName => '06_Deliver/Deliverable3/Track.test.rb',
            :FormatConf => {},
            :Metadata => { :FileName => 'Track' }
          }, '06_Deliver/Deliverable3/Track.test.rb')
        end
      end

      # Test that local metadata is not shared when delivering several
      def testDontShareLocalMetadata
        execute_Deliver_WithConf({
            :WaveFiles => {
              :FilesList => [
                { :Name => 'Wave1.wav' },
                { :Name => 'Wave2.wav' }
              ] },
            :Mix => {
              'Mix1' => { :Tracks => { 'Wave1.wav' => {} } },
              'Mix2' => { :Tracks => { 'Wave2.wav' => {} } }
            },
            :Deliver => {
              :Metadata => {
                :MDParam1 => 'MDValue1',
                :MDParam2 => 'MDValue2'
              },
              :Formats => {
                'Test' => {
                  :FileFormat => 'Test'
                }
              },
              :Deliverables => {
                'Deliverable1' => {
                  :Mix => 'Mix1',
                  :Format => 'Test',
                  :Metadata => {
                    :MDParam2 => 'MDValue2.1',
                    :MDParam3 => 'MDValue3.1'
                  }
                },
                'Deliverable2' => {
                  :Mix => 'Mix2',
                  :Format => 'Test',
                  :Metadata => {
                    :MDParam2 => 'MDValue2.2',
                    :MDParam3 => 'MDValue3.2'
                  }
                }
              }
            }
          },
          :PrepareFiles => getPreparedFiles(:Mixed_Wave1, :Mixed_Wave2)
        ) do |iStdOUTLog, iStdERRLog, iExitStatus|
          assert_exitstatus 0, iExitStatus
          assert_rb_content({
            :SrcFileName => 'Wave1.wav',
            :DstFileName => '06_Deliver/Deliverable1/Track.test.rb',
            :FormatConf => {},
            :Metadata => {
              :FileName => 'Track',
              :MDParam1 => 'MDValue1',
              :MDParam2 => 'MDValue2.1',
              :MDParam3 => 'MDValue3.1'
            }
          }, '06_Deliver/Deliverable1/Track.test.rb')
          assert_rb_content({
            :SrcFileName => 'Wave2.wav',
            :DstFileName => '06_Deliver/Deliverable2/Track.test.rb',
            :FormatConf => {},
            :Metadata => {
              :FileName => 'Track',
              :MDParam1 => 'MDValue1',
              :MDParam2 => 'MDValue2.2',
              :MDParam3 => 'MDValue3.2'
            }
          }, '06_Deliver/Deliverable2/Track.test.rb')
        end
      end

      # Deliver the same mix with different formats

      # Deliver different mixes with different formats

    end

  end

end
