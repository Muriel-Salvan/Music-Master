{

  # Command line to run WSK tool
  :WSKCmdLine => "ruby -w #{ENV['MMT_ROOTPATH']}/test/FakeWSK.rb",
  # Uncomment the following to generate real Wave files if there is a working WSK installation
  #:WSKCmdLine => "WSK.rb",

  # Command line to run Sample Rate Converter tool
  :SRCCmdLine => "ruby -w #{ENV['MMT_ROOTPATH']}/test/FakeSSRC.rb",
  # Uncomment the following to convert real Wave files if there is a working SSRC installation
  #:WSKCmdLine => "WSK.rb",

  # Record options
  :Record => {

    # Directory in which temporary files will be generated
    :TempDir => 'RecordTemp',

    # Directory in which recorded Wave files are stored
    :WaveDir => 'WaveSrc',

    # Method returning the name of the next recorded file
    :RecordedFileGetter => Proc.new do
      # Dequeue the name of the next Wave file to record
      lLstRecordedFiles = eval(File.read('MMT_RecordedFiles.rb'))
      raise 'No more files to be recorded' if (lLstRecordedFiles.empty?)
      lWaveBaseName = lLstRecordedFiles.first
      File.open('MMT_RecordedFiles.rb', 'w') { |oFile| oFile.write(lLstRecordedFiles[1..-1].inspect) }
      rDstWaveFileName = nil
      if (lWaveBaseName[-4..-1] == '.wav')
        rDstWaveFileName = lWaveBaseName
      else
        # Generate a WAV file copied from a test one
        lSrcWaveFileName = "#{ENV['MMT_ROOTPATH']}/test/Wave/#{lWaveBaseName}.wav"
        require 'tmpdir'
        rDstWaveFileName = "#{Dir.tmpdir}/#{lWaveBaseName}_Recorded.wav"
        log_debug "Preparing Wave file to be recorded: #{lSrcWaveFileName} => #{rDstWaveFileName}" if (ENV['MMT_DEBUG'] == '1')
        FileUtils::mkdir_p(File.dirname(rDstWaveFileName))
        FileUtils::cp(lSrcWaveFileName, rDstWaveFileName)
      end

      next rDstWaveFileName
    end

  },

  # PrepareMix options
  :PrepareMix => {

    # Directory in which temporary files will be generated
    :TempDir => 'PrepareMixTemp',

    # Percentage of values added as a margin of the silence thresholds (arbitrary value)
    :MarginSilenceThresholds => 0.1,

  },

  # Mix options
  :Mix => {

    # Directory in which temporary files will be generated
    :TempDir => 'MixTemp'

  },

  # Master options
  :Master => {

    # Directory in which files will be generated
    :Dir => 'Master'

  },

  # Album options
  :Album => {

    # Directory in which temporary files will be generated
    :TempDir => 'AlbumTemp',

    # Directory in which files will be generated
    :Dir => 'Album'

  },

  # Album delivery options
  :AlbumDeliver => {

    # Directory in which files will be generated
    :Dir => 'AlbumDeliver'

  },

  # Single Track delivery options
  :Deliver => {

    # Directory in which files will be generated
    :Dir => 'Deliver'

  },

  # Options for NoiseGate processes
  :NoiseGate => {

    # Durations used for noise gates
    # !!! Attack + Release should be < SilenceMin !!!
    :Attack => '0.1s',
    :Release => '0.1s',
    :SilenceMin => '1s'

  },

  # Options for Compressor processes
  :Compressor => {

    # Interval used to measure volume
    :Interval => '0.1s'

  }

}
