module Asciidoctor
  module SafeMode
    UNSAFE = 0
    SAFE = 1
    SERVER = 10
    SECURE = 20
    #PARANOID = 100

    def self.value_for_name(name)
      case name.to_s.upcase
      when "UNSAFE"
        UNSAFE
      when "SAFE"
        SAFE
      when "SERVER"
        SERVER
      when "SECURE"
        SECURE
      #when "PARANOID"
      #  PARANOID
      else
        nil
      end
    end

    def self.name_for_value(value)
      case value
      when UNSAFE
        "unsafe"
      when SAFE
        "safe"
      when SERVER
        "server"
      when SECURE
        "secure"
      #when PARANOID
      #  "paranoid"
      else
        nil
      end
    end

    def self.names
      ["unsafe", "safe", "server", "secure"]
    end
  end
end
