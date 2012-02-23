#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

puts "Fake WSK invoked: #{ARGV.inspect}"

def fail(iStr)
  puts "!!! Fake WSK error: #{iStr}"
  raise iStr
end

def format(iInfo)
  rStr = ":Input => '#{iInfo[:Input]}',\n:Output => '#{iInfo[:Output]}',\n:Action => '#{iInfo[:Action]}',\n"
  rStr.concat(":Params => [ '#{iInfo[:Params].join('\', \'')}' ]") if (iInfo[:Params] != nil)
  return rStr
end

# Check command line
if ((ARGV[0] != '--input') or
    (ARGV[2] != '--output') or
    (ARGV[4] != '--action') or
    (ARGV[6] != '--'))
  fail("Invalid parameters for WSK invocation: #{ARGV.inspect}")
end
lReceivedInfo = {
  :Input => ARGV[1],
  :Output => ARGV[3],
  :Action => ARGV[5],
  :Params => (ARGV[7..-1].empty?) ? nil : ARGV[7..-1]
}

# Dequeue the name of the next WSK command
lLstFakeWSK = eval(File.read('MMT_FakeWSK.rb'))
fail("No more WSK calls expected. Called with:\n#{format(lReceivedInfo)}") if (lLstFakeWSK.empty?)
lFakeWSKInfo = lLstFakeWSK.first
File.open('MMT_FakeWSK.rb', 'w') { |oFile| oFile.write(lLstFakeWSK[1..-1].inspect) }

# Check that we expected what we received
lErrors = []
if (lFakeWSKInfo[:Input].is_a?(Regexp))
  lErrors << 'Wrong input file' if (lReceivedInfo[:Input].match(lFakeWSKInfo[:Input]) == nil)
else
  lErrors << 'Wrong input file' if (lFakeWSKInfo[:Input] != lReceivedInfo[:Input])
end
if (lFakeWSKInfo[:Output].is_a?(Regexp))
  lErrors << 'Wrong output file' if (lReceivedInfo[:Output].match(lFakeWSKInfo[:Output]) == nil)
else
  lErrors << 'Wrong output file' if (lFakeWSKInfo[:Output] != lReceivedInfo[:Output])
end
lErrors << 'Wrong action' if (lFakeWSKInfo[:Action] != lReceivedInfo[:Action])
if ((lFakeWSKInfo[:Params] != nil) or
    (lReceivedInfo[:Params] != nil))
  lParamsOK = ((lFakeWSKInfo[:Params] != nil) and
               (lReceivedInfo[:Params] != nil) and
               (lFakeWSKInfo[:Params].size == lReceivedInfo[:Params].size))
  if (lParamsOK)
    lFakeWSKInfo[:Params].each_with_index do |iRefParam, iIdxParam|
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
fail("Following errors encountered:\n* #{lErrors.join("\n* ")}\nExpecting:\n#{format(lFakeWSKInfo)}\nReceived:\n#{format(lReceivedInfo)}") if (!lErrors.empty?)

# Copy all relevant files
lFilesToCopy = lFakeWSKInfo[:CopyFiles] || {}
lFilesToCopy["Wave/#{lFakeWSKInfo[:UseWave]}"] = lReceivedInfo[:Output]
require 'fileutils'
lFilesToCopy.each do |iSrcFileName, iDstFileName|
  begin
    FileUtils::mkdir_p(File.dirname(iDstFileName))
    FileUtils::cp("#{ENV['MMT_ROOTPATH']}/test/#{iSrcFileName}", iDstFileName)
  rescue Exception
    fail $!.to_s
  end
end
