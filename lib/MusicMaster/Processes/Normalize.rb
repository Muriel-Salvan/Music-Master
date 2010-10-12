module MusicMaster

  module Processes

    class Normalize

      # Execute the process
      #
      # Parameters:
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iOutputFileName* (_String_): File name to write
      # * *iTempDir* (_String_): Temporary directory that can be used
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters
      def execute(iInputFileName, iOutputFileName, iTempDir, iParams)
        # First, analyze
        lAnalyzeResultFileName = "#{iTempDir}/#{File.basename(iInputFileName)}.analyze"
        if (File.exists?(lAnalyzeResultFileName))
          logWarn "File #{lAnalyzeResultFileName} already exists. Will not overwrite it."
        else
          MusicMaster::wsk(iInputFileName, "#{iTempDir}/Dummy.wav", 'Analyze')
          File.unlink("#{iTempDir}/Dummy.wav")
          FileUtils::mv('analyze.result', lAnalyzeResultFileName)
        end
        lAnalyzeResult = nil
        File.open(lAnalyzeResultFileName, 'rb') do |iFile|
          lAnalyzeResult = Marshal.load(iFile.read)
        end
        lMaxDataValue = lAnalyzeResult[:MaxValues].sort[-1]
        lMinDataValue = lAnalyzeResult[:MinValues].sort[0]
        lMaxPossibleValue = (2**(lAnalyzeResult[:SampleSize]-1)) - 1
        lMinPossibleValue = -(2**(lAnalyzeResult[:SampleSize]-1))
        lCoeffNormalizeMax = Rational(lMaxPossibleValue, lMaxDataValue)
        lCoeffNormalizeMin = Rational(lMinPossibleValue, lMinDataValue)
        lCoeff = lCoeffNormalizeMax
        if (lCoeffNormalizeMin < lCoeff)
          lCoeff = lCoeffNormalizeMin
        end
        logInfo "Maximal value: #{lMaxDataValue}/#{lMaxPossibleValue}. Minimal value: #{lMinDataValue}/#{lMinPossibleValue}. Volume correction: #{lCoeff}."
        MusicMaster::wsk(iInputFileName, iOutputFileName, 'Multiply', "--coeff \"#{lCoeff.numerator}/#{lCoeff.denominator}\"")
      end

    end

  end

end