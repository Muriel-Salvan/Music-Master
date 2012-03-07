{

  # Command line to run WSK tool
  :WSKCmdLine => "ruby -w #{ENV['MMT_ROOTPATH']}/test/FakeWSK.rb",
  # Uncomment the following to generate real Wave files if there is a working WSK installation
  #:WSKCmdLine => "WSK.rb",

  # Directories used
  :Directories => {

    # Directory to record files to
    :Record => '01_Source/Record',

    # Directory to store static audio files to
    :Wave => '01_Source/Wave',

    # Directory to store analysis results of recorded files to
    :AnalyzeRecord => 'Analyze/Record',

    # Directory to clean files to
    :Clean => '02_Clean/Record',

    # Directory to calibrate files to
    :Calibrate => '03_Calibrate/Record',

    # Directory to process static audio files to
    :ProcessWave => '04_Process/Wave',

    # Directory to process recorded files to
    :ProcessRecord => '04_Process/Record',

    # Directory to mix files to
    :Mix => '05_Mix',

    # Directory storing links to final mix files
    :FinalMix => '05_Mix/Final',

    # Directory to deliver files to
    :Deliver => '06_Deliver'

  },

  # Record options
  :Record => {

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

  # Options used when cleaning recorded files
  :Clean => {

    # Percentage of values added as a margin of the silence thresholds (arbitrary value)
    # A value of 0.1 means that if the silence recording has thresholds from X to Y values, then we consider the silence thresholds to be from X-0.1*MaxValue to Y+0.1*MaxValue, MaxValue being the maximal value for the audio bit depth.
    :MarginSilenceThresholds => 0.1,

    # Durations used for noise gates
    # !!! Attack + Release should be < SilenceMin !!!
    :Attack => '0.1s',
    :Release => '0.1s',
    :SilenceMin => '1s'

  },

  # Options used by delivery formats
  :Formats => {

    'Wave' => {
      # Command line to run Sample Rate Converter tool
      :SRCCmdLine => "ruby -w #{ENV['MMT_ROOTPATH']}/test/FakeSSRC.rb"
      # Uncomment the following to convert real Wave files if there is a working SSRC installation
      #:SRCCmdLine => "ssrc"
    }

  }

}
