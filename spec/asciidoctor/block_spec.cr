require "../spec_helper"

describe Asciidoctor::Block do
  describe "#initialize" do
    it "creates a block with default content model for paragraph" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.context.should eq(:paragraph)
      block.content_model.should eq(Asciidoctor::ContentModel::Simple)
      block.lines.should be_empty
    end

    it "creates a block with default content model for listing" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :listing)
      block.content_model.should eq(Asciidoctor::ContentModel::Verbatim)
    end

    it "creates a block with default content model for image" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :image)
      block.content_model.should eq(Asciidoctor::ContentModel::Empty)
    end

    it "creates a block with source string" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, source: "Hello World")
      block.lines.should eq(["Hello World"])
    end

    it "creates a block with source array" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, source: ["line 1", "line 2"])
      block.lines.should eq(["line 1", "line 2"])
    end

    it "creates a block with custom content model" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :open, content_model: Asciidoctor::ContentModel::Simple)
      block.content_model.should eq(Asciidoctor::ContentModel::Simple)
    end
  end

  describe "#block?" do
    it "returns true" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.block?.should be_true
    end
  end

  describe "#inline?" do
    it "returns false" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.inline?.should be_false
    end
  end

  describe "#source" do
    it "returns the joined lines" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, source: ["line 1", "line 2"])
      block.source.should eq("line 1\nline 2")
    end
  end

  describe "#content" do
    it "returns joined lines for simple content model" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, source: ["Hello", "World"])
      block.content.should eq("Hello\nWorld")
    end

    it "returns nil for empty content model" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :image)
      block.content.should be_nil
    end

    it "strips leading and trailing blank lines for verbatim content" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :listing, source: ["", "code here", "more code", ""])
      block.content.should eq("code here\nmore code")
    end
  end

  describe "#document" do
    it "returns the parent document" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.document.should eq(doc)
    end
  end

  describe "#level" do
    it "inherits level from parent" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.level.should eq(0)
    end
  end
end
