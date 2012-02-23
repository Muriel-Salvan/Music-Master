#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module MusicMaster

  module Formats

    class Test

      # Give the file extension
      #
      # Return::
      # * _String_: The file extension (without .)
      def getFileExt
        return 'test.rb'
      end

      # Deliver a file.
      # The delivered file can be a shortcut to the source one.
      #
      # Parameters::
      # * *iSrcFileName* (_String_): The source file to deliver from
      # * *iDstFileName* (_String_): The destination file to be delivered
      # * *iFormatConf* (<em>map<Symbol,Object></em>): The format configuration
      # * *iMetadata* (<em>map<Symbol,Object></em>): The metadata that can be used while delivering the file
      def deliver(iSrcFileName, iDstFileName, iFormatConf, iMetadata)
        log_debug "Deliver for test purposes file #{iDstFileName}"
        File.open(iDstFileName, 'w') do |oFile|
          oFile.write({
            :SrcFileName => iSrcFileName,
            :DstFileName => iDstFileName,
            :FormatConf => iFormatConf,
            :Metadata => iMetadata
          }.inspect)
        end
      end

    end

  end

end
