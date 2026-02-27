require "../spec_helper"

describe Asciidoctor::Section do
  describe "#initialize" do
    it "creates a section with default level 1" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.context.should eq(:section)
      section.level.should eq(1)
      section.numbered.should be_false
      section.special.should be_false
    end

    it "creates a section with custom level" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc, level: 2)
      section.level.should eq(2)
    end

    it "creates a numbered section" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc, numbered: true)
      section.numbered.should be_true
    end

    it "inherits special from parent section" do
      doc = Asciidoctor::Document.new
      parent = Asciidoctor::Section.new(doc, level: 1)
      parent.special = true
      child = Asciidoctor::Section.new(doc, parent: parent, level: 2)
      child.special.should be_true
    end
  end

  describe "#block?" do
    it "returns true" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.block?.should be_true
    end
  end

  describe "#name" do
    it "returns the title" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.title = "Introduction"
      section.name.should eq("Introduction")
    end
  end

  describe "#sectnum" do
    it "returns the section number with default delimiter" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc, level: 1, numbered: true)
      section.numeral = "1"
      section.sectnum.should eq("1.")
    end

    it "returns nested section number" do
      doc = Asciidoctor::Document.new
      parent = Asciidoctor::Section.new(doc, level: 1, numbered: true)
      parent.numeral = "1"
      child = Asciidoctor::Section.new(doc, parent: parent, level: 2, numbered: true)
      child.numeral = "2"
      child.sectnum.should eq("1.2.")
    end
  end

  describe "#sections?" do
    it "returns false when no child sections" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.sections?.should be_false
    end
  end

  describe "#<<" do
    it "appends a block to the section" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      block = Asciidoctor::Block.new(doc, :paragraph, source: "Hello")
      section << block
      section.blocks.size.should eq(1)
    end
  end
end
