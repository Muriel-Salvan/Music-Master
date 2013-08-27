require 'tmpdir'
require 'fileutils'
require 'pp'
begin
  require 'processpilot/processpilot'
rescue LoadError
  puts "\n\n!!! Test framework needs ProcessPilot gem to work. Please install it: \"gem install ProcessPilot\"\n\n"
  raise
end
require 'lib/MusicMaster/Hash'
require 'lib/MusicMaster/Symbol'
require 'rUtilAnts/Platform'
RUtilAnts::Platform.install_platform_on_object

module Test

  module Unit

    class TestCase

      # Get a brand new working dir.
      # Set current directory in this working directory.
      #
      # Parameters::
      # * *CodeBlock*: Code called once working dir has been set up.
      #   * *iWorkingDir* (_String_): The working directory to be used
      def setupWorkingDir
        lWorkingDir = "#{MusicMasterTest::getTmpDir}/WorkingDir"
        FileUtils::rm_rf(lWorkingDir) if File.exists?(lWorkingDir)
        FileUtils::mkdir_p(lWorkingDir)
        change_dir(lWorkingDir) do
          yield(lWorkingDir)
        end
        FileUtils::rm_rf(lWorkingDir) if (!MusicMasterTest::debug?)
      end

      # Execute a binary in the test environment with given parameters
      #
      # Parameters::
      # * *iBinName* (_String_): Name of the binary
      # * *iParams* (<em>list<String></em>): Parameters to give to Record
      # * *iOptions* (<em>map<Symbol,Object></em>): Additional options [optional = {}]
      #   * *:RecordedFiles* (<em>list<String></em>): List of recorded files to provide to the recorder. Each file can be either the base name (without .wav extension) from a wave file from test/Wave (in this case a temporary file will be copied from this wave file), or a complete wave file name (in this case the RecordedFileGetter just returns this file name) [optional = []]
      #   * *:PrepareFiles* (<em>list< [String,String] ></em>): The list of files to copy from test/ to the test working directory before executing the binary [optional = []]
      #   * *:FakeWSK* (<em>list<map<String,Object>></em>): The list of fake WSK commands to receive [optional = []]:
      #     * *:Input* (_Object_): Name of the input file expected (can be a String or a RegExp)
      #     * *:Output* (_Object_): Name of the output file expected (can be a String or a RegExp)
      #     * *:Action* (_String_): Name of the action expected
      #     * *:Params* (<em>list<String></em>): List of parameters for the action [optional = []]
      #     * *:UseWave* (_String_): Path to the Wave file to be used (relative to the test/Wave folder) to generate the result
      #     * *:CopyFiles* (<em>map<String,String></em>): Additional files to be copied (source => destination) (source being relative to the test folder) [optional = {}]
      #   * *:FakeSSRC* (<em>list<map<String,Object>></em>): The list of fake SSRC commands to receive [optional = []]:
      #     * *:Input* (_Object_): Name of the input file expected (can be a String or a RegExp)
      #     * *:Output* (_Object_): Name of the output file expected (can be a String or a RegExp)
      #     * *:Params* (<em>list<String></em>): List of parameters [optional = []]
      #     * *:UseWave* (_String_): Path to the Wave file to be used (relative to the test/Wave folder) to generate the result
      #   * *:PilotingCode* (_Proc_): The code called to pilot the process [optional = nil]:
      #     * *oStdIN* (_IO_): The process' STDIN
      #     * *iStdOUT* (_IO_): The process' STDOUT
      #     * *iStdERR* (_IO_): The process' STDERR
      #     * *iChildProcess* (_ChildProcessInfo_): The corresponding ChildProcessInfo
      # * *CodeBlock*: Code called once it has been executed:
      #   * *iStdOUTLog* (_String_): Log STDOUT of the process
      #   * *iStdERRLog* (_String_): Log STDERR of the process
      #   * *iExitStatus* (_Integer_): Exit status
      def execute_binary(iBinName, iParams, iOptions = {})
        setupWorkingDir do |iWorkingDir|
          lRootPath = MusicMasterTest::getRootPath
          # Set the MusicMaster config file
          ENV['MUSICMASTER_CONF_PATH'] = "#{lRootPath}/test/DefaultMusicMaster.conf.rb"
          # Set the list of files to be recorded in a file.
          # This way we can compare the file's content after performance to make sure all files were marked as recorded.
          lLstFilesToBeRecorded = (iOptions[:RecordedFiles] || [])
          File.open('MMT_RecordedFiles.rb', 'w') { |oFile| oFile.write(lLstFilesToBeRecorded.inspect) }
          File.open('MMT_FakeWSK.rb', 'w') { |oFile| oFile.write((iOptions[:FakeWSK] || []).inspect) } if (!$MusicMasterTest_UseWSK)
          File.open('MMT_FakeSSRC.rb', 'w') { |oFile| oFile.write((iOptions[:FakeSSRC] || []).inspect) } if (!$MusicMasterTest_UseSSRC)
          log_debug "Setup files to be recorded: #{eval(File.read('MMT_RecordedFiles.rb')).join(', ')}" if (MusicMasterTest::debug?) and (!lLstFilesToBeRecorded.empty?)
          # Prepare files
          lPrepareFiles = (iOptions[:PrepareFiles] || [])
          lPrepareFiles.each do |iFileInfo|
            iSrcName, iDstName = iFileInfo
            FileUtils::mkdir_p(File.dirname(iDstName))
            if (iSrcName[0..0] == '*')
              # Create a shortcut
              log_debug "Create Shortcut #{iSrcName[1..-1]} => #{iDstName}"
              create_shortcut(iSrcName[1..-1], iDstName)
            else
              # Copy the file
              log_debug "Copy file #{lRootPath}/test/#{iSrcName} => #{iDstName}"
              FileUtils::cp("#{lRootPath}/test/#{iSrcName}", iDstName)
            end
          end
          # Set environmnet variables that will be used to trap some behaviour
          ENV['MMT_ROOTPATH'] = lRootPath
          lCmd = [ "#{lRootPath}/bin/#{iBinName}.rb" ] + iParams
          if (MusicMasterTest::debug?)
            ENV['MMT_DEBUG'] = '1'
            lCmd << '--debug'
          end
          lRubyCmdLine = [ 'ruby', '-w', "-I#{lRootPath}/lib" ]
          log_debug "#{Dir.getwd}> #{lRubyCmdLine.inspect} #{lCmd.inspect} ..." if (MusicMasterTest::debug?)
          if (MusicMasterTest::debug?)
            [ 'MUSICMASTER_CONF_PATH', 'MMT_ROOTPATH', 'MMT_DEBUG' ].each do |iVarName|
              log_debug "export #{iVarName}=#{ENV[iVarName]}"
            end
            log_debug "cd #{Dir.getwd}"
            log_debug "#{lRubyCmdLine.join(' ')} #{lCmd.join(' ')}"
          end
          lExitStatus = nil
          lStdOUTLog = nil
          lStdERRLog = nil
          ProcessPilot::pilot(*(lCmd + [{ :force_ruby_process_sync => true, :ruby_cmd_line => lRubyCmdLine, :debug => MusicMasterTest::debug? }])) do |oStdIN, iStdOUT, iStdERR, iChildProcess|
            if (iOptions[:PilotingCode] != nil)
              iOptions[:PilotingCode].call(oStdIN, iStdOUT, iStdERR, iChildProcess)
            end
            # Just wait for its completion
            while (!iChildProcess.exited?)
              sleep 0.1
            end
            # Get everything out of it
            lStdOUTLog = iStdOUT.read
            lStdERRLog = iStdERR.read
            lExitStatus = (iChildProcess.exit_status == nil) ? nil : iChildProcess.exit_status.exitstatus
          end
          log_debug "===== Process exited with status code #{lExitStatus}\n===== STDOUT:\n#{lStdOUTLog}\n===== STDERR:\n#{lStdERRLog}\n=====\n" if (MusicMasterTest::debug?)
          yield(lStdOUTLog, lStdERRLog, lExitStatus)
          # Assert files were all recorded
          assert_equal [], eval(File.read('MMT_RecordedFiles.rb'))
          # Assert WSK commands were all called
          assert_equal [], eval(File.read('MMT_FakeWSK.rb')) if (!$MusicMasterTest_UseWSK)
          # Assert SSRC commands were all called
          assert_equal [], eval(File.read('MMT_FakeSSRC.rb')) if (!$MusicMasterTest_UseSSRC)
          # In case of debug, do not remove files: we want them for debugging purposes
          if (!MusicMasterTest::debug?)
            File.unlink('MMT_RecordedFiles.rb')
            File.unlink('MMT_FakeWSK.rb') if (!$MusicMasterTest_UseWSK)
            File.unlink('MMT_FakeSSRC.rb') if (!$MusicMasterTest_UseSSRC)
            # Remove prepared Wave files
            lPrepareFiles.each do |iFileInfo|
              iSrcName, iDstName = iFileInfo
              if (iSrcName[0..0] == '*')
                File.unlink(get_shortcut_file_name(iDstName))
              else
                File.unlink(iDstName)
              end
            end
          end
        end
      end

      # Execute a binary in the test environment with the given configuration
      #
      # Parameters::
      # * *iBinName* (_String_): Binary name
      # * *iParams* (<em>list<String></em>): Parameters to give to the binary
      # * *iConf* (<em>map<Symbol,Object></em>): Configuration to run with
      # * *iOptions* (<em>map<Symbol,Object></em>): Additional options. See execute_binary for details. [optional = {}]
      # * *CodeBlock*: Code called once it has been executed:
      #   * *iStdOUTLog* (_String_): Log STDOUT of the process
      #   * *iStdERRLog* (_String_): Log STDERR of the process
      #   * *iExitStatus* (_Integer_): Exit status
      def execute_binary_with_conf(iBinName, iParams, iConf, iOptions = {})
        # Create the config file
        lConfFileName = "#{MusicMasterTest::getTmpDir}/#{iBinName}.conf.rb"
        FileUtils::mkdir_p(File.dirname(lConfFileName))
        File.open(lConfFileName, 'w') do |oFile|
          oFile << iConf.inspect
        end
        log_debug "Setup #{iBinName} config in #{lConfFileName}:\n#{eval(File.read(lConfFileName)).pretty_inspect}\n" if (MusicMasterTest::debug?)
        execute_binary(iBinName, iParams + [lConfFileName], iOptions) do |iStdOUTLog, iStdERRLog, iExitStatus|
          yield(iStdOUTLog, iStdERRLog, iExitStatus)
        end
        File.unlink(lConfFileName) if (!MusicMasterTest::debug?)
      end

      # Execute Record in the test environment with given parameters
      #
      # Parameters::
      # * *iParams* (<em>list<String></em>): Parameters to give to Record
      # * *iOptions* (<em>map<Symbol,Object></em>): Additional options. See execute_binary for details. [optional = {}]
      # * *CodeBlock*: Code called once it has been executed:
      #   * *iStdOUTLog* (_String_): Log STDOUT of the process
      #   * *iStdERRLog* (_String_): Log STDERR of the process
      #   * *iExitStatus* (_Integer_): Exit status
      def execute_Record(iParams, iOptions = {})
        execute_binary('Record', ['--recordedfilesprepared'] + iParams, iOptions) do |iStdOUTLog, iStdERRLog, iExitStatus|
          yield(iStdOUTLog, iStdERRLog, iExitStatus)
        end
      end

      # Execute Record in the test environment with the given configuration
      #
      # Parameters::
      # * *iConf* (<em>map<Symbol,Object></em>): Configuration to run with
      # * *iOptions* (<em>map<Symbol,Object></em>): Additional options. See execute_binary for details. [optional = {}]
      # * *CodeBlock*: Code called once it has been executed:
      #   * *iStdOUTLog* (_String_): Log STDOUT of the process
      #   * *iStdERRLog* (_String_): Log STDERR of the process
      #   * *iExitStatus* (_Integer_): Exit status
      def execute_Record_WithConf(iConf, iOptions = {})
        execute_binary_with_conf('Record', ['--recordedfilesprepared'], iConf, iOptions) do |iStdOUTLog, iStdERRLog, iExitStatus|
          yield(iStdOUTLog, iStdERRLog, iExitStatus)
        end
      end

      # Execute Clean in the test environment with the given configuration
      #
      # Parameters::
      # * *iConf* (<em>map<Symbol,Object></em>): Configuration to run with
      # * *iOptions* (<em>map<Symbol,Object></em>): Additional options. See execute_binary for details. [optional = {}]
      # * *CodeBlock*: Code called once it has been executed:
      #   * *iStdOUTLog* (_String_): Log STDOUT of the process
      #   * *iStdERRLog* (_String_): Log STDERR of the process
      #   * *iExitStatus* (_Integer_): Exit status
      def execute_Clean_WithConf(iConf, iOptions = {})
        execute_binary_with_conf('Clean', [], iConf, iOptions) do |iStdOUTLog, iStdERRLog, iExitStatus|
          yield(iStdOUTLog, iStdERRLog, iExitStatus)
        end
      end

      # Execute Calibrate in the test environment with the given configuration
      #
      # Parameters::
      # * *iConf* (<em>map<Symbol,Object></em>): Configuration to run with
      # * *iOptions* (<em>map<Symbol,Object></em>): Additional options. See execute_binary for details. [optional = {}]
      # * *CodeBlock*: Code called once it has been executed:
      #   * *iStdOUTLog* (_String_): Log STDOUT of the process
      #   * *iStdERRLog* (_String_): Log STDERR of the process
      #   * *iExitStatus* (_Integer_): Exit status
      def execute_Calibrate_WithConf(iConf, iOptions = {})
        execute_binary_with_conf('Calibrate', [], iConf, iOptions) do |iStdOUTLog, iStdERRLog, iExitStatus|
          yield(iStdOUTLog, iStdERRLog, iExitStatus)
        end
      end

      # Execute Process in the test environment with the given configuration
      #
      # Parameters::
      # * *iConf* (<em>map<Symbol,Object></em>): Configuration to run with
      # * *iOptions* (<em>map<Symbol,Object></em>): Additional options. See execute_binary for details. [optional = {}]
      # * *CodeBlock*: Code called once it has been executed:
      #   * *iStdOUTLog* (_String_): Log STDOUT of the process
      #   * *iStdERRLog* (_String_): Log STDERR of the process
      #   * *iExitStatus* (_Integer_): Exit status
      def execute_Process_WithConf(iConf, iOptions = {})
        execute_binary_with_conf('Process', [], iConf, iOptions) do |iStdOUTLog, iStdERRLog, iExitStatus|
          yield(iStdOUTLog, iStdERRLog, iExitStatus)
        end
      end

      # Execute Mix in the test environment with the given configuration
      #
      # Parameters::
      # * *iConf* (<em>map<Symbol,Object></em>): Configuration to run with
      # * *iOptions* (<em>map<Symbol,Object></em>): Additional options. See execute_binary for details. [optional = {}]
      # * *CodeBlock*: Code called once it has been executed:
      #   * *iStdOUTLog* (_String_): Log STDOUT of the process
      #   * *iStdERRLog* (_String_): Log STDERR of the process
      #   * *iExitStatus* (_Integer_): Exit status
      def execute_Mix_WithConf(iConf, iOptions = {})
        execute_binary_with_conf('Mix', [], iConf, iOptions) do |iStdOUTLog, iStdERRLog, iExitStatus|
          yield(iStdOUTLog, iStdERRLog, iExitStatus)
        end
      end

      # Execute Deliver in the test environment with the given configuration
      #
      # Parameters::
      # * *iConf* (<em>map<Symbol,Object></em>): Configuration to run with
      # * *iOptions* (<em>map<Symbol,Object></em>): Additional options. See execute_binary for details. [optional = {}]
      # * *CodeBlock*: Code called once it has been executed:
      #   * *iStdOUTLog* (_String_): Log STDOUT of the process
      #   * *iStdERRLog* (_String_): Log STDERR of the process
      #   * *iExitStatus* (_Integer_): Exit status
      def execute_Deliver_WithConf(iConf, iOptions = {})
        execute_binary_with_conf('Deliver', [], iConf, iOptions) do |iStdOUTLog, iStdERRLog, iExitStatus|
          yield(iStdOUTLog, iStdERRLog, iExitStatus)
        end
      end

      # Call some code only if WSK is installed in our current environment
      #
      # Parameters::
      # * _BlockCode_: Code called if WSK is installed
      def ensure_wsk_or_skip
        lSkip = false
        begin
          require 'WSK/Common'
        rescue LoadError
          # WSK is not installed in this environment: skip this test
          lSkip = true
        end
        if (!lSkip)
          yield
        end
      end

      # Get the list of prepared files for the given options
      #
      # Parameters::
      # * *iLstSyms* (<em>list<Symbol></em>): The list of symbols to prepare files for
      # Return::
      # * <em>list< [String,String] ></em>: The list of files to be prepared (couples [source,destination])
      def getPreparedFiles(*iLstSyms)
        rLstFiles = []

        iLstSyms.each do |iSym|
          case iSym
          when :Recorded_Env1_1
            rLstFiles.concat([
              [ 'Wave/01_Source/Record/Env1.Silence.wav', '01_Source/Record/Env1.Silence.wav' ],
              [ 'Wave/01_Source/Record/Env1.1.wav', '01_Source/Record/Env1.1.wav' ]
            ])
          when :Cleaned_Env1_1
            rLstFiles.concat([
              [ 'Analysis/Env1.1.analyze', 'Analyze/Record/Env1.1.analyze' ],
              [ 'Analysis/Env1.Silence.analyze', 'Analyze/Record/Env1.Silence.analyze' ],
              [ 'FFT/Env1.Silence.fftprofile', 'Analyze/Record/Env1.Silence.fftprofile' ],
              [ 'Wave/02_Clean/Record/Env1.1.01.SilenceRemover.wav', '02_Clean/Record/Env1.1.01.SilenceRemover.wav' ],
              [ 'Wave/02_Clean/Record/Env1.1.03.DCShifter.wav', '02_Clean/Record/Env1.1.03.DCShifter.wav' ],
              [ 'Wave/02_Clean/Record/Env1.1.04.NoiseGate.wav', '02_Clean/Record/Env1.1.04.NoiseGate.wav' ]
            ])
          when :Processed_Env1_1
            lProcessID = {
              :Param1 => 'TestParam1'
            }.unique_id
            rLstFiles.concat([
              [ 'Wave/04_Process/Record/Env1.1.04.NoiseGate.0.Test.xxx.wav', "04_Process/Record/Env1.1.04.NoiseGate.0.Test.#{lProcessID}.wav" ]
            ])
          when :Recorded_Env1_2
            rLstFiles.concat([
              [ 'Wave/01_Source/Record/Env1.Silence.wav', '01_Source/Record/Env1.Silence.wav' ],
              [ 'Wave/01_Source/Record/Env1.2.wav', '01_Source/Record/Env1.2.wav' ]
            ])
          when :Recorded_Env1_1_CalibEnv2
            rLstFiles.concat([
              [ 'Wave/01_Source/Record/Env1.Silence.wav', '01_Source/Record/Env1.Silence.wav' ],
              [ 'Wave/01_Source/Record/Env2.Silence.wav', '01_Source/Record/Env2.Silence.wav' ],
              [ 'Wave/01_Source/Record/Env1.1.wav', '01_Source/Record/Env1.1.wav' ],
              [ 'Wave/01_Source/Record/Calibration.Env1.Env2.wav', '01_Source/Record/Calibration.Env1.Env2.wav' ],
              [ 'Wave/01_Source/Record/Calibration.Env2.Env1.wav', '01_Source/Record/Calibration.Env2.Env1.wav' ]
            ])
          when :Cleaned_Env1_1_CalibEnv2
            rLstFiles.concat([
              [ 'Analysis/Env1.1.analyze', 'Analyze/Record/Env1.1.analyze' ],
              [ 'Analysis/Env1.Silence.analyze', 'Analyze/Record/Env1.Silence.analyze' ],
              [ 'FFT/Env1.Silence.fftprofile', 'Analyze/Record/Env1.Silence.fftprofile' ],
              [ 'Analysis/Env2.Silence.analyze', 'Analyze/Record/Env2.Silence.analyze' ],
              [ 'FFT/Env2.Silence.fftprofile', 'Analyze/Record/Env2.Silence.fftprofile' ],
              [ 'Analysis/Calibration.Env1.Env2.analyze', 'Analyze/Record/Calibration.Env1.Env2.analyze' ],
              [ 'Analysis/Calibration.Env2.Env1.analyze', 'Analyze/Record/Calibration.Env2.Env1.analyze' ],
              [ 'Wave/02_Clean/Record/Env1.1.01.SilenceRemover.wav', '02_Clean/Record/Env1.1.01.SilenceRemover.wav' ],
              [ 'Wave/02_Clean/Record/Env1.1.03.DCShifter.wav', '02_Clean/Record/Env1.1.03.DCShifter.wav' ],
              [ 'Wave/02_Clean/Record/Env1.1.04.NoiseGate.wav', '02_Clean/Record/Env1.1.04.NoiseGate.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env1.Env2.01.SilenceRemover.wav', '02_Clean/Record/Calibration.Env1.Env2.01.SilenceRemover.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env1.Env2.02.Cut.0.01s_0.16s.wav', '02_Clean/Record/Calibration.Env1.Env2.02.Cut.0.01s_0.16s.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env1.Env2.03.DCShifter.wav', '02_Clean/Record/Calibration.Env1.Env2.03.DCShifter.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env1.Env2.04.NoiseGate.wav', '02_Clean/Record/Calibration.Env1.Env2.04.NoiseGate.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env2.Env1.01.SilenceRemover.wav', '02_Clean/Record/Calibration.Env2.Env1.01.SilenceRemover.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env2.Env1.02.Cut.0.01s_0.16s.wav', '02_Clean/Record/Calibration.Env2.Env1.02.Cut.0.01s_0.16s.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env2.Env1.03.DCShifter.wav', '02_Clean/Record/Calibration.Env2.Env1.03.DCShifter.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env2.Env1.04.NoiseGate.wav', '02_Clean/Record/Calibration.Env2.Env1.04.NoiseGate.wav' ]
            ])
          when :Calibrated_Env1_1_CalibEnv2
            rLstFiles.concat([
              [ 'Analysis/Calibration.Env1.Env2.04.NoiseGate.analyze', 'Analyze/Record/Calibration.Env1.Env2.04.NoiseGate.analyze' ],
              [ 'Analysis/Calibration.Env2.Env1.04.NoiseGate.analyze', 'Analyze/Record/Calibration.Env2.Env1.04.NoiseGate.analyze' ],
              [ 'Wave/03_Calibrate/Record/Env1.1.Calibrated.wav', '03_Calibrate/Record/Env1.1.Calibrated.wav' ]
            ])
          when :Recorded_Env1_1_CalibEnv3
            rLstFiles.concat([
              [ 'Wave/01_Source/Record/Env1.Silence.wav', '01_Source/Record/Env1.Silence.wav' ],
              [ 'Wave/01_Source/Record/Env3.Silence.wav', '01_Source/Record/Env3.Silence.wav' ],
              [ 'Wave/01_Source/Record/Env1.1.wav', '01_Source/Record/Env1.1.wav' ],
              [ 'Wave/01_Source/Record/Calibration.Env1.Env3.wav', '01_Source/Record/Calibration.Env1.Env3.wav' ],
              [ 'Wave/01_Source/Record/Calibration.Env3.Env1.wav', '01_Source/Record/Calibration.Env3.Env1.wav' ]
            ])
          when :Recorded_Env1_1_CalibEnv4
            rLstFiles.concat([
              [ 'Wave/01_Source/Record/Env1.Silence.wav', '01_Source/Record/Env1.Silence.wav' ],
              [ 'Wave/01_Source/Record/Env4.Silence.wav', '01_Source/Record/Env4.Silence.wav' ],
              [ 'Wave/01_Source/Record/Env1.1.wav', '01_Source/Record/Env1.1.wav' ],
              [ 'Wave/01_Source/Record/Calibration.Env1.Env4.wav', '01_Source/Record/Calibration.Env1.Env4.wav' ],
              [ 'Wave/01_Source/Record/Calibration.Env4.Env1.wav', '01_Source/Record/Calibration.Env4.Env1.wav' ]
            ])
          when :Cleaned_Env1_1_CalibEnv4
            rLstFiles.concat([
              [ 'Analysis/Env1.1.analyze', 'Analyze/Record/Env1.1.analyze' ],
              [ 'Analysis/Env1.Silence.analyze', 'Analyze/Record/Env1.Silence.analyze' ],
              [ 'FFT/Env1.Silence.fftprofile', 'Analyze/Record/Env1.Silence.fftprofile' ],
              [ 'Analysis/Env4.Silence.analyze', 'Analyze/Record/Env4.Silence.analyze' ],
              [ 'FFT/Env4.Silence.fftprofile', 'Analyze/Record/Env4.Silence.fftprofile' ],
              [ 'Analysis/Calibration.Env1.Env4.analyze', 'Analyze/Record/Calibration.Env1.Env4.analyze' ],
              [ 'Analysis/Calibration.Env4.Env1.analyze', 'Analyze/Record/Calibration.Env4.Env1.analyze' ],
              [ 'Wave/02_Clean/Record/Env1.1.01.SilenceRemover.wav', '02_Clean/Record/Env1.1.01.SilenceRemover.wav' ],
              [ 'Wave/02_Clean/Record/Env1.1.03.DCShifter.wav', '02_Clean/Record/Env1.1.03.DCShifter.wav' ],
              [ 'Wave/02_Clean/Record/Env1.1.04.NoiseGate.wav', '02_Clean/Record/Env1.1.04.NoiseGate.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env1.Env4.01.SilenceRemover.wav', '02_Clean/Record/Calibration.Env1.Env4.01.SilenceRemover.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env1.Env4.02.Cut.0.01s_0.16s.wav', '02_Clean/Record/Calibration.Env1.Env4.02.Cut.0.01s_0.16s.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env1.Env4.03.DCShifter.wav', '02_Clean/Record/Calibration.Env1.Env4.03.DCShifter.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env1.Env4.04.NoiseGate.wav', '02_Clean/Record/Calibration.Env1.Env4.04.NoiseGate.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env4.Env1.01.SilenceRemover.wav', '02_Clean/Record/Calibration.Env4.Env1.01.SilenceRemover.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env4.Env1.02.Cut.0.01s_0.16s.wav', '02_Clean/Record/Calibration.Env4.Env1.02.Cut.0.01s_0.16s.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env4.Env1.03.DCShifter.wav', '02_Clean/Record/Calibration.Env4.Env1.03.DCShifter.wav' ],
              [ 'Wave/02_Clean/Record/Calibration.Env4.Env1.04.NoiseGate.wav', '02_Clean/Record/Calibration.Env4.Env1.04.NoiseGate.wav' ]
            ])
          when :Calibrated_Env1_1_CalibEnv4
            rLstFiles.concat([
              [ 'Analysis/Calibration.Env1.Env4.04.NoiseGate.analyze', 'Analyze/Record/Calibration.Env1.Env4.04.NoiseGate.analyze' ],
              [ 'Analysis/Calibration.Env4.Env1.04.NoiseGate.analyze', 'Analyze/Record/Calibration.Env4.Env1.04.NoiseGate.analyze' ]
            ])
          when :Mixed_Wave1
            rLstFiles.concat([
              [ 'Wave/01_Source/Wave/Wave1.wav', 'Wave1.wav' ],
              [ '*Wave1.wav', '05_Mix/Final/Mix1.wav' ]
            ])
          when :Mixed_Wave2
            rLstFiles.concat([
              [ 'Wave/01_Source/Wave/Wave2.wav', 'Wave2.wav' ],
              [ '*Wave2.wav', '05_Mix/Final/Mix2.wav' ]
            ])
          when :Mixed_Wave3
            rLstFiles.concat([
              [ 'Wave/01_Source/Wave/Wave3.wav', 'Wave3.wav' ],
              [ '*Wave3.wav', '05_Mix/Final/Mix3.wav' ]
            ])
          else
            raise "Unknown symbol to prepare files for: #{iSym}"
          end
        end

        return rLstFiles.uniq
      end

      # Get a file name based on a glob directive.
      # Assert that the file is alone and exists.
      #
      # Parameters::
      # * *iStrGlob* (_String_): The glob directive
      # Return::
      # * _String_: File name
      def getFileFromGlob(iStrGlob)
        lLstFiles = Dir.glob(iStrGlob)
        assert_equal 1, lLstFiles.size, "#{lLstFiles.size} files correspond to glob \"#{iStrGlob}\""

        return lLstFiles.first
      end

      # Buffer size used to compare Wave files
      BUFFER_SIZE = 4096
      # Assert that a wave file is the same as a reference one
      #
      # Parameters::
      # * *iReferenceBaseName* (_String_): The reference Wave base name
      # * *iWaveFileName* (_String_): The wave file to check
      def assert_wave(iReferenceBaseName, iWaveFileName)
        assert File.exists?(iWaveFileName), "File #{iWaveFileName} does not exist"
        lRefFileName = "#{MusicMasterTest::getRootPath}/test/Wave/#{iReferenceBaseName}.wav"
        assert_equal File.size(lRefFileName), File.size(iWaveFileName), "File #{iWaveFileName}'s size (#{File.size(iWaveFileName)}) differs from reference file's size (#{iReferenceBaseName}: #{File.size(lRefFileName)})"
        File.open(iWaveFileName, 'r') do |iFile|
          File.open(lRefFileName, 'r') do |iRefFile|
            while (!iFile.eof?)
              lOrgPos = iFile.pos
              assert_equal iRefFile.read(BUFFER_SIZE), iFile.read(BUFFER_SIZE), "File #{iWaveFileName} differs from reference file #{lRefFileName} at segment [#{lOrgPos}-#{iFile.pos-1}]"
            end
          end
        end
      end

      # Assert that a wave file pointed by a link is the same as a reference one
      #
      # Parameters::
      # * *iReferenceBaseName* (_String_): The reference Wave base name
      # * *iWaveFileName* (_String_): The wave file to check
      def assert_wave_lnk(iReferenceBaseName, iWaveFileName)
        lRealFileName = get_shortcut_target(iWaveFileName)
        assert File.exists?(lRealFileName), "File #{lRealFileName}, pointed by shortcut #{iWaveFileName}, does not exist"
        assert_wave iReferenceBaseName, lRealFileName
      end

      # Assert the process' exit status
      # Do the check only for Ruby >= 1.9
      #
      # Parameters::
      # * *iExitStatusRef* (_Integer_): The exit status reference
      # * *iExitStatus* (_Integer_): The real exit status
      def assert_exitstatus(iExitStatusRef, iExitStatus)
        assert_equal(iExitStatusRef, iExitStatus) if (RUBY_VERSION >= '1.9')
      end

      # Assert the content of an evaluated rb file
      #
      # Parameters::
      # * *iExpectedContent* (_Object_): The expected content
      # * *iFileName* (_String_): The file to check content from
      def assert_rb_content(iExpectedContent, iFileName)
        assert File.exists?(iFileName), "File #{iFileName} does not exist"
        assert_equal iExpectedContent, eval(File.read(iFileName))
      end

    end

  end

end

module MusicMasterTest

  # Are we debugging tests ?
  #
  # Return::
  # * _Boolean_: Are we debugging tests ?
  def self.debug?
    return $MusicMasterTest_Debug
  end

  # Get a temporary directory
  #
  # Parameters::
  # * *iID* (_String_): ID to be used to identify this temporary directory [optional = nil]
  # Return::
  # * _String_: The temporary directory
  def self.getTmpDir(iID = nil)
    rTmpDir = "#{Dir.tmpdir}/MusicMasterTest"

    rTmpDir.concat("/#{iID}") if (iID != nil)

    return rTmpDir
  end

end
