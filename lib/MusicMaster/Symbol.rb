if (RUBY_VERSION < '1.9')
  class Symbol
    def <=>(iOther)
      return self.to_s <=> iOther.to_s
    end
  end
end
