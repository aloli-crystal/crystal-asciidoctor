require "../spec_helper"

# Helper methods
def convert_string_to_embedded(input : String, options : Hash(String, String) = {} of String => String) : String
  options["standalone"] = "false"
  Asciicrystal.convert(input, options)
end

describe Asciicrystal::Logger do
  describe "initialization" do
    it "should configure logger with level set to WARN by default" do
      io = IO::Memory.new
      logger = Asciicrystal::Logger.new(io)
      # Default level is WARN, so debug/info should not be logged
      logger.debug("debug message")
      logger.info("info message")
      io.to_s.should be_empty
    end

    it "should log WARN messages by default" do
      io = IO::Memory.new
      logger = Asciicrystal::Logger.new(io)
      logger.warn("warning message")
      io.to_s.should contain("warning message")
    end

    it "should log FATAL messages" do
      io = IO::Memory.new
      logger = Asciicrystal::Logger.new(io)
      logger.fatal("fatal message")
      io.to_s.should contain("fatal message")
    end

    it "should log ERROR messages" do
      io = IO::Memory.new
      logger = Asciicrystal::Logger.new(io)
      logger.error("error message")
      io.to_s.should contain("error message")
    end

    it "should not log DEBUG messages at default level" do
      io = IO::Memory.new
      logger = Asciicrystal::Logger.new(io)
      logger.debug("debug message")
      io.to_s.should be_empty
    end

    it "should not log INFO messages at default level" do
      io = IO::Memory.new
      logger = Asciicrystal::Logger.new(io)
      logger.info("info message")
      io.to_s.should be_empty
    end
  end

  describe "BasicFormatter" do
    it "should format WARN as WARNING" do
      io = IO::Memory.new
      logger = Asciicrystal::Logger.new(io)
      logger.warn("this is a call")
      io.to_s.should contain("asciidoctor: WARNING: this is a call")
    end

    it "should format FATAL as FAILED" do
      io = IO::Memory.new
      logger = Asciicrystal::Logger.new(io)
      logger.fatal("it cannot be done")
      io.to_s.should contain("asciidoctor: FAILED: it cannot be done")
    end

    it "should format ERROR as ERROR" do
      io = IO::Memory.new
      logger = Asciicrystal::Logger.new(io)
      logger.error("something went wrong")
      io.to_s.should contain("asciidoctor: ERROR: something went wrong")
    end
  end

  describe "max_severity tracking" do
    it "should track max severity" do
      io = IO::Memory.new
      logger = Asciicrystal::Logger.new(io)
      logger.max_severity.should be_nil
      logger.warn("warn")
      logger.max_severity.should eq(Asciicrystal::Severity::WARN)
      logger.error("error")
      logger.max_severity.should eq(Asciicrystal::Severity::ERROR)
    end

    it "should not decrease max severity" do
      io = IO::Memory.new
      logger = Asciicrystal::Logger.new(io)
      logger.error("error")
      logger.warn("warn")
      logger.max_severity.should eq(Asciicrystal::Severity::ERROR)
    end
  end
end

describe Asciicrystal::MemoryLogger do
  it "should store messages in memory" do
    logger = Asciicrystal::MemoryLogger.new
    logger.warn("warning 1")
    logger.error("error 1")
    logger.messages.size.should eq(2)
  end

  it "should store message severity" do
    logger = Asciicrystal::MemoryLogger.new
    logger.warn("warning 1")
    logger.messages.first.severity.should eq(Asciicrystal::Severity::WARN)
  end

  it "should store message text" do
    logger = Asciicrystal::MemoryLogger.new
    logger.warn("warning 1")
    logger.messages.first.message.should eq("warning 1")
  end

  it "should clear messages" do
    logger = Asciicrystal::MemoryLogger.new
    logger.warn("warning 1")
    logger.clear
    logger.messages.should be_empty
  end

  it "should report empty? correctly" do
    logger = Asciicrystal::MemoryLogger.new
    logger.empty?.should be_true
    logger.warn("warning 1")
    logger.empty?.should be_false
  end

  it "should compute max_severity" do
    logger = Asciicrystal::MemoryLogger.new
    logger.max_severity.should be_nil
    logger.warn("warning 1")
    logger.max_severity.should eq(Asciicrystal::Severity::WARN)
    logger.error("error 1")
    logger.max_severity.should eq(Asciicrystal::Severity::ERROR)
  end

  it "should support error with block" do
    logger = Asciicrystal::MemoryLogger.new
    logger.error { "lazy error" }
    logger.messages.first.message.should eq("lazy error")
    logger.messages.first.severity.should eq(Asciicrystal::Severity::ERROR)
  end

  it "should support warn with block" do
    logger = Asciicrystal::MemoryLogger.new
    logger.warn { "lazy warn" }
    logger.messages.first.message.should eq("lazy warn")
    logger.messages.first.severity.should eq(Asciicrystal::Severity::WARN)
  end
