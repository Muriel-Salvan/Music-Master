# Set to true to activate more verbose logging and to not clean repositories
$MusicMasterTest_Debug = false

# Set to true to use the real WSK command.
# In this case FakeWSK will not be used.
# If true, don't forget to configure the WSK command line in test/DefaultMusicMaster.conf.rb
$MusicMasterTest_UseWSK = false

# Set to true to use the real SSRC command.
# In this case FakeSSRC will not be used.
# If true, don't forget to configure the SSRC command line in test/DefaultMusicMaster.conf.rb
$MusicMasterTest_UseSSRC = false

require 'test/unit'
require 'rUtilAnts/Logging'
RUtilAnts::Logging::install_logger_on_object(:debug_mode => $MusicMasterTest_Debug)
require 'rUtilAnts/Misc'
RUtilAnts::Misc::install_misc_on_object

$MusicMasterTest_RootPath = File.expand_path("#{File.dirname(__FILE__)}/..")

module MusicMasterTest

  # Get the root path
  #
  # Return::
  # * _String_: The root path
  def self.getRootPath
    return $MusicMasterTest_RootPath
  end

end

$: << MusicMasterTest::getRootPath

require 'test/Common'
require 'test/Tests/Config'
require 'test/Tests/GenerateSourceFiles/Tracks'
require 'test/Tests/GenerateSourceFiles/Wave'
require 'test/Tests/CleanRecordings/Tracks'
require 'test/Tests/CalibrateRecordings/Tracks'
require 'test/Tests/ProcessSourceFiles/Wave'
require 'test/Tests/ProcessSourceFiles/Tracks'
require 'test/Tests/ProcessSourceFiles/Generic'
Dir.glob('test/Tests/ProcessSourceFiles/Processes/*') do |iTestFileName|
  require iTestFileName
end
require 'test/Tests/Mix/Tracks'
require 'test/Tests/Mix/Wave'
require 'test/Tests/Mix/SingleTrackID'
require 'test/Tests/Mix/SeveralTrackID'
require 'test/Tests/Deliver/Generic'
Dir.glob('test/Tests/Deliver/Formats/*') do |iTestFileName|
  require iTestFileName
end
