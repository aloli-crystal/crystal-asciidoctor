require "../spec_helper"

# We test AbstractBlock through Block and Section since AbstractBlock is abstract
describe "AbstractBlock (via Block)" do
  describe "#title" do
    it "returns nil when no title is set" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.title.should be_nil
    end

    it "returns the title when set" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.title = "My Title"
      block.title.should eq("My Title")
    end
  end

  describe "#title?" do
    it "returns false when no title" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.title?.should be_false
    end

    it "returns true when title is set" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.title = "My Title"
      block.title?.should be_true
    end
  end

  describe "#<<" do
    it "appends a child block" do
      doc = Asciidoctor::Document.new
      parent = Asciidoctor::Block.new(doc, :open, content_model: Asciidoctor::ContentModel::Compound)
      child = Asciidoctor::Block.new(doc, :paragraph, source: "Hello")
      parent << child
      parent.blocks.size.should eq(1)
      parent.blocks[0].should eq(child)
    end
  end

  describe "#blocks?" do
    it "returns false when no child blocks" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.blocks?.should be_false
    end

    it "returns true when child blocks exist" do
      doc = Asciidoctor::Document.new
      parent = Asciidoctor::Block.new(doc, :open, content_model: Asciidoctor::ContentModel::Compound)
      parent << Asciidoctor::Block.new(doc, :paragraph)
      parent.blocks?.should be_true
    end
  end

  describe "#sections" do
    it "returns only section blocks" do
      doc = Asciidoctor::Document.new
      doc << Asciidoctor::Block.new(doc, :paragraph)
      section = Asciidoctor::Section.new(doc)
      doc << section
      doc.sections.size.should eq(1)
    end
  end

  describe "#captioned_title" do
    it "returns caption + title" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :listing)
      block.title = "My Listing"
      block.caption = "Listing 1. "
      block.captioned_title.should eq("Listing 1. My Listing")
    end
  end

  describe "#find_by" do
    it "finds blocks by context" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      doc << section
      para1 = Asciidoctor::Block.new(doc, :paragraph)
      section << para1
      para2 = Asciidoctor::Block.new(doc, :paragraph)
      section << para2
      listing = Asciidoctor::Block.new(doc, :listing)
      section << listing

      results = doc.find_by(context: :paragraph)
      results.size.should eq(2)
    end

    it "finds blocks by style" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.style = "source"
      doc << block
      doc << Asciidoctor::Block.new(doc, :paragraph)

      results = doc.find_by(style: "source")
      results.size.should eq(1)
    end

    it "finds blocks by id" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.id = "my-block"
      doc << block

      results = doc.find_by(id: "my-block")
      results.size.should eq(1)
      results[0].id.should eq("my-block")
    end

    it "finds nested blocks" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc)
      doc << section
      para = Asciidoctor::Block.new(doc, :paragraph)
      section << para
      nested_section = Asciidoctor::Section.new(doc, parent: section, level: 2)
      section << nested_section
      nested_para = Asciidoctor::Block.new(doc, :paragraph)
      nested_section << nested_para

      results = doc.find_by(context: :paragraph)
      results.size.should eq(2)
    end
  end

  describe "#context=" do
    it "updates the context and node_name" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.context = :listing
      block.context.should eq(:listing)
      block.node_name.should eq("listing")
    end
  end

  describe "#source_location" do
    it "can be set and retrieved" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      loc = Asciidoctor::SourceLocation.new("test.adoc", 42)
      block.source_location = loc
      block.file.should eq("test.adoc")
      block.lineno.should eq(42)
    end
  end
end
