require "log"

module Asciidoctor
  # Simplified logging module for the Crystal port.
  # Uses Crystal's built-in Log framework.
  module Logging
    Log = ::Log.for("asciidoctor")

    def logger
      Log
    end
  end
end
