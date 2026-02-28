module Asciidoctor
  module SafeMode
    SAFE    =  1
    SECURE  = 20
    SERVER  = 10
    UNSAFE  =  0

    def self.name_for_value(value)
      case value
      when UNSAFE then "unsafe"
      when SAFE   then "safe"
      when SERVER then "server"
      when SECURE then "secure"
      else             nil
      end
    end

    def self.names
      ["unsafe", "safe", "server", "secure"]
    end

    def self.value_for_name(name)
      case name.to_s.upcase
      when "UNSAFE" then UNSAFE
      when "SAFE"   then SAFE
      when "SERVER" then SERVER
      when "SECURE" then SECURE
      else               nil
      end
    end
  end
end
