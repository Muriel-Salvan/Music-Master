require 'WSK/Common'

module MusicMaster

  module Processes

    class Compressor
      
      include WSK::Common

      # -Infinity
      MINUS_INFINITY = -1.0/0.0

      # Parameters of this process:
      # * *:DBUnits* (_Boolean_): Are units in DB format ? [optional = false]
      # * *:Threshold* (_Float_): The threshold below which there is no compression (in DB if :DBUnit is true, else in a [0..1] scale)
      # * *:Ratio* (_Float_): Compression ratio to apply above threshold.
      # * *:AttackDuration* (_String_): The attack duration (either in seconds or in samples)
      # * *:AttackDamping* (_String_): The attack damping value in the duration previously defined (in DB if :DBUnit is true, else in a [0..1] scale). The compressor will never attack more than :AttackDamping values during a duration of :AttackDuration.
      # * *:ReleaseDuration* (_String_): The release duration (either in seconds or in samples)
      # * *:ReleaseDamping* (_String_): The release damping value in the duration previously defined (in DB if :DBUnit is true, else in a [0..1] scale). The compressor will never release more than :ReleaseDamping values during a duration of :ReleaseDuration.

      # Execute the process
      #
      # Parameters:
      # * *iInputFileName* (_String_): File name we want to apply effects to
      # * *iOutputFileName* (_String_): File name to write
      # * *iTempDir* (_String_): Temporary directory that can be used
      # * *iParams* (<em>map<Symbol,Object></em>): Parameters
      def execute(iInputFileName, iOutputFileName, iTempDir, iParams)
        # Check parameters
        lDBUnits = iParams[:DBUnits]
        if (lDBUnits == nil)
          lDBUnits = false
        end
        lParamsOK = true
        if (lDBUnits)
          # Threshold must be < 0
          if (iParams[:Threshold] >= 0)
            logErr "Threshold (#{iParams[:Threshold]}db) has to be < 0db"
            lParamsOK = false
          end
        else
          # Threshold must be < 1
          if (iParams[:Threshold] >= 1)
            logErr "Threshold (#{iParams[:Threshold]}) has to be < 1"
            lParamsOK = false
          end
          # Threshold must be > 0
          if (iParams[:Threshold] <= 0)
            logErr "Threshold (#{iParams[:Threshold]}) has to be > 0"
            lParamsOK = false
          end
        end
        # Ratio must be > 1
        if (iParams[:Ratio] <= 1)
          logErr "Ratio (#{iParams[:Ratio]}) has to be > 1"
          lParamsOK = false
        end
        if (lParamsOK)
          # Get the volume profile of the Wave file
          lTempVolProfileFile = "#{iTempDir}/#{File.basename(iInputFileName)[0..-5]}.ProfileFct.rb"
          if (File.exists?(lTempVolProfileFile))
            logWarn "File #{lTempVolProfileFile} already exists. Will not overwrite it."
          else
            lTempWaveFile = "#{iTempDir}/Dummy.wav"
            # Get the volume profile
            MusicMaster::wsk(iInputFileName, lTempWaveFile, 'VolumeProfile', "--function \"#{lTempVolProfileFile}\" --begin 0 --end -1 --interval \"#{$MusicMasterConf[:Compressor][:Interval]}\"")
            File::unlink(lTempWaveFile)
          end

          # Get the file header for various measures later
          lHeader = nil
          File.open(iInputFileName, 'rb') do |iFile|
            lError, lHeader = readHeader(iFile)
            if (lError != nil)
              logErr "An error occurred while reading header: #{lError}"
            end
          end

          # Create the Compressor's function based on the parameters
          # Minimal value represented in DB.
          # This value will be used to replace -Infinity
          lMinimalDBValue = nil
          lCompressorFunction = WSK::Functions::Function.new
          if (lDBUnits)
            # The minimal DB value is the smallest ratio possible for RMS values of this file (1/2^(BPS-1)) converted in DB and minus 1 to not mix it with the ratio 1/2^(BPS-1)
            lMinimalDBValue = val2db(1, 2**(lHeader.NbrBitsPerSample-1))[0] - 1
            lCompressorFunction.set( {
              :FunctionType => WSK::Functions::FCTTYPE_PIECEWISE_LINEAR,
              :Points => [
                [lMinimalDBValue, lMinimalDBValue],
                [iParams[:Threshold], iParams[:Threshold]],
                [0, iParams[:Threshold] - Float(iParams[:Threshold])/iParams[:Ratio] ]
              ]
            } )
          else
            lCompressorFunction.set( {
              :FunctionType => WSK::Functions::FCTTYPE_PIECEWISE_LINEAR,
              :Points => [
                [0, 0],
                [iParams[:Threshold], iParams[:Threshold]],
                [1, iParams[:Threshold] + (1.0-iParams[:Threshold])/iParams[:Ratio] ]
              ]
            } )
          end
          logInfo "Compressor transfer function: #{lCompressorFunction.functionData[:Points].inspect}"

          # Compute the volume transformation function based on the profile function and the Compressor's parameters
          lTempVolTransformFile = "#{iTempDir}/#{File.basename(iInputFileName)[0..-5]}.VolumeFct.rb"
          if (File.exists?(lTempVolTransformFile))
            logWarn "File #{lTempVolTransformFile} already exists. Will not overwrite it."
          else
            # Read the Profile function
            lProfileFunction = WSK::Functions::Function.new
            lProfileFunction.readFromFile(lTempVolProfileFile)
            if (lDBUnits)
              # Convert the Profile function in DB units
              lProfileFunction.convertToDB(1)
              # Replace -Infinity with lMinimalDBValue
              lProfileFunction.functionData[:Points].each do |ioPoint|
                if (ioPoint[1] == MINUS_INFINITY)
                  ioPoint[1] = lMinimalDBValue
                end
              end
            end

            # Clone the profile function before applying the map
            lNewProfileFunction = WSK::Functions::Function.new
            lNewProfileFunction.set(lProfileFunction.functionData.clone)
            
            # Transform the Profile function with the Compressor function
            lNewProfileFunction.applyMapFunction(lCompressorFunction)

            # The difference of the functions will give the volume transformation profile
            lDiffProfileFunction = WSK::Functions::Function.new
            lDiffProfileFunction.set(lNewProfileFunction.functionData.clone)
            if (lDBUnits)
              # The volume transformation will be a DB difference
              lDiffProfileFunction.substractFunction(lProfileFunction)
            else
              # The volume transformation will be a ratio
              lDiffProfileFunction.divideByFunction(lProfileFunction)
            end

            # Apply damping for attack and release times
            lAttackDuration = readDuration(iParams[:AttackDuration], lHeader.SampleRate)
            lAttackSlope = Float(iParams[:AttackDamping])/Float(lAttackDuration)
            lReleaseDuration = readDuration(iParams[:ReleaseDuration], lHeader.SampleRate)
            lReleaseSlope = Float(iParams[:ReleaseDamping])/Float(lReleaseDuration)
            if (lDBUnits)
              lAttackSlope = -lAttackSlope
              lReleaseSlope = -lReleaseSlope
            end
            lDiffProfileFunction.applyDamping(lReleaseSlope, -lAttackSlope)

            # Save the volume transformation file
            lDiffProfileFunction.writeToFile(lTempVolTransformFile)
          end

          # Apply the volume transformation to the Wave file
          lStrUnitDB = 0
          if (lDBUnits)
            lStrUnitDB = 1
          end
          MusicMaster::wsk(iInputFileName, iOutputFileName, 'ApplyVolumeFct', "--function \"#{lTempVolTransformFile}\" --begin 0 --end -1 --unitdb #{lStrUnitDB}")
        end
      end

    end

  end

end