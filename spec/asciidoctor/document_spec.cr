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

  describe "#<<" do
    it "assigns numeral to sections when appended" do
      doc = Asciidoctor::Document.new
      section = Asciidoctor::Section.new(doc, numbered: true)
      doc << section
      section.index.should eq(0)
    end
  end

  describe "#author" do
    it "returns nil when no author is set" do
      doc = Asciidoctor::Document.new
      doc.author.should be_nil
    end

    it "returns the author attribute" do
      doc = Asciidoctor::Document.new
      doc.attributes["author"] = "John Doe"
      doc.author.should eq("John Doe")
    end
  end

  describe "#authors" do
    it "returns empty array when no authors" do
      doc = Asciidoctor::Document.new
      doc.authors.should be_empty
    end

    it "returns a single author" do
      doc = Asciidoctor::Document.new
      doc.attributes["author"] = "John Doe"
      doc.authors.should eq(["John Doe"])
    end

    it "returns multiple authors" do
      doc = Asciidoctor::Document.new
      doc.attributes["author"] = "John Doe"
      doc.attributes["author_2"] = "Jane Smith"
      doc.authors.should eq(["John Doe", "Jane Smith"])
    end
  end

  describe "#basebackend?" do
    it "returns true when backend starts with base" do
      doc = Asciidoctor::Document.new(backend: "html5")
      doc.basebackend?("html").should be_true
    end

    it "returns false when backend does not start with base" do
      doc = Asciidoctor::Document.new(backend: "html5")
      doc.basebackend?("docbook").should be_false
    end
  end

  describe "#block?" do
    it "returns true" do
      doc = Asciidoctor::Document.new
      doc.block?.should be_true
    end
  end

  describe "#catalog" do
    it "provides access to the document catalog" do
      doc = Asciidoctor::Document.new
      doc.catalog.should_not be_nil
      doc.catalog.footnotes.should be_empty
      doc.catalog.images.should be_empty
      doc.catalog.includes.should be_empty
      doc.catalog.links.should be_empty
      doc.catalog.refs.should be_empty
    end
  end

  describe "#counters" do
    it "starts with empty counters" do
      doc = Asciidoctor::Document.new
      doc.counters.should be_empty
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

  describe "#document" do
    it "returns itself" do
      doc = Asciidoctor::Document.new
      doc.document.should eq(doc)
    end
  end

  describe "#embedded?" do
    it "returns false by default" do
      doc = Asciidoctor::Document.new
      doc.embedded?.should be_false
    end

    it "returns true when embedded attribute is set" do
      doc = Asciidoctor::Document.new
      doc.attributes["embedded"] = ""
      doc.embedded?.should be_true
    end
  end

  describe "#extensions?" do
    it "returns false by default" do
      doc = Asciidoctor::Document.new
      doc.extensions?.should be_false
    end
  end

  describe "#first_section" do
    it "returns nil when no sections" do
      doc = Asciidoctor::Document.new
      doc.first_section.should be_nil
    end

    it "returns the first section" do
      doc = Asciidoctor::Document.new
      doc << Asciidoctor::Block.new(doc, :paragraph)
      section = Asciidoctor::Section.new(doc)
      section.title = "First"
      doc << section
      doc.first_section.should eq(section)
    end
  end

  describe "#header?" do
    it "returns false when no header is set" do
      doc = Asciidoctor::Document.new
      doc.header?.should be_false
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

  describe "#inline?" do
    it "returns false" do
      doc = Asciidoctor::Document.new
      doc.inline?.should be_false
    end
  end

  describe "#multipart?" do
    it "returns false for article doctype" do
      doc = Asciidoctor::Document.new
      doc.multipart?.should be_false
    end
  end

  describe "#nested?" do
    it "returns false for a root document" do
      doc = Asciidoctor::Document.new
      doc.nested?.should be_false
    end
  end

  describe "#nofooter" do
    it "returns false by default" do
      doc = Asciidoctor::Document.new
      doc.nofooter.should be_false
    end
  end

  describe "#noheader" do
    it "returns false by default" do
      doc = Asciidoctor::Document.new
      doc.noheader.should be_false
    end
  end

  describe "#notitle" do
    it "returns false by default" do
      doc = Asciidoctor::Document.new
      doc.notitle.should be_false
    end
  end

  describe "#register" do
    it "registers a link" do
      doc = Asciidoctor::Document.new
      doc.register(:links, "https://example.com")
      doc.catalog.links.should eq(["https://example.com"])
    end

    it "registers an image" do
      doc = Asciidoctor::Document.new
      doc.register(:images, "photo.png")
      doc.catalog.images.size.should eq(1)
      doc.catalog.images[0].target.should eq("photo.png")
    end

    it "registers an include" do
      doc = Asciidoctor::Document.new
      doc.register(:includes, "chapter1.adoc")
      doc.catalog.includes["chapter1.adoc"].should be_true
    end
  end

  describe "#revdate" do
    it "returns nil when not set" do
      doc = Asciidoctor::Document.new
      doc.revdate.should be_nil
    end

    it "returns the revdate attribute" do
      doc = Asciidoctor::Document.new
      doc.attributes["revdate"] = "2026-01-01"
      doc.revdate.should eq("2026-01-01")
    end
  end

  describe "#sections?" do
    it "returns false when no sections" do
      doc = Asciidoctor::Document.new
      doc.sections?.should be_false
    end
  end

  describe "#xreftext" do
    it "returns the doctitle" do
      doc = Asciidoctor::Document.new
      doc.xreftext.should be_nil
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
end
