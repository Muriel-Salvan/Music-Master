#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'pp'
require 'tmpdir'

module MusicMaster

  module Utils

    # Initialize variables used by utils
    def initialize_Utils
      # A little cache
      # map< Symbol, Object >
      # * *:Analysis* (<em>map<String,Object></em>): Analysis object, per analysis file name
      # * *:DCOffsets* (<em>map<String,list<Float>></em>): Channels DC offsets, per analysis file name
      # * *:RMSValues* (<em>map<String,Float></em>): The average RMS values, per analysis file name
      # * *:Thresholds* (<em>map<String,list< [Integer,Integer] >></em>): List of [min,max] thresholds per channel, per analysis file name
      @Cache = {
        :Analysis => {},
        :DCOffsets => {},
        :RMSValues => {},
        :Thresholds => {}
      }
    end

    # Record into a given file
    #
    # Parameters::
    # * *iFileName* (_String_): File name to record into
    # * *iAlreadyPrepared* (_Boolean_): Is the file to be recorded already prepared ? [optional = false]
    def record(iFileName, iAlreadyPrepared = false)
      lTryAgain = true
      if (File.exists?(iFileName))
        puts "File \"#{iFileName}\" already exists. Overwrite ? ['y' = yes]"
        lTryAgain = ($stdin.gets.chomp == 'y')
      end
      while (lTryAgain)
        puts "Record file \"#{iFileName}\""
        lSkip = nil
        if (iAlreadyPrepared)
          lSkip = false
        else
          puts 'Press Enter to continue once done. Type \'s\' to skip it.'
          lSkip = ($stdin.gets.chomp == 's')
        end
        if (lSkip)
          lTryAgain = false
        else
          # Get the recorded file name
          lFileName = $MusicMasterConf[:Record][:RecordedFileGetter].call
          if (!File.exists?(lFileName))
            log_err "File #{lFileName} does not exist. Could not get recorded file."
          else
            log_info "Getting recorded file: #{lFileName} => #{iFileName}"
            FileUtils::mkdir_p(File.dirname(iFileName))
            FileUtils::mv(lFileName, iFileName)
            lTryAgain = false
          end
        end
      end
    end

    # Make an FFT profile of a given wav file, and store the result in the given file name.
    #
    # Parameters::
    # * *iWaveFile* (_String_): The wav file to analyze
    # * *iFFTProfileFile* (_String_): The analysis file to store into
    def fftProfileFile(iWaveFile, iFFTProfileFile)
      lDummyFile = "#{Dir.tmpdir}/MusicMaster/Dummy.wav"
      FileUtils::mkdir_p(File.dirname(lDummyFile))
      wsk(iWaveFile, lDummyFile, 'FFT')
      File.unlink(lDummyFile)
      FileUtils::mkdir_p(File.dirname(iFFTProfileFile))
      FileUtils::mv('fft.result', iFFTProfileFile)
    end

    # Analyze a given wav file, and store the result in the given file name.
    #
    # Parameters::
    # * *iWaveFile* (_String_): The wav file to analyze
    # * *iAnalysisFile* (_String_): The analysis file to store into
    def analyzeFile(iWaveFile, iAnalysisFile)
      lDummyFile = "#{Dir.tmpdir}/MusicMaster/Dummy.wav"
      FileUtils::mkdir_p(File.dirname(lDummyFile))
      wsk(iWaveFile, lDummyFile, 'Analyze')
      File.unlink(lDummyFile)
      FileUtils::mkdir_p(File.dirname(iAnalysisFile))
      FileUtils::mv('analyze.result', iAnalysisFile)
    end

    # Get analysis result
    #
    # Parameters::
    # * *iAnalysisFileName* (_String_): The name of the analysis file
    # Return::
    # * <em>map<Symbol,Object></em>: The analyze result
    def getAnalysis(iAnalysisFileName)
      rResult = nil

      if (@Cache[:Analysis][iAnalysisFileName] == nil)
        File.open(iAnalysisFileName, 'rb') do |iFile|
          rResult = Marshal.load(iFile.read)
        end
        @Cache[:Analysis][iAnalysisFileName] = rResult
      else
        rResult = @Cache[:Analysis][iAnalysisFileName]
      end

      return rResult
    end

    # Get DC offsets out of an analysis file
    #
    # Parameters::
    # * *iAnalyzeRecordedFileName* (_String_): Name of the file containing analysis
    # Return::
    # * _Boolean_: Is there an offset ?
    # * <em>list<Float></em>: The DC offsets, per channel
    def getDCOffsets(iAnalyzeRecordedFileName)
      rOffset = false
      rDCOffsets = []

      if (@Cache[:DCOffsets][iAnalyzeRecordedFileName] == nil)
        lAnalyze = getAnalysis(iAnalyzeRecordedFileName)
        lAnalyze[:MoyValues].each do |iMoyValue|
          lDCOffset = iMoyValue.round
          rDCOffsets << lDCOffset
          if (lDCOffset != 0)
            rOffset = true
          end
        end
        @Cache[:DCOffsets][iAnalyzeRecordedFileName] = [ rOffset, rDCOffsets ]
      else
        rOffset, rDCOffsets = @Cache[:DCOffsets][iAnalyzeRecordedFileName]
      end

      return rOffset, rDCOffsets
    end

    # Get average RMS value from an analysis file
    #
    # Parameters::
    # * *iAnalysisFileName* (_String_): Name of the analysis file
    # Return::
    # * _Float_: The average RMS value
    def getRMSValue(iAnalysisFileName)
      rRMSValue = nil

      if (@Cache[:RMSValues][iAnalysisFileName] == nil)
        lAnalysis = getAnalysis(iAnalysisFileName)
        rRMSValue = lAnalysis[:RMSValues].inject{ |iSum, iValue| next (iSum + iValue) } / lAnalysis[:RMSValues].size
        @Cache[:RMSValues][iAnalysisFileName] = rRMSValue
      else
        rRMSValue = @Cache[:RMSValues][iAnalysisFileName]
      end

      return rRMSValue
    end

    # Get signal thresholds, without DC offsets, from an analysis file
    #
    # Parameters::
    # * *iAnalysisFileName* (_String_): Name of the file containing analysis
    # * *iOptions* (<em>map<Symbol,Object></em>): Additional options [optional = {}]
    #   * *:margin* (_Float_): The margin to be added, in terms of fraction of the maximal signal value [optional = 0.0]
    # Return::
    # * <em>list< [Integer,Integer] ></em>: The [min,max] values, per channel
    def getThresholds(iAnalysisFileName, iOptions = {})
      rThresholds = []

      if (@Cache[:Thresholds][iAnalysisFileName] == nil)
        # Get silence thresholds from the silence file
        lSilenceAnalyze = getAnalysis(iAnalysisFileName)
        # Compute the DC offsets
        lSilenceDCOffsets = lSilenceAnalyze[:MoyValues].map { |iValue| iValue.round }
        lMargin = iOptions[:margin] || 0.0
        lSilenceAnalyze[:MaxValues].each_with_index do |iMaxValue, iIdxChannel|
          # Remove silence DC Offset
          lCorrectedMinValue = lSilenceAnalyze[:MinValues][iIdxChannel] - lSilenceDCOffsets[iIdxChannel]
          lCorrectedMaxValue = iMaxValue - lSilenceDCOffsets[iIdxChannel]
          # Compute the silence threshold by adding the margin
          rThresholds << [(lCorrectedMinValue-lCorrectedMinValue.abs*lMargin).to_i, (lCorrectedMaxValue+lCorrectedMaxValue.abs*lMargin).to_i]
        end
        @Cache[:Thresholds][iAnalysisFileName] = rThresholds
      else
        rThresholds = @Cache[:Thresholds][iAnalysisFileName]
      end

      return rThresholds
    end

    # Shift thresholds by a given DC offset.
    #
    # Parameters::
    # * *iThresholds* (<em>list< [Integer,Integer] ></em>): The thresholds to shift
    # * *iDCOffsets* (<em>list<Integer></em>): The DC offsets
    # Return::
    # * <em>list< [Integer,Integer] ></em>: The shifted thresholds
    def shiftThresholdsByDCOffset(iThresholds, iDCOffsets)
      rCorrectedThresholds = []

      # Compute the silence thresholds with DC offset applied
      iThresholds.each_with_index do |iThresholdInfo, iIdxChannel|
        lChannelDCOffset = iDCOffsets[iIdxChannel]
        rCorrectedThresholds << iThresholdInfo.map { |iValue| iValue + lChannelDCOffset }
      end

      return rCorrectedThresholds
    end

    # The groups of processes that can be optimized, and their corresponding optimization methods
    # They are sorted by importance: first ones will have greater priority
    # Here are the symbols used for each group:
    # * *:OptimizeProc* (_Proc_): The code called to optimize a group. It is called only for groups containing all processes from the group key, and including no other processes. Only for groups strictly larger than 1 element.
    #   Parameters::
    #   * *iLstProcesses* (<em>list<map<Symbol,Object>></em>): List of processes to optimize
    #   Return::
    #   * <em>list<map<Symbol,Object>></em>: List of optimized processes. Can be empty to delete them, or nil to not optimize them.
    OPTIM_GROUPS = [
      [ [ 'VolCorrection' ],
        {
          :OptimizeProc => Proc.new do |iLstProcesses|
            rOptimizedProcesses = []

            lRatio = 0.0
            iLstProcesses.each do |iProcessInfo|
              lRatio += readStrRatio(iProcessInfo[:Factor])
            end
            if (lRatio != 0)
              # Replace the serie with just 1 volume correction
              rOptimizedProcesses = [ {
                :Name => 'VolCorrection',
                :Factor => "#{lRatio}db"
              } ]
            end

            next rOptimizedProcesses
          end
        }
      ],
      [ [ 'DCShifter' ],
        {
          :OptimizeProc => Proc.new do |iLstProcesses|
            rOptimizedProcesses = []

            lDCOffset = 0
            iLstProcesses.each do |iProcessInfo|
              lDCOffset += iProcessInfo[:Offset]
            end
            if (lDCOffset != 0)
              # Replace the serie with just 1 DC offset
              rOptimizedProcesses = [ {
                :Name => 'DCShifter',
                :Offset => lDCOffset
              } ]
            end

            next rOptimizedProcesses
          end
        }
      ]
    ]
    # Activate debug log for this method only
    OPTIM_DEBUG = false
    # Optimize a list of processes.
    # Delete useless ones or ones that cancel themselves.
    #
    # Parameters::
    # * *iLstProcesses* (<em>list<map<Symbol,Object>></em>): List of processes
    # Return::
    # * <em>list<map<Symbol,Object>></em>: The optimized list of processes
    def optimizeProcesses(iLstProcesses)
      rNewLstProcesses = []

      lModified = true
      rNewLstProcesses = iLstProcesses
      while (lModified)
        # rNewLstProcesses contains the current list
        log_debug "[Optimize]: ========== Launch optimization for processes list: #{rNewLstProcesses.inspect}" if OPTIM_DEBUG
        lLstCurrentProcesses = rNewLstProcesses
        rNewLstProcesses = []
        lModified = false

        # The list of all possible group keys that can be used for optimizations
        # list< [ list<String>, map<Symbol,Object> ] >
        lCurrentMatchingGroups = nil
        lIdxGroupBegin = nil
        lIdxProcess = 0
        while (lIdxProcess < lLstCurrentProcesses.size)
          lProcessInfo = lLstCurrentProcesses[lIdxProcess]
          log_debug "[Optimize]: ===== Process Index: #{lIdxProcess} - Process: #{lProcessInfo.inspect} - Process group begin: #{lIdxGroupBegin.inspect} - Current matching groups: #{lCurrentMatchingGroups.inspect} - New processes list: #{rNewLstProcesses.inspect}" if OPTIM_DEBUG
          if (lIdxGroupBegin == nil)
            # We can begin grouping
            lCurrentMatchingGroups = []
            OPTIM_GROUPS.each do |iGroupInfo|
              if (iGroupInfo[0].include?(lProcessInfo[:Name]))
                # This group key can begin a new group
                lCurrentMatchingGroups << iGroupInfo
              end
            end
            if (lCurrentMatchingGroups.empty?)
              # We can't do anything with this process
              rNewLstProcesses << lProcessInfo
            else
              # We can begin a group
              lIdxGroupBegin = lIdxProcess
            end
            log_debug "[Optimize]: Set process group begin to #{lIdxGroupBegin.inspect}" if OPTIM_DEBUG
            lIdxProcess += 1
          else
            # We already have some group candidates
            # Now we remove the groups that do not fit with our current process
            lNewGroups = lCurrentMatchingGroups.clone.delete_if { |iGroupInfo| !iGroupInfo[0].include?(lProcessInfo[:Name]) }
            if (lNewGroups.empty?)
              log_debug '[Optimize]: Closing current matching groups.' if OPTIM_DEBUG
              # We are closing the group(s) we got
              lIdxGroupEnd = lIdxProcess - 1
              if (lIdxGroupBegin == lIdxGroupEnd)
                # This is a group of 1 element.
                log_debug '[Optimize]: Just 1 element to close.' if OPTIM_DEBUG
                # Just ignore it
                rNewLstProcesses << lLstCurrentProcesses[lIdxGroupBegin]
              else
                log_debug "[Optimize]: #{lIdxGroupEnd-lIdxGroupBegin+1} elements to close." if OPTIM_DEBUG
                lOptimizedProcesses = optimizeProcessesByGroups(lLstCurrentProcesses[lIdxGroupBegin..lIdxGroupEnd], lCurrentMatchingGroups)
                if (lOptimizedProcesses == nil)
                  # No optimization
                  log_debug '[Optimize]: Optimizer decided to not optimize.' if OPTIM_DEBUG
                  rNewLstProcesses.concat(lLstCurrentProcesses[lIdxGroupBegin..lIdxGroupEnd])
                else
                  # Optimization
                  log_debug "[Optimize]: Optimizer decided to optimize from #{lIdxGroupEnd-lIdxGroupBegin+1} to #{lOptimizedProcesses.size} elements." if OPTIM_DEBUG
                  rNewLstProcesses.concat(lOptimizedProcesses)
                  lModified = true
                end
              end
              lIdxGroupBegin = nil
              # Process again this element
            else
              log_debug "[Optimize]: Matching groups reduced from #{lCurrentMatchingGroups.size} to #{lNewGroups.size} elements." if OPTIM_DEBUG
              # We just remove groups that are out due to the current process
              lCurrentMatchingGroups = lNewGroups
              # Go on to the next element
              lIdxProcess += 1
            end
          end
        end
        # Last elements could have been part of a group
        log_debug "[Optimize]: ===== Process Index: #{lIdxProcess} - End of processes list - Process group begin: #{lIdxGroupBegin.inspect} - Current matching groups: #{lCurrentMatchingGroups.inspect} - New processes list: #{rNewLstProcesses.inspect}" if OPTIM_DEBUG
        if (lIdxGroupBegin != nil)
          if (lIdxGroupBegin < lLstCurrentProcesses.size - 1)
            # Indeed
            lOptimizedProcesses = optimizeProcessesByGroups(lLstCurrentProcesses[lIdxGroupBegin..-1], lCurrentMatchingGroups)
            if (lOptimizedProcesses == nil)
              # No optimization
              log_debug '[Optimize]: Optimizer decided to not optimize last group.' if OPTIM_DEBUG
              rNewLstProcesses.concat(lLstCurrentProcesses[lIdxGroupBegin..-1])
            else
              # Optimization
              log_debug "[Optimize]: Optimizer decided to optimize from #{lLstCurrentProcesses.size-lIdxGroupBegin} to #{lOptimizedProcesses.size} elements." if OPTIM_DEBUG
              rNewLstProcesses.concat(lOptimizedProcesses)
              lModified = true
            end
          else
            # Just the last element is remaining in the group
            log_debug '[Optimize]: Just 1 element to close at the end.' if OPTIM_DEBUG
            rNewLstProcesses << lLstCurrentProcesses[-1]
          end
        end
      end

      return rNewLstProcesses
    end

    # Optimize (or choose not to) a list of processes based on a potential list of optimization groups
    # Prerequisites:
    # * The list of processes has a size > 1
    # * The list of groups has a size > 0
    # * Each optimization group has at least 1 process in each of the processes' list's elements
    #
    # Parameters::
    # * *iLstProcesses* (<em>list<map<Symbol,Object>></em>): The list of processes to optimize
    # * *iLstGroups* (<em>list< [list<String>,map<Symbol,Object>] ></em>): The list of potential optimization groups
    # Return::
    # * <em>list<map<Symbol,Object>></em>: The corresponding list of processes optimized. Can be empty to delete them, or nil to not optimize them
    def optimizeProcessesByGroups(iLstProcesses, iLstGroups)
      rOptimizedProcesses = nil

      # Now we remove the groups needing several processes and that do not have all their processes among the selected group
      lLstProcessesNames = iLstProcesses.map { |iProcessInfo| iProcessInfo[:Name] }.uniq
      lLstMatchingGroups = iLstGroups.clone.delete_if do |iGroupInfo|
        # All processes from iGroupKey must be present among the current processes group
        next !(iGroupInfo[0] - lLstProcessesNames).empty?
      end
      # lLstMatchingGroups contain all the groups that can offer optimizations
      log_debug "[Optimize]: #{lLstMatchingGroups.size} groups can offer optimization." if OPTIM_DEBUG
      if (!lLstMatchingGroups.empty?)
        # Here we can optimize for real
        while ((rOptimizedProcesses == nil) and
               (!lLstMatchingGroups.empty?))
          # Choose the biggest priority group first
          lGroupInfo = lLstMatchingGroups.first
          # Call the relevant grouping function from the selected group on our list of processes
          log_debug "[Optimize]: Apply optimization from group #{lGroupInfo.inspect} to processes: #{iLstProcesses.inspect}" if OPTIM_DEBUG
          rOptimizedProcesses = lGroupInfo[1][:OptimizeProc].call(iLstProcesses)
          if (rOptimizedProcesses == nil)
            log_debug '[Optimize]: Group optimizer decided to not optimize.'
            lLstMatchingGroups = lLstMatchingGroups[1..-1]
          end
        end
      end
      log_debug "Processes optimized: from\n#{iLstProcesses.pretty_inspect}\nto\n#{rOptimizedProcesses.pretty_inspect}" if (rOptimizedProcesses != nil)

      return rOptimizedProcesses
    end

    # Read a ratio or db, and get back the corresponding ratio in db
    #
    # Parameters::
    # * *iStrValue* (_String_): The value to read
    # Return::
    # * _Float_: The corresponding ratio in db
    def self.readStrRatio(iStrValue)
      rRatio = nil

      lMatch = iStrValue.match(/^(.*)db$/)
      if (lMatch == nil)
        # The argument is a ratio
        rRatio = val2db(iStrValue.to_f)
      else
        # The argument is already in db
        rRatio = iStrValue.to_f
      end

      return rRatio
    end

    # Call WSK
    #
    # Parameters::
    # * *iInputFile* (_String_): The input file
    # * *iOutputFile* (_String_): The output file
    # * *iAction* (_String_): The action
    # * *iParams* (_String_): Action parameters [optional = '']
    def wsk(iInputFile, iOutputFile, iAction, iParams = '')
      log_info ''
      log_info "========== Processing #{iInputFile} ==#{iAction}==> #{iOutputFile} | #{iParams} ..."
      FileUtils::mkdir_p(File.dirname(iOutputFile))
      lCmd = "#{$MusicMasterConf[:WSKCmdLine]} --input \"#{iInputFile}\" --output \"#{iOutputFile}\" --action #{iAction} -- #{iParams}"
      log_debug "#{Dir.getwd}> #{lCmd}"
      system(lCmd)
      lErrorCode = $?.exitstatus
      if (lErrorCode == 0)
        log_info "========== Processing #{iInputFile} ==#{iAction}==> #{iOutputFile} | #{iParams} ... OK"
      else
        log_err "========== Processing #{iInputFile} ==#{iAction}==> #{iOutputFile} | #{iParams} ... ERROR #{lErrorCode}"
        raise RuntimeError, "Processing #{iInputFile} ==#{iAction}==> #{iOutputFile} | #{iParams} ... ERROR #{lErrorCode}"
      end
      log_info ''
    end

  end

end
