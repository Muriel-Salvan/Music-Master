require 'WSK/Common'

module MusicMaster

  module Processes

    class Compressor

      # Parameters of this process:
      # * *:DBUnits* (_Boolean_): Are units in DB format ? [optional = false]
      # * *:Threshold* (_Float_): The threshold below which there is no compression (in DB if :DBUnit is true, else in a [0..1] scale)
      # * *:Ratio* (_Float_): Compression ratio to apply above threshold.
      # * *:AttackDuration* (_String_): The attack duration (either in seconds or in samples)
      # * *:AttackDamping* (_Float_): The attack damping value in the duration previously defined (in DB if :DBUnit is true, else in a [0..1] scale). The compressor will never attack more than :AttackDamping values during a duration of :AttackDuration.
      # * *:AttackLookAhead* (_Boolean_): Is the attack to be forecast before it happens ?
      # * *:ReleaseDuration* (_String_): The release duration (either in seconds or in samples)
      # * *:ReleaseDamping* (_Float_): The release damping value in the duration previously defined (in DB if :DBUnit is true, else in a [0..1] scale). The compressor will never release more than :ReleaseDamping values during a duration of :ReleaseDuration.
      # * *:ReleaseLookAhead* (_Boolean_): Is the attack to be forecast before it happens ?
      # * *:MinChangeDuration* (_String_): The minimal duration a change in volume should have (either in seconds or in samples)
      # * *:RMSRatio* (_Float_): Ratio of RMS vs Peak level measurement used when profiling Wave files volumes. 0.0 = Use only Peak level. 1.0 = Use only RMS level. Other values in-between will produce a mix of both.

      include WSK::Common

      # -Infinity
      MINUS_INFINITY = -1.0/0.0

      # Interval used to profile the volume
      PROFILEVOLUME_INTERVAL = '0.1s'

      # Execute the process
      #
      # Parameters::
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
            log_err "Threshold (#{iParams[:Threshold]}db) has to be < 0db"
            lParamsOK = false
          end
        else
          # Threshold must be < 1
          if (iParams[:Threshold] >= 1)
            log_err "Threshold (#{iParams[:Threshold]}) has to be < 1"
            lParamsOK = false
          end
          # Threshold must be > 0
          if (iParams[:Threshold] <= 0)
            log_err "Threshold (#{iParams[:Threshold]}) has to be > 0"
            lParamsOK = false
          end
        end
        # Ratio must be > 1
        if (iParams[:Ratio] <= 1)
          log_err "Ratio (#{iParams[:Ratio]}) has to be > 1"
          lParamsOK = false
        end
        if (lParamsOK)
          # Get the volume profile of the Wave file
          lTempVolProfileFile = "#{iTempDir}/#{File.basename(iInputFileName)[0..-5]}.ProfileFct.rb"
          if (File.exists?(lTempVolProfileFile))
            log_warn "File #{lTempVolProfileFile} already exists. Will not overwrite it."
          else
            lTempWaveFile = "#{iTempDir}/Dummy.wav"
            # Get the volume profile
            wsk(iInputFileName, lTempWaveFile, 'VolumeProfile', "--function \"#{lTempVolProfileFile}\" --begin 0 --end -1 --interval \"#{PROFILEVOLUME_INTERVAL}\" --rmsratio #{iParams[:RMSRatio]}")
            File::unlink(lTempWaveFile)
          end

          # Get the file header for various measures later
          lHeader = nil
          File.open(iInputFileName, 'rb') do |iFile|
            lError, lHeader = readHeader(iFile)
            if (lError != nil)
              log_err "An error occurred while reading header: #{lError}"
            end
          end

          # Create the Compressor's function based on the parameters
          # Minimal value represented in DB.
          # This value will be used to replace -Infinity
          lMinimalDBValue = nil
          lCompressorFunction = WSK::Functions::Function.new
          lBDThreshold = iParams[:Threshold].to_r
          if (lDBUnits)
            # The minimal DB value is the smallest ratio possible for RMS values of this file (1/2^(BPS-1)) converted in DB and minus 1 to not mix it with the ratio 1/2^(BPS-1)
            lMinimalDBValue = lCompressorFunction.value_val_2_db(Rational(1), Rational(2)**(lHeader.NbrBitsPerSample-1)) - 1
            lCompressorFunction.set( {
              :FunctionType => WSK::Functions::FCTTYPE_PIECEWISE_LINEAR,
              :Points => [
                [lMinimalDBValue, lMinimalDBValue],
                [lBDThreshold, lBDThreshold],
                [0, lBDThreshold - lBDThreshold/(iParams[:Ratio].to_r) ]
              ]
            } )
          else
            lCompressorFunction.set( {
              :FunctionType => WSK::Functions::FCTTYPE_PIECEWISE_LINEAR,
              :Points => [
                [0, 0],
                [lBDThreshold, lBDThreshold],
                [1, lBDThreshold + (1-lBDThreshold)/(iParams[:Ratio].to_r) ]
              ]
            } )
          end
          log_info "Compressor transfer function: #{lCompressorFunction.function_data[:Points].map{ |p| next [ sprintf('%.2f', p[0]), sprintf('%.2f', p[1]) ] }.inspect}"

          # Compute the volume transformation function based on the profile function and the Compressor's parameters
          lTempVolTransformFile = "#{iTempDir}/#{File.basename(iInputFileName)[0..-5]}.VolumeFct.rb"
          if (File.exists?(lTempVolTransformFile))
            log_warn "File #{lTempVolTransformFile} already exists. Will not overwrite it."
          else
            # Read the Profile function
            log_info 'Create volume profile function ...'
            lProfileFunction = WSK::Functions::Function.new
            lProfileFunction.read_from_file(lTempVolProfileFile)
            if (lDBUnits)
              # Convert the Profile function in DB units
              lProfileFunction.convert_to_db(Rational(1))
              # Replace -Infinity with lMinimalDBValue
              lProfileFunction.function_data[:Points].each do |ioPoint|
                if (ioPoint[1] == MINUS_INFINITY)
                  ioPoint[1] = lMinimalDBValue
                end
              end
            end

            #dumpDebugFct(iInputFileName, lProfileFunction, 'ProfileDB', lDBUnits, iTempDir)

            # Clone the profile function before applying the map
            lNewProfileFunction = WSK::Functions::Function.new
            lNewProfileFunction.set(lProfileFunction.function_data.clone)

            # Transform the Profile function with the Compressor function
            log_info 'Apply compressor transfer function ...'
            lNewProfileFunction.apply_map_function(lCompressorFunction)

            #dumpDebugFct(iInputFileName, lNewProfileFunction, 'NewProfileDB', lDBUnits, iTempDir)

            # The difference of the functions will give the volume transformation profile
            log_info 'Compute differing function ...'
            lDiffProfileFunction = WSK::Functions::Function.new
            lDiffProfileFunction.set(lNewProfileFunction.function_data.clone)
            if (lDBUnits)
              # The volume transformation will be a DB difference
              lDiffProfileFunction.substract_function(lProfileFunction)
            else
              # The volume transformation will be a ratio
              lDiffProfileFunction.divide_by_function(lProfileFunction)
            end

            dumpDebugFct(iInputFileName, lDiffProfileFunction, 'RawDiffProfileDB', lDBUnits, iTempDir)

            # Apply damping for attack and release times
            log_info 'Damp differing function with attack and release ...'
            lAttackDuration = Rational(readDuration(iParams[:AttackDuration], lHeader.SampleRate))
            lAttackSlope = iParams[:AttackDamping].to_f.to_r/lAttackDuration
            lReleaseDuration = Rational(readDuration(iParams[:ReleaseDuration], lHeader.SampleRate))
            lReleaseSlope = iParams[:ReleaseDamping].to_f.to_r/lReleaseDuration
            if (lDBUnits)
              lAttackSlope = -lAttackSlope
              lReleaseSlope = -lReleaseSlope
            end
            # Take care of look-aheads
            if ((iParams[:AttackLookAhead] == true) or
                (iParams[:ReleaseLookAhead] == true))
              # Look-Aheads are implemented by applying damping on the reverted function
              lDiffProfileFunction.invert_abscisses
              if (iParams[:AttackLookAhead] == false)
                lDiffProfileFunction.apply_damping(nil, -lReleaseSlope)
              elsif (iParams[:ReleaseLookAhead] == false)
                lDiffProfileFunction.apply_damping(lAttackSlope, nil)
              else
                lDiffProfileFunction.apply_damping(lAttackSlope, -lReleaseSlope)
              end
              lDiffProfileFunction.invert_abscisses
            end
            if (iParams[:AttackLookAhead] == true)
              if (iParams[:ReleaseLookAhead] == false)
                lDiffProfileFunction.apply_damping(lReleaseSlope, nil)
              end
            elsif (iParams[:ReleaseLookAhead] == true)
              if (iParams[:AttackLookAhead] == false)
                lDiffProfileFunction.apply_damping(nil, -lAttackSlope)
              end
            else
              lDiffProfileFunction.apply_damping(lReleaseSlope, -lAttackSlope)
            end

            #dumpDebugFct(iInputFileName, lDiffProfileFunction, 'DampedDiffProfileDB', lDBUnits, iTempDir)

            # Eliminate glitches in the function.
            # This is done by deleting intermediate abscisses that are too close to each other

            log_info 'Smooth differing function ...'
            lDiffProfileFunction.remove_noise_abscisses(Rational(readDuration(iParams[:MinChangeDuration], lHeader.SampleRate)))

            dumpDebugFct(iInputFileName, lDiffProfileFunction, 'SmoothedDiffProfileDB', lDBUnits, iTempDir)

            # Save the volume transformation file
            lDiffProfileFunction.write_to_file(lTempVolTransformFile)
          end

          # Apply the volume transformation to the Wave file
          lStrUnitDB = 0
          if (lDBUnits)
            lStrUnitDB = 1
          end
          wsk(iInputFileName, iOutputFileName, 'ApplyVolumeFct', "--function \"#{lTempVolTransformFile}\" --begin 0 --end -1 --unitdb #{lStrUnitDB}")
        end
      end

      # Dump a function into a Wave file.
      # This is used for debugging purposes only.
      #
      # Parameters::
      # * *iInputFileName* (_String_): Name of the input file
      # * *iFunction* (<em>WSK::Functions::Function</em>): The function to dump
      # * *iName* (_String_): Name given to this function
      # * *iDBUnits* (_Boolean_): Is the function in DB units ?
      # * *iTempDir* (_String_): Temporary directory to use
      def dumpDebugFct(iInputFileName, iFunction, iName, iDBUnits, iTempDir)
        lBaseFileName = File.basename(iInputFileName)[0..-5]
        # Clone the function to round it first
        lRoundedFunction = WSK::Functions::Function.new
        lRoundedFunction.set(iFunction.function_data.clone)
        lRoundedFunction.write_to_file("#{iTempDir}/_#{lBaseFileName}_#{iName}.fct.rb", :Floats => true)
        wsk(iInputFileName, "#{iTempDir}/_#{lBaseFileName}_#{iName}.wav", 'DrawFct', "--function \"#{iTempDir}/_#{lBaseFileName}_#{iName}.fct.rb\" --unitdb #{iDBUnits ? '1' : '0'}")
      end

    end

  end

end
