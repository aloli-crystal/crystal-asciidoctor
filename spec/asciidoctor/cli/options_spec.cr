require "../../spec_helper"

describe Asciidoctor::Cli::Options do
  describe ".new" do
    it "creates options with default values" do
      opts = Asciidoctor::Cli::Options.new
      opts.backend.should eq("html5")
      opts.doctype.should eq("article")
      opts.safe_mode.should eq(Asciidoctor::SafeMode::UNSAFE)
      opts.standalone.should be_true
      opts.verbose.should eq(1)
      opts.sourcemap.should be_false
      opts.embedded.should be_false
    end
  end

  describe "#to_options_hash" do
    it "converts options to a hash" do
      opts = Asciidoctor::Cli::Options.new
      hash = opts.to_options_hash
      hash["backend"].should eq("html5")
      hash["doctype"].should eq("article")
      hash["standalone"].should eq("true")
    end

    it "includes attributes when set" do
      opts = Asciidoctor::Cli::Options.new
      opts.attributes["toc"] = "left"
      hash = opts.to_options_hash
      hash["attributes"]?.should_not be_nil
      hash["attributes"].should contain("toc=left")
    end
  end
end
