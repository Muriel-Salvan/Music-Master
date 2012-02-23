#!env ruby
#--
# Copyright (c) 2009 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# Convert a ratio value into a decibel value
def val2db(iRatio)
  if (iRatio == 0)
    return -1.0/0
  else
    return (6*Math.log(iRatio))/Math.log(2.0)
  end
end

# Convert a decibel value into a ratio value
def db2val(iDB)
  return 2**(iDB/6)
end

lArg = ARGV[0]

if (lArg == nil)
  puts 'Usage: DBConvert.rb <Value>'
  puts '  <Value>: Either a ratio (0.43) or a db value (4.1db)'
  exit 1
end

lMatch = lArg.match(/^(.*)db$/)
if (lMatch == nil)
  # The argument is a ratio
  lRatio = lArg.to_f
  puts "#{lRatio} = #{val2db(lRatio)}db"
else
  lDB = lArg.to_f
  puts "#{lDB}db = #{db2val(lDB)}"
end
  