end

describe Asciicrystal::NullLogger do
  it "should discard all messages" do
    logger = Asciicrystal::NullLogger.new
    logger.warn("warning 1")
    logger.error("error 1")
    logger.fatal("fatal 1")
    # NullLogger has no messages accessor, it just tracks max_severity
    logger.max_severity.should eq(Asciicrystal::Severity::FATAL)
  end

  it "should track max severity" do
    logger = Asciicrystal::NullLogger.new
    logger.max_severity.should be_nil
    logger.warn("warn")
    logger.max_severity.should eq(Asciicrystal::Severity::WARN)
    logger.error("error")
    logger.max_severity.should eq(Asciicrystal::Severity::ERROR)
  end

  it "should not decrease max severity" do
    logger = Asciicrystal::NullLogger.new
    logger.fatal("fatal")
    logger.warn("warn")
    logger.max_severity.should eq(Asciicrystal::Severity::FATAL)
  end
end

describe Asciicrystal::LoggerManager do
  it "should provide access to logger via static logger method" do
    logger = Asciicrystal::LoggerManager.logger
    logger.should_not be_nil
    logger.should be_a(Asciicrystal::Logger)
  end

  it "should allow logger instance to be changed" do
    old_logger = Asciicrystal::LoggerManager.logger
    begin
      new_logger = Asciicrystal::MemoryLogger.new
      Asciicrystal::LoggerManager.logger = new_logger
      Asciicrystal::LoggerManager.logger.should be(new_logger)
    ensure
      Asciicrystal::LoggerManager.logger = old_logger
    end
  end

  it "should reset to default logger when set to nil" do
    old_logger = Asciicrystal::LoggerManager.logger
    begin
      Asciicrystal::LoggerManager.logger = Asciicrystal::MemoryLogger.new
      Asciicrystal::LoggerManager.logger = nil
      Asciicrystal::LoggerManager.logger.should_not be_nil
      Asciicrystal::LoggerManager.logger.should be_a(Asciicrystal::Logger)
    ensure
      Asciicrystal::LoggerManager.logger = old_logger
    end
  end
end

describe Asciicrystal::LogMessage do
  it "should create a log message with text" do
    msg = Asciicrystal::LogMessage.new(text: "test message")
    msg.text.should eq("test message")
    msg.source_location.should be_nil
  end

  it "should create a log message with text and source location" do
    msg = Asciicrystal::LogMessage.new(text: "test message", source_location: "file.adoc: line 5")
    msg.text.should eq("test message")
    msg.source_location.should eq("file.adoc: line 5")
  end

  it "should format message with source location in inspect" do
    msg = Asciicrystal::LogMessage.new(text: "test message", source_location: "file.adoc: line 5")
    msg.inspect.should eq("file.adoc: line 5: test message")
  end

  it "should format message without source location in inspect" do
    msg = Asciicrystal::LogMessage.new(text: "test message")
    msg.inspect.should eq("test message")
  end
end

describe Asciicrystal::Logging do
  it "should provide logger access through Logging module" do
    # Test that a class including Logging can access the logger
    obj = Asciicrystal::PathResolver.new # PathResolver includes Logging
    obj.logger.should_not be_nil
    obj.logger.should be(Asciicrystal::LoggerManager.logger)
  end

  it "should provide message_with_context method" do
    obj = Asciicrystal::PathResolver.new
    msg = obj.message_with_context("test message", source_location: "file.adoc: line 5")
    msg.text.should eq("test message")
    msg.source_location.should eq("file.adoc: line 5")
  end
end
