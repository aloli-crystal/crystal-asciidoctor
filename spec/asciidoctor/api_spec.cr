require "../spec_helper"

describe Asciidoctor do
  describe ".load" do
    it "loads a simple document" do
      doc = Asciidoctor.load("= My Title\n\nHello World")
      doc.should be_a(Asciidoctor::Document)
    end

    it "loads a document with backend option" do
      doc = Asciidoctor.load("= My Title\n\nHello", {"backend" => "html5"})
      doc.backend.should eq("html5")
    end

    it "loads a document with doctype option" do
      doc = Asciidoctor.load("= My Title\n\nHello", {"doctype" => "book"})
      doc.doctype.should eq("book")
    end

    it "loads a document with safe mode" do
      doc = Asciidoctor.load("= My Title\n\nHello", {"safe" => "safe"})
      doc.safe.should eq(Asciidoctor::SafeMode::SAFE)
    end

    it "loads a document with attributes" do
      doc = Asciidoctor.load("= My Title\n\nHello", {"attributes" => "toc=left,icons=font"})
      # After save_attributes, toc value is normalized per Ruby AsciiDoctor behavior:
      # toc-placement defaults to 'macro' (not 'auto'), so position resolves to 'macro'
      doc.attributes["toc"]?.should eq("")
      doc.attributes["toc-position"]?.should eq("content")
      doc.attributes["toc-placement"]?.should eq("macro")
      doc.attributes["icons"]?.should eq("font")
    end

    it "creates a converter for the document" do
      doc = Asciidoctor.load("= My Title\n\nHello")
      doc.converter.should_not be_nil
    end

    it "creates an html5 converter by default" do
      doc = Asciidoctor.load("Hello")
      doc.converter.should be_a(Asciidoctor::Converter::Html5Converter)
    end

    it "creates a docbook5 converter when backend is docbook5" do
      doc = Asciidoctor.load("Hello", {"backend" => "docbook5"})
      doc.converter.should be_a(Asciidoctor::Converter::DocBook5Converter)
    end

    it "creates a manpage converter when backend is manpage" do
      doc = Asciidoctor.load("Hello", {"backend" => "manpage"})
      doc.converter.should be_a(Asciidoctor::Converter::ManPageConverter)
    end
  end

  describe ".convert" do
    it "converts a simple paragraph to HTML" do
      result = Asciidoctor.convert("Hello World")
      result.should contain("Hello World")
    end

    it "converts with docbook backend" do
      result = Asciidoctor.convert("Hello World", {"backend" => "docbook5"})
      result.should contain("<simpara>")
    end
  end
end
