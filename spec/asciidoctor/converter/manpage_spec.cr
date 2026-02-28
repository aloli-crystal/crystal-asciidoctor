require "../../spec_helper"

describe Asciidoctor::Converter::ManPageConverter do
  converter = Asciidoctor::Converter::ManPageConverter.new("manpage")

  describe "#convert_paragraph" do
    it "converts a simple paragraph" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(parent_block: doc, context: :paragraph, content_model: Asciidoctor::ContentModel::Simple)
      block.lines = ["Hello World"]
      result = converter.convert_paragraph(block)
      result.should contain("Hello World")
    end
  end

  describe "#convert_section" do
    it "converts a section with title" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(document: doc, parent: doc)
      section.title = "SYNOPSIS"
      section.level = 1
      result = converter.convert_section(section)
      result.should contain(".SH")
      result.should contain("SYNOPSIS")
    end
  end

  describe "#convert_literal" do
    it "converts a literal block" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(parent_block: doc, context: :literal, content_model: Asciidoctor::ContentModel::Verbatim)
      block.lines = ["literal text"]
      result = converter.convert_literal(block)
      result.should contain(".sp")
      result.should contain("literal text")
    end
  end

  describe "#convert_listing" do
    it "converts a listing block" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(parent_block: doc, context: :listing, content_model: Asciidoctor::ContentModel::Verbatim)
      block.lines = ["code here"]
      result = converter.convert_listing(block)
      result.should contain(".sp")
      result.should contain("code here")
    end
  end

  describe "#convert_inline_quoted" do
    it "converts emphasis" do
      doc = Asciidoctor::Document.new
      node = Asciidoctor::Inline.new(parent_block: doc, context: :quoted, text: "emphasized", type: :emphasis)
      result = converter.convert_inline_quoted(node)
      result.should contain("\\fI")
      result.should contain("emphasized")
      result.should contain("\\fP")
    end

    it "converts strong" do
      doc = Asciidoctor::Document.new
      node = Asciidoctor::Inline.new(parent_block: doc, context: :quoted, text: "bold", type: :strong)
      result = converter.convert_inline_quoted(node)
      result.should contain("\\fB")
      result.should contain("bold")
      result.should contain("\\fP")
    end
  end

  describe "#convert_inline_anchor" do
    it "converts a link" do
      doc = Asciidoctor::Document.new
      node = Asciidoctor::Inline.new(parent_block: doc, context: :anchor, text: "Example", type: :link)
      node.target = "https://example.com"
      result = converter.convert_inline_anchor(node)
      result.should contain("Example")
    end
  end

  describe "#convert_admonition" do
    it "converts an admonition block" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(parent_block: doc, context: :admonition, content_model: Asciidoctor::ContentModel::Compound)
      block.style = "NOTE"
      block.attributes["name"] = "note"
      result = converter.convert_admonition(block)
      result.should contain("Note")
    end
  end
end
