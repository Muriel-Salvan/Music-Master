#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMasterTest

  class Config < ::Test::Unit::TestCase

    # Missing config file
    def testMissingConfigFile
      execute_Record([]) do |iStdOUTLog, iStdERRLog, iExitStatus|
        assert_exitstatus 1, iExitStatus
        assert_match 'Please specify 1 config file', iStdERRLog
      end
    end

    # Empty config file
    def testEmptyConfigFile
      execute_Record_WithConf({}) do |iStdOUTLog, iStdERRLog, iExitStatus|
        assert_exitstatus 0, iExitStatus
      end
    end

    # Invalid config file
    def testInvalidConfigFile
      execute_Record_WithConf(42) do |iStdOUTLog, iStdERRLog, iExitStatus|
        assert_exitstatus 1, iExitStatus
      end
    end

  end

end
