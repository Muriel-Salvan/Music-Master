#!env ruby
#--
# Copyright (c) 2009 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'MusicMaster/Common'
require 'rUtilAnts/Logging'
RUtilAnts::Logging::initializeLogging('', '')
require 'MusicMaster/ConfLoader'

module MusicMaster

  # Execute the delivery
  #
  # Parameters:
  # * *iWaveFile* (_String_): Wave file to deliver
  def self.execute(iWaveFile)
    lRealBaseName = File.basename(iWaveFile)[0..-5]
    MusicMaster::src(iWaveFile, "#{$MusicMasterConf[:Deliver][:Dir]}/#{lRealBaseName}_96_24.wav", :SampleRate => 96000)
    MusicMaster::src(iWaveFile, "#{$MusicMasterConf[:Deliver][:Dir]}/#{lRealBaseName}_48_24.wav", :SampleRate => 48000)
    MusicMaster::src(iWaveFile, "#{$MusicMasterConf[:Deliver][:Dir]}/#{lRealBaseName}_44_16.wav", :SampleRate => 44100, :BitDepth => 16, :Dither => true)
    # TODO: Deliver MP3 files too
  end

end

rErrorCode = 0
lWaveFile = ARGV[0]
if (lWaveFile == nil)
  logErr 'Please specify the WAVE file.'
  rErrorCode = 1
elsif (!File.exists?(lWaveFile))
  logErr "File #{lWaveFile} does not exist."
  rErrorCode = 2
else
  FileUtils::mkdir_p($MusicMasterConf[:Deliver][:Dir])
  MusicMaster::execute(lWaveFile)
  logInfo "===== Delivery finished in #{$MusicMasterConf[:Deliver][:Dir]}"
end

exit rErrorCode
