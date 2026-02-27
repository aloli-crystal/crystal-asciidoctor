require "../spec_helper"

describe Asciidoctor::Document do
  describe "#initialize" do
    it "creates a document with default values" do
      doc = Asciidoctor::Document.new
      doc.context.should eq(:document)
      doc.safe.should eq(Asciidoctor::SafeMode::SECURE)
      doc.backend.should eq("html5")
      doc.doctype.should eq("article")
      doc.base_dir.should eq(".")
    end

    it "creates a document with custom safe mode" do
      doc = Asciidoctor::Document.new(safe: Asciidoctor::SafeMode::UNSAFE)
      doc.safe.should eq(Asciidoctor::SafeMode::UNSAFE)
    end

    it "creates a document with custom backend" do
      doc = Asciidoctor::Document.new(backend: "docbook5")
      doc.backend.should eq("docbook5")
    end
  end

  describe "#document" do
    it "returns itself" do
      doc = Asciidoctor::Document.new
      doc.document.should eq(doc)
    end
  end

  describe "#block?" do
    it "returns true" do
      doc = Asciidoctor::Document.new
      doc.block?.should be_true
    end
  end

  describe "#inline?" do
    it "returns false" do
      doc = Asciidoctor::Document.new
      doc.inline?.should be_false
    end
  end

  describe "#header?" do
    it "returns false when no header is set" do
      doc = Asciidoctor::Document.new
      doc.header?.should be_false
    end
  end

  describe "#nested?" do
    it "returns false for a root document" do
      doc = Asciidoctor::Document.new
      doc.nested?.should be_false
    end
  end

  describe "#catalog" do
    it "provides access to the document catalog" do
      doc = Asciidoctor::Document.new
      doc.catalog.should_not be_nil
      doc.catalog.refs.should be_empty
      doc.catalog.footnotes.should be_empty
      doc.catalog.links.should be_empty
      doc.catalog.images.should be_empty
      doc.catalog.includes.should be_empty
    end
  end

  describe "#counters" do
    it "starts with empty counters" do
      doc = Asciidoctor::Document.new
      doc.counters.should be_empty
    end
  end

  describe "#increment_and_store_counter" do
    it "initializes a counter to 1" do
      doc = Asciidoctor::Document.new
      doc.increment_and_store_counter("example-number").should eq("1")
    end

    it "increments an existing integer counter" do
      doc = Asciidoctor::Document.new
      doc.increment_and_store_counter("example-number")
      doc.increment_and_store_counter("example-number").should eq("2")
    end
  end

  describe "#doctitle" do
    it "returns nil when no header is set" do
      doc = Asciidoctor::Document.new
      doc.doctitle.should be_nil
    end

    it "returns fallback title when use_fallback is true" do
      doc = Asciidoctor::Document.new
      doc.doctitle({:use_fallback => true}).should eq("Untitled")
    end
  end

  describe "Asciidoctor::Document::Title" do
    it "parses a simple title" do
      title = Asciidoctor::Document::Title.new("My Document")
      title.main.should eq("My Document")
      title.subtitle.should be_nil
      title.combined.should eq("My Document")
    end

    it "parses a title with subtitle" do
      title = Asciidoctor::Document::Title.new("Main Title: Subtitle Here")
      title.main.should eq("Main Title")
      title.subtitle.should eq("Subtitle Here")
      title.combined.should eq("Main Title: Subtitle Here")
    end

    it "uses the last separator for subtitle split" do
      title = Asciidoctor::Document::Title.new("Part One: Chapter: Details")
      title.main.should eq("Part One: Chapter")
      title.subtitle.should eq("Details")
    end
  end

  describe "Asciidoctor::Document::ImageReference" do
    it "stores target and imagesdir" do
      ref = Asciidoctor::Document::ImageReference.new("image.png", "images")
      ref.target.should eq("image.png")
      ref.imagesdir.should eq("images")
    end

    it "converts to string as target" do
      ref = Asciidoctor::Document::ImageReference.new("image.png", "images")
      ref.to_s.should eq("image.png")
    end
  end

  describe "Asciidoctor::Document::Footnote" do
    it "stores index, id, and text" do
      fn = Asciidoctor::Document::Footnote.new(index: 1, id: "fn1", text: "A footnote")
      fn.index.should eq(1)
      fn.id.should eq("fn1")
      fn.text.should eq("A footnote")
    end
  end
end
