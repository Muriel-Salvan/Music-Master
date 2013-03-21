#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

gem 'rake', '>= 0.9'
require 'rake'

require 'rUtilAnts/Platform'
RUtilAnts::Platform.install_platform_on_object
require 'rUtilAnts/Misc'
RUtilAnts::Misc.install_misc_on_object
require 'MusicMaster/Symbol'
require 'MusicMaster/Task'

module MusicMaster

  module RakeProcesses

    class UnknownTrackIDError < RuntimeError
    end

    include Rake::DSL

    # Initialize variables used by rake processes
    #
    # Parameters::
    # * *iOptions* (<em>map<Symbol,Object></em>): First set of options [optional = {}]
    def initialize_RakeProcesses(iOptions = {})
      # The context: this will be shared across Rake tasks and this code.
      # map< Symbol, Object >
      # * *:EnvsToCalibrate* (<em>map< [Symbol,Symbol],nil ></em>): The set of environments pairs to calibrate
      # * *:CleanFiles* (<em>map<String,map<Symbol,Object>></em>: Data associated to a recorded file that will be cleaned, per recorded file base name (without extension):
      #   * *:FramedFileName* (_String_): Name of the recorded file once framed
      #   * *:DCRemovedFileName* (_String_): Name of the file without DC offset
      #   * *:NoiseGatedFileName* (_String_): Name of the file with noise gate applied
      #   * *:SilenceAnalysisFileName* (_String_): Name of the file containing analysis of the corresponding silence recording
      #   * *:SilenceFFTProfileFileName* (_String_): Name of the file containing FFT profile of the corresponding silence recording
      # * *:RakeSetupFor_GenerateSourceFiles* (_Boolean_): Have the rules for GenerateSourceFiles been created ?
      # * *:RakeSetupFor_CleanRecordings* (_Boolean_): Have the rules for CleanRecordings been created ?
      # * *:RakeSetupFor_CalibrateRecordings* (_Boolean_): Have the rules for CalibrateRecordings been created ?
      # * *:RakeSetupFor_ProcessSourceFiles* (_Boolean_): Have the rules for ProcessSourceFiles been created ?
      # * *:RakeSetupFor_Mix* (_Boolean_): Have the rules for Mix been created ?
      # * *:Calibrate* (<em>map<String,map<Symbol,Object>></em>): Data associated to a calibrated file, per recorded file base name (without extension):
      #   * *:FinalTask* (_Symbol_): Name of the final calibration task
      #   * *:CalibratedFileName* (_String_): Name of the calibrated file
      # * *:CalibrationAnalysisFiles* (<em>map< [Symbol,Symbol],String ></em>): Name of the calibration analysis files, per environment pair [ReferenceEnv, RecordingEnv]
      # * *:Processes* (<em>map<String,map<Symbol,Object>></em>): Data associated to a process chain, per recorded file base name (without extension):
      #   * *:LstProcesses* (<em>list<map<Symbol,Object>></em>): List of processes to apply to this recording
      #   * *:FinalTask* (_Symbol_): Name of the final process task
      # * *:WaveProcesses* (<em>map<String,map<Symbol,Object>></em>): Data associated to a process chain, per Wave name (from the config file):
      #   * *:LstProcesses* (<em>list<map<Symbol,Object>></em>): List of processes to apply to this Wave file
      #   * *:FinalTask* (_Symbol_): Name of the final process task
      # * *:RecordedFilesPrepared* (_Boolean_): Recorded files are already prepared: no need to wait for user input while recording.
      # * *:LstEnvToRecord* (<em>list<Symbol></em>): The list of recording environments to record. An empty list means all environments.
      # * *:LstMixNames* (_String_): Names of the mix to produce. Can be empty to produce all mixes.
      # * *:LstDeliverNames* (_String_): Names of the deliverables to produce. Can be empty to produce all deliverables.
      # * *:FinalMixSources* (<em>map<Object,Symbol></em>): List of all tasks defining source files, per mix TrackID
      # * *:DeliverableConf* (<em>map<String,[map<Symbol,Object>,map<Symbol,Object>]></em>): The deliverable information, per deliverable file name: [FormatConfig, Metadata]
      # * *:Deliverables* (<em>map<String,map<Symbol,Object>></em>): Data associated to a deliverable, per deliverable name (from the config file):
      #   * *:FileName* (_String_): The real deliverable file name
      @Context = {
        :EnvsToCalibrate => {},
        :CleanFiles => {},
        :RakeSetupFor_GenerateSourceFiles => false,
        :RakeSetupFor_CleanRecordings => false,
        :RakeSetupFor_CalibrateRecordings => false,
        :RakeSetupFor_ProcessSourceFiles => false,
        :Calibrate => {},
        :CalibrationAnalysisFiles => {},
        :Processes => {},
        :WaveProcesses => {},
        :RecordedFilesPrepared => false,
        :LstEnvToRecord => [],
        :LstMixNames => [],
        :LstDeliverableNames => [],
        :FinalMixSources => {},
        :DeliverableConf => {},
        :Deliverables => {}
      }.merge(iOptions)
    end

    # Display rake tasks
    # This is useful for debugging purposes
    def displayRakeTasks
      Rake.application.tasks.each do |iTask|
        log_info   "+-#{iTask.name}: #{iTask.comment}"
        iTask.prerequisites.each do |iPrerequisiteTaskName|
          log_info "| +-#{iPrerequisiteTaskName}"
        end
        log_info   '|'
      end
    end

    # Generate rake targets for generating source files
    def generateRakeFor_GenerateSourceFiles
      lLstGlobalRecordTasks = []

      # 1. Recordings
      lRecordingsConf = @RecordConf[:Recordings]
      if (lRecordingsConf != nil)
        # Generate recordings rules
        # Gather the recording environments and their respective file names to produce
        # map< Symbol, list< String > >
        lRecordings = {}
        lTracksConf = lRecordingsConf[:Tracks]
        if (lTracksConf != nil)
          lTracksConf.each do |iLstTracks, iRecordingConf|
            lEnv = iRecordingConf[:Env]
            lRecordedFileName = getRecordedFileName(lEnv, iLstTracks)

            desc "Raw recording of tracks #{iLstTracks.sort.join(', ')} in recording environment #{lEnv}"
            file lRecordedFileName do |iTask|
              # Raw recording task
              record(iTask.name, @Context[:RecordedFilesPrepared])
            end

            if (lRecordings[lEnv] == nil)
              lRecordings[lEnv] = []
            end
            lRecordings[lEnv] << lRecordedFileName
            # If there is a need of calibration, record also the calibration files
            if (iRecordingConf[:CalibrateWithEnv] != nil)
              lReferenceEnv = iRecordingConf[:CalibrateWithEnv]
              [
                [ lReferenceEnv, lEnv ],
                [ lEnv, lReferenceEnv ]
              ].each do |iEnvPair|
                iRefEnv, iRecEnv = iEnvPair
                lCalibrationFileName = getRecordedCalibrationFileName(iRefEnv, iRecEnv)
                if (lRecordings[iRecEnv] == nil)
                  lRecordings[iRecEnv] = []
                end
                if (!lRecordings[iRecEnv].include?(lCalibrationFileName))

                  desc "Calibration recording in recording environment #{iRecEnv} to be compared with reference environment #{iRefEnv}"
                  file lCalibrationFileName do |iTask|
                    record(iTask.name, @Context[:RecordedFilesPrepared])
                  end

                  lRecordings[iRecEnv] << lCalibrationFileName
                end
              end
              @Context[:EnvsToCalibrate][[ lReferenceEnv, lEnv ].sort] = nil
            end
          end
        end
        # Make the task recording in the correct order
        lSortedEnv = lRecordingsConf[:EnvRecordingOrder] || []
        lRecordings.sort do
          |iElem1, iElem2|
          if (iElem2[1].size == iElem1[1].size)
            next iElem1[0] <=> iElem2[0]
          else
            next iElem2[1].size <=> iElem1[1].size
          end
        end.each do |iElem|
          if (!lSortedEnv.include?(iElem[0]))
            lSortedEnv << iElem[0]
          end
        end
        lLstTasks = []
        lSortedEnv.each do |iEnv|
          lLstFiles = lRecordings[iEnv]
          if (lLstFiles != nil)
            # Record a silence file
            lSilenceFile = getRecordedSilenceFileName(iEnv)

            desc "Record silence file for recording environment #{iEnv}"
            file lSilenceFile do |iTask|
              # Raw recording task
              record(iTask.name, @Context[:RecordedFilesPrepared])
            end

            lSymTask = "Record_#{iEnv}".to_sym

            desc "Record all files for recording environment #{iEnv}"
            task lSymTask => lLstFiles + [lSilenceFile]

            lLstTasks << lSymTask if (@Context[:LstEnvToRecord].empty?) or (@Context[:LstEnvToRecord].include?(iEnv))
          end
        end

        desc 'Record all files'
        task :Record => lLstTasks

        lLstGlobalRecordTasks << :Record
      end

      # 2. Wave files
      lWaveFilesConf = @RecordConf[:WaveFiles]
      if (lWaveFilesConf != nil)
        # Generate wave files rules
        lLstWaveFiles = []
        lWaveFilesConf[:FilesList].map { |iFileInfo| iFileInfo[:Name] }.each do |iFileName|
          lWaveFileName = getWaveSourceFileName(iFileName)
          if (!File.exists?(iFileName))

            desc "Generate wave file #{iFileName}"
            file lWaveFileName do |iTask|
              puts "Create Wave file #{iTask.name}, and press Enter when done."
              $stdin.gets
            end

          end
          lLstWaveFiles << lWaveFileName
        end

        desc 'Generate all wave files'
        task :GenerateWaveFiles => lLstWaveFiles

        lLstGlobalRecordTasks << :GenerateWaveFiles
      end

      desc 'Generate source files (both recording and Wave files)'
      task :GenerateSourceFiles => lLstGlobalRecordTasks

      @Context[:RakeSetupFor_GenerateSourceFiles] = true
    end

    # Generate rake targets for cleaning recorded files
    def generateRakeFor_CleanRecordings
      if (!@Context[:RakeSetupFor_GenerateSourceFiles])
        generateRakeFor_GenerateSourceFiles
      end

      # List of cleaning tasks
      # list< Symbol >
      lLstCleanTasks = []
      lRecordingsConf = @RecordConf[:Recordings]
      if (lRecordingsConf != nil)
        lTracksConf = lRecordingsConf[:Tracks]
        if (lTracksConf != nil)
          # Look for recorded files
          lTracksConf.each do |iLstTracks, iRecordingConf|
            lEnv = iRecordingConf[:Env]
            lRecordedFileName = getRecordedFileName(lEnv, iLstTracks)
            lRecordedBaseName = File.basename(lRecordedFileName[0..-5])
            # Clean the recorded file itself
            lLstCleanTasks << generateRakeForCleaningRecordedFile(lRecordedBaseName, lEnv)
          end
          # Look for calibration files
          @Context[:EnvsToCalibrate].each do |iEnvToCalibratePair, iNil|
            iEnv1, iEnv2 = iEnvToCalibratePair
            # Read the cutting values if any from the conf
            lCutInfo = nil
            if (lRecordingsConf[:EnvCalibration] != nil)
              lRecordingsConf[:EnvCalibration].each do |iEnvPair, iCalibrationInfo|
                if (iEnvPair.sort == iEnvToCalibratePair)
                  # Found it
                  lCutInfo = iCalibrationInfo[:CompareCuts]
                  break
                end
              end
            end
            # Clean the calibration files
            lReferenceFileName = getRecordedCalibrationFileName(iEnv1, iEnv2)
            lLstCleanTasks << generateRakeForCleaningRecordedFile(File.basename(lReferenceFileName)[0..-5], iEnv2, lCutInfo)
            lRecordingFileName = getRecordedCalibrationFileName(iEnv2, iEnv1)
            lLstCleanTasks << generateRakeForCleaningRecordedFile(File.basename(lRecordingFileName)[0..-5], iEnv1, lCutInfo)
          end
        end
      end

      desc 'Clean all recorded files: remove silences, cut them, remove DC offset and apply noise gate'
      task :CleanRecordings => lLstCleanTasks.sort.uniq

      @Context[:RakeSetupFor_CleanRecordings] = true
    end

    # Generate rake targets for calibrating recorded files
    def generateRakeFor_CalibrateRecordings
      if (!@Context[:RakeSetupFor_CleanRecordings])
        generateRakeFor_CleanRecordings
      end

      # List of calibrating tasks
      # list< Symbol >
      lLstCalibrateTasks = []
      lRecordingsConf = @RecordConf[:Recordings]
      if (lRecordingsConf != nil)
        lTracksConf = lRecordingsConf[:Tracks]
        if (lTracksConf != nil)
          # Generate analysis files for calibration files
          @Context[:EnvsToCalibrate].each do |iEnvToCalibratePair, iNil|
            [
              [ iEnvToCalibratePair[0], iEnvToCalibratePair[1] ],
              [ iEnvToCalibratePair[1], iEnvToCalibratePair[0] ]
            ].each do |iEnvPair|
              iEnv1, iEnv2 = iEnvPair
              lCalibrationFileName = getRecordedCalibrationFileName(iEnv1, iEnv2)
              lNoiseGatedFileName = @Context[:CleanFiles][File.basename(lCalibrationFileName)[0..-5]][:NoiseGatedFileName]
              lAnalysisFileName = getRecordedAnalysisFileName(File.basename(lNoiseGatedFileName)[0..-5])
              @Context[:CalibrationAnalysisFiles][iEnvPair] = lAnalysisFileName

              desc "Generate analysis for framed calibration file #{lNoiseGatedFileName}"
              file lAnalysisFileName => lNoiseGatedFileName do |iTask|
                analyzeFile(iTask.prerequisites[0], iTask.name)
              end

            end
          end

          # Generate calibrated files
          lTracksConf.each do |iLstTracks, iRecordingConf|
            if (iRecordingConf[:CalibrateWithEnv] != nil)
              # Need calibration
              lRecEnv = iRecordingConf[:Env]
              lRefEnv = iRecordingConf[:CalibrateWithEnv]
              lRecordedBaseName = File.basename(getRecordedFileName(lRecEnv, iLstTracks))[0..-5]
              # Create the data target that stores the comparison of analysis files for calibration
              lCalibrationInfoTarget = "#{lRecordedBaseName}.Calibration.info".to_sym

              desc "Compare the analysis of calibration files for recording #{lRecordedBaseName}"
              task lCalibrationInfoTarget => [
                @Context[:CalibrationAnalysisFiles][[lRefEnv,lRecEnv]],
                @Context[:CalibrationAnalysisFiles][[lRecEnv,lRefEnv]]
              ] do |iTask|
                iRecordingCalibrationAnalysisFileName, iReferenceCalibrationAnalysisFileName = iTask.prerequisites
                # Compute the distance between the 2 average RMS values
                lRMSReference = getRMSValue(iReferenceCalibrationAnalysisFileName)
                lRMSRecording = getRMSValue(iRecordingCalibrationAnalysisFileName)
                log_info "Reference environment #{lRefEnv} - RMS: #{lRMSReference}"
                log_info "Recording environment #{lRecEnv} - RMS: #{lRMSRecording}"
                iTask.data = {
                  :RMSReference => lRMSReference,
                  :RMSRecording => lRMSRecording,
                  :MaxValue => getAnalysis(iRecordingCalibrationAnalysisFileName)[:MinPossibleValue].abs
                }
              end

              # Create the dependency task
              lDependenciesTask = "Dependencies_Calibration_#{lRecordedBaseName}".to_sym

              desc "Compute dependencies to know if we need to calibrate tracks [#{iLstTracks.join(', ')}] recording."
              task lDependenciesTask => lCalibrationInfoTarget do |iTask|
                lCalibrationInfo = Rake::Task[iTask.prerequisites.first].data
                # If the RMS values are different, we need to generate the calibrated file
                lRecordedBaseName2 = iTask.name.match(/^Dependencies_Calibration_(.*)$/)[1]
                lCalibrateContext = @Context[:Calibrate][lRecordedBaseName2]
                lLstPrerequisitesFinalTask = [iTask.name]
                if (lCalibrationInfo[:RMSRecording] != lCalibrationInfo[:RMSReference])
                  # Make the final task depend on the calibrated file
                  lLstPrerequisitesFinalTask << lCalibrateContext[:CalibratedFileName]
                  # Create the target that will generate the calibrated file.

                  desc "Generate calibrated recording for #{lRecordedBaseName2}"
                  file @Context[:Calibrate][lRecordedBaseName2][:CalibratedFileName] => [
                    @Context[:CleanFiles][lRecordedBaseName2][:NoiseGatedFileName],
                    lCalibrationInfoTarget
                  ] do |iTask2|
                    iRecordedFileName, iCalibrationInfoTarget = iTask2.prerequisites
                    lCalibrationInfo = Rake::Task[iCalibrationInfoTarget].data
                    # If the Recording is louder, apply a volume reduction
                    if (lCalibrationInfo[:RMSRecording] < lCalibrationInfo[:RMSReference])
                      # Here we are loosing quality: we need to increase the recording volume.
                      # Notify the user about it.
                      lDBValue, lPCValue = val2db(lCalibrationInfo[:RMSReference]-lCalibrationInfo[:RMSRecording], lCalibrationInfo[:MaxValue])
                      log_warn "Tracks [#{iLstTracks.join(', ')}] should be recorded louder (at least #{lDBValue} db <=> #{lPCValue} %)."
                    end
                    wsk(iRecordedFileName, iTask2.name, 'Multiply', "--coeff \"#{lCalibrationInfo[:RMSReference]}/#{lCalibrationInfo[:RMSRecording]}\"")
                  end

                end
                Rake::Task[lCalibrateContext[:FinalTask]].prerequisites.replace(lLstPrerequisitesFinalTask)
              end

              # Make the final task depend on this dependency task
              lCalibrateFinalTask = "Calibrate_#{iLstTracks.join('_')}".to_sym
              lLstCalibrateTasks << lCalibrateFinalTask
              @Context[:Calibrate][lRecordedBaseName] = {
                :FinalTask => lCalibrateFinalTask,
                :CalibratedFileName => getCalibratedFileName(lRecordedBaseName)
              }

              desc "Calibrate tracks [#{iLstTracks.join(', ')}] recording."
              task lCalibrateFinalTask => lDependenciesTask

            end
          end

        end
      end
      # Generate global task

      desc 'Calibrate recordings needing it'
      task :CalibrateRecordings => lLstCalibrateTasks

      @Context[:RakeSetupFor_CalibrateRecordings] = true
    end

    # Generate rake targets for processing source files
    def generateRakeFor_ProcessSourceFiles
      if (!@Context[:RakeSetupFor_CalibrateRecordings])
        generateRakeFor_CalibrateRecordings
      end

      # List of process tasks
      # list< Symbol >
      lLstProcessTasks = []

      # 1. Handle recordings
      lRecordingsConf = @RecordConf[:Recordings]
      if (lRecordingsConf != nil)
        # Read global processes and environment processes to be applied before and after recordings
        lGlobalProcesses_Before = lRecordingsConf[:GlobalProcesses_Before] || []
        lGlobalProcesses_After = lRecordingsConf[:GlobalProcesses_After] || []
        lEnvProcesses_Before = lRecordingsConf[:EnvProcesses_Before] || {}
        lEnvProcesses_After = lRecordingsConf[:EnvProcesses_After] || {}
        lTracksConf = lRecordingsConf[:Tracks]
        if (lTracksConf != nil)
          lTracksConf.each do |iLstTracks, iRecordingConf|
            lRecEnv = iRecordingConf[:Env]
            # Compute the list of processes to apply
            lEnvProcesses_RecordingBefore = lEnvProcesses_Before[lRecEnv] || []
            lEnvProcesses_RecordingAfter = lEnvProcesses_After[lRecEnv] || []
            lRecordingProcesses = iRecordingConf[:Processes] || []
            # Optimize the list
            lLstProcesses = optimizeProcesses(lGlobalProcesses_Before + lEnvProcesses_RecordingBefore + lRecordingProcesses + lEnvProcesses_RecordingAfter + lGlobalProcesses_After)
            # Get the file name to apply processes to
            lRecordedBaseName = File.basename(getRecordedFileName(lRecEnv, iLstTracks))[0..-5]
            # Create the target that gives the name of the final wave file, and make it depend on the Calibration.Info target only if calibration might be needed
            lPrerequisites = []
            lPrerequisites << "#{lRecordedBaseName}.Calibration.info".to_sym if (iRecordingConf[:CalibrateWithEnv] != nil)
            lFinalBeforeMixTarget = "FinalBeforeMix_Recording_#{lRecordedBaseName}".to_sym

            desc "Get final wave file name for recording #{lRecordedBaseName}"
            task lFinalBeforeMixTarget => lPrerequisites do |iTask|
              lRecordedBaseName2 = iTask.name.match(/^FinalBeforeMix_Recording_(.*)$/)[1]
              # Get the name of the file that may be processed
              # Set the cleaned file as a default
              lFileNameToProcess = getNoiseGateFileName(lRecordedBaseName2)
              if (!iTask.prerequisites.empty?)
                lCalibrationInfo = Rake::Task[iTask.prerequisites.first].data
                if (lCalibrationInfo[:RMSReference] != lCalibrationInfo[:RMSRecording])
                  # Apply processes on the calibrated file
                  lFileNameToProcess = getCalibratedFileName(lRecordedBaseName2)
                end
              end
              # By default, the final name is the one to be processed
              lFinalFileName = lFileNameToProcess
              # Get the list of processes from the context
              if (@Context[:Processes][lRecordedBaseName2] != nil)
                # Processing has to be performed
                # Now generate the whole branch of targets to process the choosen file
                lFinalFileName = generateRakeForProcesses(@Context[:Processes][lRecordedBaseName2][:LstProcesses], lFileNameToProcess, getProcessesRecordDir)
              end
              iTask.data = {
                :FileName => lFinalFileName
              }
            end

            if (!lLstProcesses.empty?)
              # Generate the Dependencies task, and make it depend on the target creating the processing chain
              lDependenciesTask = "Dependencies_ProcessRecord_#{lRecordedBaseName}".to_sym

              desc "Create the targets needed to process tracks [#{iLstTracks.join(', ')}]"
              task lDependenciesTask => lFinalBeforeMixTarget do |iTask|
                lRecordedBaseName2 = iTask.name.match(/^Dependencies_ProcessRecord_(.*)$/)[1]
                # Make the final task depend on the processed file
                Rake::Task[@Context[:Processes][lRecordedBaseName2][:FinalTask]].prerequisites.replace([
                  iTask.name,
                  Rake::Task[iTask.prerequisites.first].data[:FileName]
                ])
              end

              # Make the final task depend on the Dependencies task only for the beginning
              lFinalTask = "ProcessRecord_#{iLstTracks.join('_')}".to_sym
              lLstProcessTasks << lFinalTask

              desc "Apply processes to recording #{lRecordedBaseName}"
              task lFinalTask => lDependenciesTask

              @Context[:Processes][lRecordedBaseName] = {
                :LstProcesses => lLstProcesses,
                :FinalTask => lFinalTask
              }
            end
          end
        end
      end

      # 2. Handle Wave files
      lWaveFilesConf = @RecordConf[:WaveFiles]
      if (lWaveFilesConf != nil)
        lGlobalProcesses_Before = lWaveFilesConf[:GlobalProcesses_Before] || []
        lGlobalProcesses_After = lWaveFilesConf[:GlobalProcesses_After] || []
        lLstWaveInfo = lWaveFilesConf[:FilesList]
        if (lLstWaveInfo != nil)
          lLstWaveInfo.each do |iWaveInfo|
            lWaveProcesses = iWaveInfo[:Processes] || []
            if (iWaveInfo[:Position] != nil)
              lWaveProcesses << {
                :Name => 'SilenceInserter',
                :Begin => iWaveInfo[:Position],
                :End => 0
              }
            end
            # Optimize the list
            lLstProcesses = optimizeProcesses(lGlobalProcesses_Before + lWaveProcesses + lGlobalProcesses_After)
            lFinalBeforeMixTarget = "FinalBeforeMix_Wave_#{iWaveInfo[:Name]}"

            desc "Get final wave file name for Wave #{iWaveInfo[:Name]}"
            task lFinalBeforeMixTarget do |iTask|
              lWaveName = iTask.name.match(/^FinalBeforeMix_Wave_(.*)$/)[1]
              # By default, use the original Wave file
              lFinalFileName = getWaveSourceFileName(lWaveName)
              if (@Context[:WaveProcesses][lWaveName] != nil)
                # Generate rake tasks for processing the clean recorded file.
                lFinalFileName = generateRakeForProcesses(@Context[:WaveProcesses][lWaveName][:LstProcesses], lFinalFileName, getProcessesWaveDir)
              end
              iTask.data = {
                :FileName => lFinalFileName
              }
            end

            if (!lLstProcesses.empty?)
              # Generate the Dependencies task, and make it depend on the target creating the processing chain
              lDependenciesTask = "Dependencies_ProcessWave_#{iWaveInfo[:Name]}".to_sym

              desc "Create the targets needed to process Wave #{iWaveInfo[:Name]}"
              task lDependenciesTask => lFinalBeforeMixTarget do |iTask|
                lWaveName = iTask.name.match(/^Dependencies_ProcessWave_(.*)$/)[1]
                # Make the final task depend on the processed file
                Rake::Task[@Context[:WaveProcesses][lWaveName][:FinalTask]].prerequisites.replace([
                  iTask.name,
                  Rake::Task[iTask.prerequisites.first].data[:FileName]
                ])
              end

              # Make the final task depend on the Dependencies task only for the beginning
              lFinalTask = "ProcessWave_#{iWaveInfo[:Name]}".to_sym
              lLstProcessTasks << lFinalTask

              desc "Apply processes to Wave #{iWaveInfo[:Name]}"
              task lFinalTask => lDependenciesTask

              @Context[:WaveProcesses][iWaveInfo[:Name]] = {
                :LstProcesses => lLstProcesses,
                :FinalTask => lFinalTask
              }
            end
          end
        end
      end

      # 3. Generate global task

      desc 'Process source files'
      task :ProcessSourceFiles => lLstProcessTasks

      @Context[:RakeSetupFor_ProcessSourceFiles] = true
    end

    # Generate rake targets for the mix
    def generateRakeFor_Mix
      if (!@Context[:RakeSetupFor_ProcessSourceFiles])
        generateRakeFor_ProcessSourceFiles
      end

      lMixConf = @RecordConf[:Mix]
      if (lMixConf != nil)

        # Create a map of all possible TrackIDs, with their corresponding target containing the file name as part of its data
        # map< Object, Symbol >
        lFinalSources = {}
        lRecordingsConf = @RecordConf[:Recordings]
        if (lRecordingsConf != nil)
          lTracksConf = lRecordingsConf[:Tracks]
          if (lTracksConf != nil)
            lTracksConf.each do |iLstTracks, iTrackInfo|
              associateSourceTarget(iLstTracks, iTrackInfo, "FinalBeforeMix_Recording_#{File.basename(getRecordedFileName(iTrackInfo[:Env], iLstTracks))[0..-5]}".to_sym, lFinalSources)
            end
          end
        end
        lWaveConf = @RecordConf[:WaveFiles]
        if (lWaveConf != nil)
          lFilesList = lWaveConf[:FilesList]
          if (lFilesList != nil)
            lFilesList.each do |iWaveInfo|
              associateSourceTarget(iWaveInfo[:Name], iWaveInfo, "FinalBeforeMix_Wave_#{iWaveInfo[:Name]}".to_sym, lFinalSources)
            end
          end
        end
        lMixConf.each do |iMixName, iMixInfo|
          associateSourceTarget(iMixName, iMixInfo, "FinalMix_#{iMixName}".to_sym, lFinalSources)
        end
        log_debug "List of mix final sources:\n#{lFinalSources.pretty_inspect}"

        # Use this info to generate needed targets
        lLstTargets = []
        lMixConf.keys.sort.each do |iMixName|
          lLstTargets << generateRakeForMix(iMixName, lFinalSources) if (@Context[:LstMixNames].empty?) or (@Context[:LstMixNames].include?(iMixName))
        end

        desc 'Produce all mixes'
        task :Mix => lLstTargets

        @Context[:FinalMixSources] = lFinalSources
      end

      @Context[:RakeSetupFor_Mix] = true
    end

    # Generate rake targets for the deliverables
    def generateRakeFor_Deliver
      if (!@Context[:RakeSetupFor_Mix])
        generateRakeFor_Mix
      end
      lLstTargets = []
      lDeliverConf = @RecordConf[:Deliver]
      if (lDeliverConf != nil)
        lDeliverablesConf = lDeliverConf[:Deliverables]
        if (lDeliverablesConf != nil)
          # Use this info to generate needed targets
          lDeliverablesConf.keys.sort.each do |iDeliverableName|
            lLstTargets << generateRakeForDeliver(iDeliverableName) if (@Context[:LstDeliverableNames].empty?) or (@Context[:LstDeliverableNames].include?(iDeliverableName))
          end
        end
      end

      desc 'Produce all deliverables'
      task :Deliver => lLstTargets

    end

    private

    # Associate a given name and associated info to a given target.
    # Take the map to complete as a parameter.
    #
    # Parameters::
    # * *iInitialID* (_Object_): Initial ID to be associated
    # * *iInfo* (<em>map<Symbol,Object></em>): Info associated to the initial ID, that can be used to get aliases
    # * *iTargetName* (_Symbol_): Target to associate the ID and its aliases to
    # * *oFinalSources* (<em>map<Object,Symbol></em>): The map to complete with the associations
    def associateSourceTarget(iInitialID, iInfo, iTargetName, oFinalSources)
      # Get aliases
      lNames = [ iInitialID ]
      if (iInfo[:Alias] != nil)
        if (iInfo[:Alias].is_a?(Array))
          lNames.concat(iInfo[:Alias])
        else
          lNames << iInfo[:Alias]
        end
      end
      lNames.each do |iName|
        oFinalSources[iName] = iTargetName
      end
    end

    # Generate rake targets to clean a recorded file
    #
    # Parameters::
    # * *iBaseName* (_String_): The base name (without extension) of the recorded file
    # * *iEnv* (_Symbol_): The environment in which this file has been recorded
    # * *iCutInfo* (<em>[String,String]</em>): The cut information, used to extract only a part of the file (begin and end markers, in seconds or samples) [optional = nil]
    # Return::
    # * _Symbol_: Name of the entering task for this generation process
    def generateRakeForCleaningRecordedFile(iBaseName, iEnv, iCutInfo = nil)
      # 1. Create all needed analysis files
      lRecordedSilenceFileName = getRecordedSilenceFileName(iEnv)
      lRecordedSilenceBaseName = File.basename(lRecordedSilenceFileName)[0..-5]

      lAnalyzeSilenceFileName = getRecordedAnalysisFileName(lRecordedSilenceBaseName)
      if (!Rake::Task.task_defined?(lAnalyzeSilenceFileName))

        desc "Generate analysis of silence file for environment #{iEnv}"
        file lAnalyzeSilenceFileName => lRecordedSilenceFileName do |iTask|
          analyzeFile(iTask.prerequisites[0], iTask.name)
        end

      end
      lFFTProfileSilenceFileName = getRecordedFFTProfileFileName(lRecordedSilenceBaseName)
      if (!Rake::Task.task_defined?(lFFTProfileSilenceFileName))

        desc "Generate FFT profile of silence file for environment #{iEnv}"
        file lFFTProfileSilenceFileName => lRecordedSilenceFileName do |iTask|
          fftProfileFile(iTask.prerequisites[0], iTask.name)
        end

      end
      lAnalyzeRecordedFileName = getRecordedAnalysisFileName(iBaseName)
      lRecordedFileName = "#{getRecordedDir}/#{iBaseName}.wav"

      desc "Generate analysis of file #{lRecordedFileName}"
      file lAnalyzeRecordedFileName => lRecordedFileName do |iTask|
        analyzeFile(iTask.prerequisites[0], iTask.name)
      end

      # 2. Remove silences from the beginning and the end
      lSilenceRemovedFileName = getSilenceRemovedFileName(iBaseName)

      desc "Remove silences from beginning and end of file #{lRecordedFileName}"
      file lSilenceRemovedFileName => [ lRecordedFileName, lAnalyzeRecordedFileName, lFFTProfileSilenceFileName, lAnalyzeSilenceFileName ] do |iTask|
        iRecordedFileName, iAnalyzeRecordedFileName, iFFTProfileSilenceFileName, iAnalyzeSilenceFileName = iTask.prerequisites

        # Get DC offset from the recorded file
        _, lDCOffsets = getDCOffsets(iAnalyzeRecordedFileName)
        # Get thresholds (without DC offsets) from the silence file
        lSilenceThresholds = getThresholds(iAnalyzeSilenceFileName, :margin => @MusicMasterConf[:Clean][:MarginSilenceThresholds])
        # Get the thresholds with the recorded DC offset, and prepare them to be given to wsk
        lLstStrSilenceThresholdsWithDC = shiftThresholdsByDCOffset(lSilenceThresholds, lDCOffsets).map { |iSilenceThresholdInfo| iSilenceThresholdInfo.join(',') }

        # Call wsk
        wsk(iRecordedFileName, iTask.name, 'SilenceRemover', "--silencethreshold \"#{lLstStrSilenceThresholdsWithDC.join('|')}\" --attack 0 --release #{@MusicMasterConf[:Clean][:SilenceMin]} --noisefft \"#{iFFTProfileSilenceFileName}\"")
      end

      # Cut the file if needed
      lFramedFileName = nil
      if (iCutInfo == nil)
        lFramedFileName = lSilenceRemovedFileName
      else
        lFramedFileName = getCutFileName(iBaseName, iCutInfo)

        desc "Extract sample [#{iCutInfo.join(', ')}] from file #{lSilenceRemovedFileName}"
        file lFramedFileName => lSilenceRemovedFileName do |iTask|
          wsk(iTask.prerequisites.first, iTask.name, 'Cut', "--begin \"#{iCutInfo[0]}\" --end \"#{iCutInfo[1]}\"")
        end

      end
      lDCRemovedFileName = getDCRemovedFileName(iBaseName)
      # Create a target that will change the dependencies of the noise gate dynamically
      lNoiseGatedFileName = getNoiseGateFileName(iBaseName)
      lDependenciesNoiseGateTaskName = "Dependencies_NoiseGate_#{iBaseName}".to_sym

      desc "Compute NoiseGate dependencies for file #{lNoiseGatedFileName}"
      task lDependenciesNoiseGateTaskName => lAnalyzeRecordedFileName do |iTask|
        # Get the basename from the task name
        lBaseName = iTask.name.match(/^Dependencies_NoiseGate_(.*)$/)[1]
        lRecordedAnalysisFileName = iTask.prerequisites.first
        # Get DC offset from the recorded file
        lOffset, lDCOffsets = getDCOffsets(lRecordedAnalysisFileName)
        lSourceFileName = nil
        if (lOffset)
          log_debug "Noise gated file #{lNoiseGatedFileName} will depend on a DC shifted recording. DC offsets: #{lDCOffsets.inspect}"
          lSourceFileName = @Context[:CleanFiles][lBaseName][:DCRemovedFileName]
          # Create the corresponding task removing the DC offset

          desc "Remove DC offset from file #{lRecordedAnalysisFileName}"
          file lSourceFileName => [ lRecordedAnalysisFileName, @Context[:CleanFiles][lBaseName][:FramedFileName] ] do |iDCRemoveTask|
            iRecordedAnalysisFileName, iFramedFileName = iDCRemoveTask.prerequisites
            _, lDCOffsets2 = getDCOffsets(iRecordedAnalysisFileName)
            wsk(iFramedFileName, iDCRemoveTask.name, 'DCShifter', "--offset \"#{lDCOffsets2.map { |iValue| -iValue }.join('|')}\"")
          end

        else
          log_debug "Noise gated file #{lNoiseGatedFileName} does not depend on a DC shifted recording."
          lSourceFileName = @Context[:CleanFiles][lBaseName][:FramedFileName]
        end
        # Set prerequisites for the task generating Noise Gate
        Rake::Task[@Context[:CleanFiles][lBaseName][:NoiseGatedFileName]].prerequisites.replace([
          iTask.name,
          lSourceFileName,
          lRecordedAnalysisFileName,
          @Context[:CleanFiles][lBaseName][:SilenceAnalysisFileName],
          @Context[:CleanFiles][lBaseName][:SilenceFFTProfileFileName]
        ])
      end

      # Create the Noise Gate file generation target.
      # By default it depends only on the corresponding dependencies task, but its execution will modify its prerequisites.

      desc "Apply Noise Gate to recorded file based on #{iBaseName}"
      file lNoiseGatedFileName => lDependenciesNoiseGateTaskName do |iTask|
        # Prerequisites list has been setup by the first prerequisite execution
        iSourceFileName, _, iSilenceAnalysisFileName, iSilenceFFTProfileFileName = iTask.prerequisites[1..4]
        # Get thresholds (without DC offsets) from the silence file
        lSilenceThresholds = getThresholds(iSilenceAnalysisFileName, :margin => @MusicMasterConf[:Clean][:MarginSilenceThresholds])
        lLstStrSilenceThresholds = lSilenceThresholds.map { |iThreshold| iThreshold.join(',') }
        wsk(iSourceFileName, iTask.name, 'NoiseGate', "--silencethreshold \"#{lLstStrSilenceThresholds.join('|')}\" --attack #{@MusicMasterConf[:Clean][:Attack]} --release #{@MusicMasterConf[:Clean][:Release]} --silencemin #{@MusicMasterConf[:Clean][:SilenceMin]} --noisefft \"#{iSilenceFFTProfileFileName}\"")
      end

      # Create embracing task
      rFinalTaskName = "CleanRecord_#{iBaseName}".to_sym

      desc "Clean recorded file #{iBaseName}"
      task rFinalTaskName => lNoiseGatedFileName

      # Set context for this file to be cleaned
      @Context[:CleanFiles][iBaseName] = {
        :SilenceAnalysisFileName => lAnalyzeSilenceFileName,
        :SilenceFFTProfileFileName => lFFTProfileSilenceFileName,
        :FramedFileName => lFramedFileName,
        :DCRemovedFileName => lDCRemovedFileName,
        :NoiseGatedFileName => lNoiseGatedFileName
      }

      return rFinalTaskName
    end

    # Generate rake rules to apply processes to a given Wave file.
    # Return the name of the last file.
    #
    # Parameters::
    # * *iProcesses* (<em>list<map<Symbol,Object>></em>): List of processes to apply
    # * *iFileName* (_String_): File name to apply processes to
    # * *iDir* (_String_): The directory where processed files are stored
    def generateRakeForProcesses(iProcesses, iFileName, iDir)
      rLastFileName = iFileName

      lFileNameNoExt = File.basename(iFileName[0..-5])
      iProcesses.each_with_index do |iProcessInfo, iIdxProcess|
        lProcessName = iProcessInfo[:Name]
        lProcessParams = iProcessInfo.clone.delete_if { |iKey, iValue| (iKey == :Name) }
        access_plugin('Processes', lProcessName) do |ioActionPlugin|
          # Set the MusicMaster configuration as an instance variable of the plugin also
          ioActionPlugin.instance_variable_set(:@MusicMasterConf, @MusicMasterConf)
          # Add Utils to the plugin namespace
          ioActionPlugin.class.module_eval('include MusicMaster::Utils')
          lCurrentFileName = rLastFileName
          rLastFileName = getProcessedFileName(iDir, lFileNameNoExt, iIdxProcess, lProcessName, lProcessParams)

          desc "Process file #{lCurrentFileName} with #{lProcessName}"
          file rLastFileName => [lCurrentFileName] do |iTask|
            log_info "===== Apply Process #{iProcessInfo[:Name]} to #{iTask.name} ====="
            FileUtils::mkdir_p(File.dirname(iTask.name))
            ioActionPlugin.execute(iTask.prerequisites.first, iTask.name, '.', lProcessParams)
          end

        end
      end

      return rLastFileName
    end

    # Generate all needed targets to produce a given mix
    #
    # Parameters::
    # * *iMixName* (_String_): The name of the mix to produce targets for
    # * *iFinalSources* (<em>map<Object,String></em>): The set of possible sources, per Track ID (can be alias, mix name, tracks list, wave name)
    # Return::
    # * _Symbol_: Name of the top-level target producing the mix
    def generateRakeForMix(iMixName, iFinalSources)
      rTarget = "Mix_#{iMixName}".to_sym

      # If the target already exists, do nothing
      if (!Rake::Task.task_defined?(rTarget))
        lDependenciesTarget = "Dependencies_Mix_#{iMixName}".to_sym
        lFinalMixTask = "FinalMix_#{iMixName}".to_sym
        # Create the target being the symbolic link
        lSymLinkFileName = getShortcutFileName(getFinalMixFileName(iMixName))

        desc "Mix #{iMixName}"
        task rTarget => lSymLinkFileName

        desc "Symbolic link pointing to the mix file #{iMixName}"
        file lSymLinkFileName => lDependenciesTarget do |iTask|
          # Get the mix name from the name of the Dependencies target
          lMixName = iTask.prerequisites[0].to_s.match(/^Dependencies_Mix_(.*)$/)[1]
          FileUtils::mkdir_p(File.dirname(iTask.name))
          createShortcut(iTask.prerequisites[1], getFinalMixFileName(lMixName))
        end

        desc "Dependencies needed to mix #{iMixName}"
        task lDependenciesTarget => lFinalMixTask do |iTask|
          lMixName = iTask.name.match(/^Dependencies_Mix_(.*)$/)[1]

          # Modify the dependencies of the symbolic link
          Rake::Task[getShortcutFileName(getFinalMixFileName(lMixName))].prerequisites.replace([
            iTask.name,
            Rake::Task[iTask.prerequisites.first].data[:FileName]
          ])
        end

        # Use the corresponding final mix task to create the whole processing chain
        # First, compute dependencies of the final mix task
        lLstDeps = []
        @RecordConf[:Mix][iMixName][:Tracks].keys.sort.each do |iTrackID|
          raise UnknownTrackIDError, "TrackID #{iTrackID} is not defined in the configuration for the mix." if (iFinalSources[iTrackID] == nil)
          lLstDeps << iFinalSources[iTrackID]
        end

        desc "Create processing chain for mix #{iMixName}"
        task lFinalMixTask => lLstDeps do |iTask|
          # This task is responsible for creating the whole processing chain from the source files (taken from prerequisites' data), and storing the top-level file name as its data.
          lMixName = iTask.name.match(/^FinalMix_(.*)$/)[1]
          lMixConf = @RecordConf[:Mix][lMixName]
          lFinalMixFileName = nil
          if (lMixConf[:Tracks].size == 1)
            # Just 1 source for this mix
            lTrackID = lMixConf[:Tracks].keys.first
            lTrackInfo = lMixConf[:Tracks][lTrackID]
            lSourceFileName = Rake::Task[@Context[:FinalMixSources][lTrackID]].data[:FileName]
            # Use all processes
            lLstProcesses = []
            lLstProcesses.concat(lTrackInfo[:Processes]) if (lTrackInfo[:Processes] != nil)
            lLstProcesses.concat(lMixConf[:Processes]) if (lMixConf[:Processes] != nil)
            lLstProcesses = optimizeProcesses(lLstProcesses)
            if (lLstProcesses.empty?)
              # Nothing to do
              lFinalMixFileName = lSourceFileName
            else
              lFinalMixFileName = generateRakeForProcesses(lLstProcesses, lSourceFileName, getMixDir)
            end
          else
            # Here, there will be a step of mixing files
            # 1. Process source files if needed
            lLstProcessedSourceFiles = []
            lMixConf[:Tracks].keys.sort.each do |iTrackID|
              lTrackInfo = lMixConf[:Tracks][iTrackID]
              # Get the source file for this track ID
              lSourceFileName = Rake::Task[@Context[:FinalMixSources][iTrackID]].data[:FileName]
              # By default it will be the processed file name
              lProcessedFileName = lSourceFileName
              # Get the list of processes to apply to it
              if (lTrackInfo[:Processes] != nil)
                lLstProcesses = optimizeProcesses(lTrackInfo[:Processes])
                if (!lLstProcesses.empty?)
                  lProcessedFileName = generateRakeForProcesses(lLstProcesses, lSourceFileName, getMixDir)
                end
              end
              lLstProcessedSourceFiles << lProcessedFileName
            end
            # 2. Mix all resulting files
            lFinalMixFileName = getMixFileName(getMixDir, lMixName, lMixConf[:Tracks])

            desc "Mix all processed sources for mix #{lMixName}"
            file lFinalMixFileName => lLstProcessedSourceFiles do |iTask2|
              lMixInputFile = iTask2.prerequisites.first
              lLstMixFiles = iTask2.prerequisites[1..-1]
              wsk(lMixInputFile, iTask2.name, 'Mix', "--files \"#{lLstMixFiles.join('|1|')}|1\" ")
            end

            # 3. Process the mix result
            if (lMixConf[:Processes] != nil)
              lLstProcesses = optimizeProcesses(lMixConf[:Processes])
              if (!lLstProcesses.empty?)
                lFinalMixFileName = generateRakeForProcesses(lLstProcesses, lFinalMixFileName, getMixDir)
              end
            end
          end
          log_info "File produced from the mix #{lMixName}: #{lFinalMixFileName}"
          iTask.data = {
            :FileName => lFinalMixFileName
          }
        end

      end

      return rTarget
    end

    # Generate all needed targets to produce a given deliverable
    #
    # Parameters::
    # * *iDeliverableName* (_String_): The name of the deliverable to produce targets for
    # Return::
    # * _Symbol_: Name of the top-level target producing the deliverable
    def generateRakeForDeliver(iDeliverableName)
      rTarget = "Deliver_#{iDeliverableName}".to_sym

      lDeliverableConf = @RecordConf[:Deliver][:Deliverables][iDeliverableName]

      # Get metadata
      # Default values
      lMetadata = {
        :FileName => 'Track'
      }
      lMetadata.merge!(@RecordConf[:Deliver][:Metadata]) if (@RecordConf[:Deliver][:Metadata] != nil)
      lMetadata.merge!(lDeliverableConf[:Metadata]) if (lDeliverableConf[:Metadata] != nil)

      # Get the format
      # Default values
      lFormatConf = {
        :FileFormat => 'Wave'
      }
      lFormatConf.merge!(@RecordConf[:Deliver][:Formats][lDeliverableConf[:Format]]) if (lDeliverableConf[:Format] != nil)

      # Call the format plugin
      access_plugin('Formats', lFormatConf[:FileFormat]) do |iFormatPlugin|
        # Set the MusicMaster configuration as an instance variable of the plugin also
        iFormatPlugin.instance_variable_set(:@MusicMasterConf, @MusicMasterConf)
        # Create the final filename
        # TODO: On Windows, when the format plugin creates a symbolic link, this target has a different name. Should create a virtual target storing the real name. Otherwise it will be always invoked every time.
        lDeliverableFileName = "#{getDeliverDir}/#{get_valid_file_name(iDeliverableName)}/#{replace_vars(lMetadata[:FileName], lMetadata)}.#{iFormatPlugin.getFileExt}"
        # Get the name of the mix file using the target computing it
        lFinalMixTarget = "FinalMix_#{lDeliverableConf[:Mix]}".to_sym
        # Use a dependency target to adapt the prerequisites of our deliverable
        lDepTarget = "Dependencies_Deliver_#{iDeliverableName}".to_sym

        desc "Compute dependencies for the deliverable #{iDeliverableName}"
        task lDepTarget => lFinalMixTarget do |iTask|
          lDeliverableName = iTask.name.match(/^Dependencies_Deliver_(.*)$/)[1]
          Rake::Task[@Context[:Deliverables][lDeliverableName][:FileName]].prerequisites.replace([
            iTask.name,
            Rake::Task[iTask.prerequisites.first].data[:FileName]
          ])
        end

        desc "Produce file for deliverable #{iDeliverableName}"
        file lDeliverableFileName => lDepTarget do |iTask|
          FileUtils::mkdir_p(File.dirname(iTask.name))
          iFormatPlugin.deliver(iTask.prerequisites[1], iTask.name, @Context[:DeliverableConf][iTask.name][0], @Context[:DeliverableConf][iTask.name][1])
        end

        desc "Deliver deliverable #{iDeliverableName}"
        task rTarget => lDeliverableFileName

        @Context[:DeliverableConf][lDeliverableFileName] = [
          lFormatConf.delete_if { |iKey, iValue| iKey == :FileFormat },
          lMetadata
        ]
        @Context[:Deliverables][iDeliverableName] = {
          :FileName => lDeliverableFileName
        }
      end

      return rTarget
    end

  end

end
