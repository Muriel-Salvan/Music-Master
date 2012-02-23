#--
# Copyright (c) 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

if (RUBY_VERSION < '1.9')
  class Symbol
    def <=>(iOther)
      return self.to_s <=> iOther.to_s
    end
  end
end
