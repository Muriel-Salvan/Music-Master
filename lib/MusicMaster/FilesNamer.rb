#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'MusicMaster/Hash'

module MusicMaster

  module FilesNamer

    # Get the directory in which files are recorded
    #
    # Return::
    # * _String_: Directory to record files to
    def getRecordedDir
      return '01_Source/Record'
    end

    # Get the recorded file name of a given list of tracks on a given environment
    #
    # Parameters::
    # * *iEnv* (_Symbol_): The environment
    # * *iLstTracks* (<em>list<Integer></em>): The list of tracks being recorded
    # Return::
    # * _String_: Name of the Wave file
    def getRecordedFileName(iEnv, iLstTracks)
      return "#{getRecordedDir}/#{iEnv}.#{iLstTracks.sort.join('.')}.wav"
    end

    # Get the recorded silence file name on a given recording environment
    #
    # Parameters::
    # * *iEnv* (_Symbol_): The environment
    # Return::
    # * _String_: Name of the Wave file
    def getRecordedSilenceFileName(iEnv)
      return "01_Source/Record/#{iEnv}.Silence.wav"
    end

    # Get the recorded calibration file name, recording from a recording environment in order to be compared later with a reference environment.
    #
    # Parameters::
    # * *iEnvReference* (_Symbol_): The reference environment
    # * *iEnvRecording* (_Symbol_): The recording environment
    # Return::
    # * _String_: Name of the Wave file
    def getRecordedCalibrationFileName(iEnvReference, iEnvRecording)
      return "01_Source/Record/Calibration.#{iEnvRecording}.#{iEnvReference}.wav"
    end

    # Get the calibrated recorded file name
    #
    # Parameters::
    # * *iRecordedBaseName* (_String_): Base name of the recorded track
    # Return::
    # * _String_: Name of the Wave file
    def getCalibratedFileName(iRecordedBaseName)
      return "03_Calibrate/Record/#{iRecordedBaseName}.Calibrated.wav"
    end

    # Get the name of a source wave file
    #
    # Parameters::
    # * *iFileName* (_String_): Name of the Wave file used to generate this source wave file
    # Return::
    # * _String_: Name of the Wave file
    def getWaveSourceFileName(iFileName)
      if (File.exists?(iFileName))
        # Use the original one
        return iFileName
      else
        # We will generate a new one
        return "01_Source/Wave/#{File.basename(iFileName)}"
      end
    end

    # Get the name of an analysis file taken from a recorded file
    #
    # Parameters::
    # * *iBaseName* (_String_): Base name of the recorded file (without extension)
    # Return::
    # * _String_: The analysis file name
    def getRecordedAnalysisFileName(iBaseName)
      return "Analyze/Record/#{iBaseName}.analyze"
    end

    # Get the name of a FFT profike file taken from a recorded file
    #
    # Parameters::
    # * *iBaseName* (_String_): Base name of the recorded file (without extension)
    # Return::
    # * _String_: The FFT profile file name
    def getRecordedFFTProfileFileName(iBaseName)
      return "Analyze/Record/#{iBaseName}.fftprofile"
    end

    # Get the name of the file generated after removing silences from it.
    #
    # Parameters::
    # * *iBaseName* (_String_): Base name of the file
    # Return::
    # * _String_: The generated file name
    def getSilenceRemovedFileName(iBaseName)
      return "02_Clean/Record/#{iBaseName}.01.SilenceRemover.wav"
    end

    # Get the name of the file generated after applying a cut from it.
    #
    # Parameters::
    # * *iBaseName* (_String_): Base name of the file
    # * *iCutInfo* (<em>[String,String]</em>): The cut information, used to extract only a part of the file (begin and end markers, in seconds or samples)
    # Return::
    # * _String_: The generated file name
    def getCutFileName(iBaseName, iCutInfo)
      return "02_Clean/Record/#{iBaseName}.02.Cut.#{iCutInfo.join('_')}.wav"
    end

    # Get the name of the file generated after applying a DC remover from it.
    #
    # Parameters::
    # * *iBaseName* (_String_): Base name of the file
    # Return::
    # * _String_: The generated file name
    def getDCRemovedFileName(iBaseName)
      return "02_Clean/Record/#{iBaseName}.03.DCShifter.wav"
    end

    # Get the name of the file generated after applying a noise gate from it.
    #
    # Parameters::
    # * *iBaseName* (_String_): Base name of the file
    # Return::
    # * _String_: The generated file name
    def getNoiseGateFileName(iBaseName)
      return "02_Clean/Record/#{iBaseName}.04.NoiseGate.wav"
    end

    # Get the directory in which Wave files are processed
    #
    # Return::
    # * _String_: Directory to process files to
    def getProcessesWaveDir
      return '04_Process/Wave'
    end

    # Get the directory in which recorded files are processed
    #
    # Return::
    # * _String_: Directory to process files to
    def getProcessesRecordDir
      return '04_Process/Record'
    end

    # Get the name of a file to processed
    #
    # Parameters::
    # * *iDir* (_String_): Directory where to store the processed file
    # * *iBaseName* (_String_): Base name of the processed file source
    # * *iIdxProcess* (_Integer_): Index of the process
    # * *iProcessName* (_String_): Name of the process to apply
    # * *iProcessParams* (<em>map<Symbol,Object></em>): Process parameters
    def getProcessedFileName(iDir, iBaseName, iIdxProcess, iProcessName, iProcessParams)
      # If the base name contains already an ID, integrate it in the new ID
      lMatch = iBaseName.match(/^(.*)\.([[:xdigit:]]{32,32})$/)
      if (lMatch == nil)
        return "#{iDir}/#{iBaseName}.#{iIdxProcess}.#{iProcessName}.#{iProcessParams.unique_id}.wav"
      else
        lNewBaseName = lMatch[1]
        lNewProcessParams = {
          :__InheritedID__ => lMatch[2]
        }.merge(iProcessParams)
        return "#{iDir}/#{lNewBaseName}.#{iIdxProcess}.#{iProcessName}.#{lNewProcessParams.unique_id}.wav"
      end
    end

    # Get the directory in which mix files are processed
    #
    # Return::
    # * _String_: Directory to mix files to
    def getMixDir
      return '05_Mix'
    end

    # Get the name of a file to be mixed
    #
    # Parameters::
    # * *iDir* (_String_): Directory where to store the mixed file
    # * *iMixName* (_String_): Name of the mix
    # * *iMixTracksConf* (<em>map<Symbol,Object></em>): Mix tracks' parameters
    def getMixFileName(iDir, iMixName, iMixTracksConf)
      return "#{iDir}/#{iMixName}.#{iMixTracksConf.unique_id}.wav"
    end

    # Get the name of a final mix file (the symbolic link)
    #
    # Parameters::
    # * *iMixName* (_String_): Name of the mix
    def getFinalMixFileName(iMixName)
      return "05_Mix/Final/#{iMixName}.wav"
    end

    # Get the directory in which files are delivered
    #
    # Return::
    # * _String_: Directory to deliver files to
    def getDeliverDir
      return '06_Deliver'
    end

  end

end
