require "../spec_helper"

describe Asciidoctor::Section do
  describe "#initialize" do
    it "creates a section with default values" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.context.should eq(:section)
      section.level.should eq(1)
      section.numbered.should be_false
      section.special.should be_false
      section.index.should eq(0)
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

    it "inherits level from parent section" do
      doc = Asciidoctor::Document.new
      parent = Asciidoctor::Section.new(doc, level: 1)
      child = Asciidoctor::Section.new(doc, parent: parent)
      child.level.should eq(2)
    end

    it "inherits special from parent section" do
      doc = Asciidoctor::Document.new
      parent = Asciidoctor::Section.new(doc, level: 1)
      parent.special = true
      child = Asciidoctor::Section.new(doc, parent: parent)
      child.special.should be_true
    end

    it "sets parent reference" do
      doc = Asciidoctor::Document.new
      parent = Asciidoctor::Section.new(doc, level: 1)
      child = Asciidoctor::Section.new(doc, parent: parent)
      child.parent.should eq(parent)
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

    it "assigns numeral to child sections" do
      doc = Asciidoctor::Document.new
      parent = Asciidoctor::Section.new(doc, level: 1, numbered: true)
      parent.numeral = "1"
      child1 = Asciidoctor::Section.new(doc, parent: parent, numbered: true)
      parent << child1
      child1.index.should eq(0)
    end
  end

  describe "#block?" do
    it "returns true" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.block?.should be_true
    end
  end

  describe "#generate_id" do
    it "generates an id from the title" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.title = "My First Section"
      section.generate_id.should eq("_my_first_section")
    end

    it "returns nil when no title" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.generate_id.should be_nil
    end
  end

  describe ".generate_id" do
    it "generates an id from a title string" do
      doc = Asciidoctor::Document.new
      Asciidoctor::Section.generate_id("Hello World", doc).should eq("_hello_world")
    end

    it "respects custom idprefix" do
      doc = Asciidoctor::Document.new
      doc.attributes["idprefix"] = "id-"
      Asciidoctor::Section.generate_id("Hello World", doc).should eq("id-hello_world")
    end

    it "respects custom idseparator" do
      doc = Asciidoctor::Document.new
      doc.attributes["idseparator"] = "-"
      Asciidoctor::Section.generate_id("Hello World", doc).should eq("_hello-world")
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
    it "returns the section number with delimiter" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc, numbered: true)
      section.numeral = "1"
      section.sectnum.should eq("1.")
    end

    it "returns nested section number" do
      doc = Asciidoctor::Document.new
      parent = Asciidoctor::Section.new(doc, level: 1, numbered: true)
      parent.numeral = "1"
      child = Asciidoctor::Section.new(doc, parent: parent, numbered: true)
      child.numeral = "2"
      child.sectnum.should eq("1.2.")
    end

    it "supports custom delimiter" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc, numbered: true)
      section.numeral = "1"
      section.sectnum("-").should eq("1-")
    end

    it "supports custom append" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc, numbered: true)
      section.numeral = "1"
      section.sectnum(".", "").should eq("1")
    end
  end

  describe "#sections?" do
    it "returns false when no child sections" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.sections?.should be_false
    end

    it "returns true when child sections exist" do
      doc = Asciidoctor::Document.new
      parent = Asciidoctor::Section.new(doc)
      child = Asciidoctor::Section.new(doc, parent: parent)
      parent << child
      parent.sections?.should be_true
    end
  end

  describe "#xreftext" do
    it "returns reftext when set" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.set_attr("reftext", "See here")
      section.xreftext.should eq("See here")
    end

    it "returns title when no reftext and no xrefstyle" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.title = "Introduction"
      section.xreftext.should eq("Introduction")
    end

    it "returns full xreftext with numbered section" do
      doc = Asciidoctor::Document.new
      doc.attributes["section-refsig"] = "Section"
      section = Asciidoctor::Section.new(doc, numbered: true)
      section.title = "Introduction"
      section.numeral = "1"
      section.sectname = "section"
      section.xreftext("full").should eq("Section 1, \"Introduction\"")
    end

    it "returns short xreftext with numbered section" do
      doc = Asciidoctor::Document.new
      doc.attributes["section-refsig"] = "Section"
      section = Asciidoctor::Section.new(doc, numbered: true)
      section.title = "Introduction"
      section.numeral = "1"
      section.sectname = "section"
      section.xreftext("short").should eq("Section 1")
    end

    it "returns basic xreftext (title only)" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      section.title = "Introduction"
      section.xreftext("basic").should eq("Introduction")
    end
  end
end
