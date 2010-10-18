module MusicMaster

  module Processes

    class Compressor
      
      # Minimal value represented in DB
      MINIMAL_DB = -1.0/0.0

      # Parameters of this process:
      # * *:DBUnits* (_Boolean_): Are units in DB format ? [optional = false]
      # * *:Threshold* (_Float_): The threshold below which there is no compression (in DB if :DBUnit is true)
      # * *:Ratio* (_Float_): Compression ratio to apply above threshold
      # * *:Attack* (_String_): The attack duration (either in seconds or in samples)
      # * *:Release* (_String_): The release duration (either in seconds or in samples)

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
          logErr "Ratio (#{iParams[:Threshold]}) has to be > 1"
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

          # Create the Compressor's function based on the parameters
          require 'WSK/Common'
          lCompressorFunction = WSK::Functions::Function.new
          if (lDBUnits)
            lCompressorFunction.set( {
              :FunctionType => WSK::Functions::FCTTYPE_PIECEWISE_LINEAR,
              :Points => [
                [MINIMAL_DB, MINIMAL_DB],
                [iParams[:Threshold], iParams[:Threshold]],
                [0, iParams[:Threshold] - iParams[:Threshold]/iParams[:Ratio] ]
              ]
            } )
          else
            lCompressorFunction.set( {
              :FunctionType => WSK::Functions::FCTTYPE_PIECEWISE_LINEAR,
              :Points => [
                [0, 0],
                [iParams[:Threshold], iParams[:Threshold]],
                [1, iParams[:Threshold] + (1-iParams[:Threshold])/iParams[:Ratio] ]
              ]
            } )
          end

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
              lProfileFunction.convertToDB
            end
            # Clone the profile function before applying the map
            lNewProfileFunction = WSK::Functions::Function.new
            lNewProfileFunction.set(lProfileFunction.functionData.clone)
            
            # Transform the Profile function with the Compressor function
            # TODO: Check if we really need Attack and Release
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