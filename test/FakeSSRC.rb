#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

puts "Fake SSRC invoked: #{ARGV.inspect}"

def fail(iStr)
  puts "!!! Fake SSRC error: #{iStr}"
  raise iStr
end

def format(iInfo)
  rStr = ":Input => '#{iInfo[:Input]}',\n:Output => '#{iInfo[:Output]}',\n"
  rStr.concat(":Params => [ '#{iInfo[:Params].join('\', \'')}' ]") if (iInfo[:Params] != nil)
  return rStr
end

# Check command line
if (ARGV.size < 2)
  fail("Invalid parameters for SSRC invocation: #{ARGV.inspect}")
end
lReceivedInfo = {
  :Input => ARGV[-2],
  :Output => ARGV[-1],
  :Params => (ARGV[0..-3].empty?) ? nil : ARGV[0..-3]
}

# Dequeue the name of the next SSRC command
lLstFakeSSRC = eval(File.read('MMT_FakeSSRC.rb'))
fail("No more SSRC calls expected. Called with:\n#{format(lReceivedInfo)}") if (lLstFakeSSRC.empty?)
lFakeSSRCInfo = lLstFakeSSRC.first
File.open('MMT_FakeSSRC.rb', 'w') { |oFile| oFile.write(lLstFakeSSRC[1..-1].inspect) }

# Check that we expected what we received
lErrors = []
if (lFakeSSRCInfo[:Input].is_a?(Regexp))
  lErrors << 'Wrong input file' if (lReceivedInfo[:Input].match(lFakeSSRCInfo[:Input]) == nil)
else
  lErrors << 'Wrong input file' if (lFakeSSRCInfo[:Input] != lReceivedInfo[:Input])
end
if (lFakeSSRCInfo[:Output].is_a?(Regexp))
  lErrors << 'Wrong output file' if (lReceivedInfo[:Output].match(lFakeSSRCInfo[:Output]) == nil)
else
  lErrors << 'Wrong output file' if (lFakeSSRCInfo[:Output] != lReceivedInfo[:Output])
end
if ((lFakeSSRCInfo[:Params] != nil) or
    (lReceivedInfo[:Params] != nil))
  lParamsOK = ((lFakeSSRCInfo[:Params] != nil) and
               (lReceivedInfo[:Params] != nil) and
               (lFakeSSRCInfo[:Params].size == lReceivedInfo[:Params].size))
  if (lParamsOK)
    lFakeSSRCInfo[:Params].each_with_index do |iRefParam, iIdxParam|
      lReceivedParam = lReceivedInfo[:Params][iIdxParam]
      if (iRefParam.is_a?(Regexp))
        if (lReceivedParam.match(iRefParam) == nil)
          lParamsOK = false
        end
      elsif (iRefParam != lReceivedParam)
        lParamsOK = false
      end
    end
  end
  lErrors << 'Wrong parameters' if (!lParamsOK)
end
fail("Following errors encountered:\n* #{lErrors.join("\n* ")}\nExpecting:\n#{format(lFakeSSRCInfo)}\nReceived:\n#{format(lReceivedInfo)}") if (!lErrors.empty?)

# Copy all relevant files
lFilesToCopy = {
  "Wave/#{lFakeSSRCInfo[:UseWave]}" => lReceivedInfo[:Output]
}
require 'fileutils'
lFilesToCopy.each do |iSrcFileName, iDstFileName|
  begin
    FileUtils::mkdir_p(File.dirname(iDstFileName))
    FileUtils::cp("#{ENV['MMT_ROOTPATH']}/test/#{iSrcFileName}", iDstFileName)
  rescue Exception
    fail $!.to_s
  end
end
