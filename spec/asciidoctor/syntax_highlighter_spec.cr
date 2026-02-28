require "../spec_helper"

# A simple test syntax highlighter for testing the registry.
class TestSyntaxHighlighter < Asciidoctor::SyntaxHighlighterBase
  register_for "test_highlighter"

  def initialize(name : String = "test_highlighter", backend : String = "html5")
    super(name, backend)
  end

  def highlight? : Bool
    true
  end

  def highlight(node : Asciidoctor::AbstractNode, source : String, lang : String, opts : Hash(Symbol, String) = {} of Symbol => String) : String
    %(<span class="test-hl">#{source}</span>)
  end
end

describe Asciidoctor::SyntaxHighlighter do
  describe "DefaultRegistry" do
    it "registers a syntax highlighter for a name" do
      klass = Asciidoctor::SyntaxHighlighter::DefaultRegistry.for("test_highlighter")
      klass.should eq TestSyntaxHighlighter
    end

    it "creates a syntax highlighter instance" do
      instance = Asciidoctor::SyntaxHighlighter::DefaultRegistry.create("test_highlighter")
      instance.should_not be_nil
      instance.not_nil!.name.should eq "test_highlighter"
    end

    it "returns nil for an unregistered name" do
      klass = Asciidoctor::SyntaxHighlighter::DefaultRegistry.for("nonexistent_hl_xyz")
      klass.should be_nil
    end

    it "registers highlight.js adapter" do
      klass = Asciidoctor::SyntaxHighlighter::DefaultRegistry.for("highlightjs")
      klass.should eq Asciidoctor::HighlightJsAdapter
    end

    it "registers highlight.js adapter under alternate name" do
      klass = Asciidoctor::SyntaxHighlighter::DefaultRegistry.for("highlight.js")
      klass.should eq Asciidoctor::HighlightJsAdapter
    end
  end

  describe "CustomFactory" do
    it "creates an empty factory" do
      factory = Asciidoctor::SyntaxHighlighter::CustomFactory.new
      factory.for("highlightjs").should be_nil
    end

    it "registers and retrieves a syntax highlighter" do
      factory = Asciidoctor::SyntaxHighlighter::CustomFactory.new
      factory.register(TestSyntaxHighlighter, "custom_hl")
      klass = factory.for("custom_hl")
      klass.should eq TestSyntaxHighlighter
    end

    it "creates a syntax highlighter instance" do
      factory = Asciidoctor::SyntaxHighlighter::CustomFactory.new
      factory.register(TestSyntaxHighlighter, "custom_hl")
      instance = factory.create("custom_hl")
      instance.should_not be_nil
      instance.not_nil!.name.should eq "custom_hl"
    end

    it "initializes with a seed registry" do
      seed = {"seeded_hl" => TestSyntaxHighlighter.as(Asciidoctor::SyntaxHighlighterBase.class)}
      factory = Asciidoctor::SyntaxHighlighter::CustomFactory.new(seed)
      factory.for("seeded_hl").should eq TestSyntaxHighlighter
    end
  end
end

describe Asciidoctor::SyntaxHighlighterBase do
  describe "#initialize" do
    it "sets name and pre_class" do
      hl = TestSyntaxHighlighter.new("myhl")
      hl.name.should eq "myhl"
      hl.pre_class.should eq "myhl"
    end
  end

  describe "#highlight?" do
    it "returns false by default" do
      hl = Asciidoctor::HighlightJsAdapter.new
      hl.highlight?.should be_false
    end

    it "returns true for server-side highlighters" do
      hl = TestSyntaxHighlighter.new
      hl.highlight?.should be_true
    end
  end

  describe "#docinfo?" do
    it "returns false by default for base class" do
      hl = TestSyntaxHighlighter.new
      hl.docinfo?(:head).should be_false
    end
  end

  describe "#format" do
    it "generates pre/code markup with language" do
      hl = TestSyntaxHighlighter.new
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :listing)
      block.lines = ["puts 'hello'"]
      result = hl.format(block, "ruby")
      result.should contain "pre"
      result.should contain %(data-lang="ruby")
    end

    it "generates pre/code markup without language" do
      hl = TestSyntaxHighlighter.new
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :listing)
      block.lines = ["some code"]
      result = hl.format(block, nil)
      result.should contain "pre"
      result.should_not contain "data-lang"
    end
  end
end

describe Asciidoctor::HighlightJsAdapter do
  describe "#initialize" do
    it "sets name to highlightjs" do
      hl = Asciidoctor::HighlightJsAdapter.new
      hl.name.should eq "highlightjs"
      hl.pre_class.should eq "highlightjs"
    end
  end

  describe "#docinfo?" do
    it "returns true for both head and footer" do
      hl = Asciidoctor::HighlightJsAdapter.new
      hl.docinfo?(:head).should be_true
      hl.docinfo?(:footer).should be_true
    end
  end

  describe "#docinfo" do
    it "generates stylesheet link for head" do
      hl = Asciidoctor::HighlightJsAdapter.new
      doc = Asciidoctor::Document.new
      result = hl.docinfo(:head, doc)
      result.should contain "link"
      result.should contain "stylesheet"
      result.should contain "highlight.js"
      result.should contain "github.min.css"
    end

    it "uses custom theme when set" do
      hl = Asciidoctor::HighlightJsAdapter.new
      doc = Asciidoctor::Document.new
      doc.attributes["highlightjs-theme"] = "monokai"
      result = hl.docinfo(:head, doc)
      result.should contain "monokai.min.css"
    end

    it "generates script tags for footer" do
      hl = Asciidoctor::HighlightJsAdapter.new
      doc = Asciidoctor::Document.new
      result = hl.docinfo(:footer, doc)
      result.should contain "script"
      result.should contain "highlight.min.js"
      result.should contain "hljs.initHighlighting"
    end

    it "includes additional language scripts when specified" do
      hl = Asciidoctor::HighlightJsAdapter.new
      doc = Asciidoctor::Document.new
      doc.attributes["highlightjs-languages"] = "ruby, python"
      result = hl.docinfo(:footer, doc)
      result.should contain "ruby.min.js"
      result.should contain "python.min.js"
    end

    it "uses custom base URL when highlightjsdir is set" do
      hl = Asciidoctor::HighlightJsAdapter.new
      doc = Asciidoctor::Document.new
      doc.attributes["highlightjsdir"] = "https://example.com/hljs"
      result = hl.docinfo(:head, doc)
      result.should contain "https://example.com/hljs"
    end
  end

  describe "#format" do
    it "generates pre/code markup with hljs class" do
      hl = Asciidoctor::HighlightJsAdapter.new
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :listing)
      block.lines = ["puts 'hello'"]
      result = hl.format(block, "ruby")
      result.should contain %(class="highlightjs highlight")
      result.should contain %(class="language-ruby hljs")
      result.should contain %(data-lang="ruby")
    end

    it "uses 'none' when no language is specified" do
      hl = Asciidoctor::HighlightJsAdapter.new
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :listing)
      block.lines = ["some code"]
      result = hl.format(block, nil)
      result.should contain %(class="language-none hljs")
    end
  end

  describe "#highlight?" do
    it "returns false (client-side highlighting)" do
      hl = Asciidoctor::HighlightJsAdapter.new
      hl.highlight?.should be_false
    end
  end
end
