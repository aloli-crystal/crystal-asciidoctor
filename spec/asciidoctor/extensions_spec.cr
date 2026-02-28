require "../spec_helper"

# =============================================================================
# Test Processors — simple implementations for testing each extension type
# =============================================================================

# A Preprocessor that adds a line at the beginning of the source.
class SamplePreprocessor < Asciidoctor::Extensions::Preprocessor
  def process(document : Asciidoctor::Document, reader : Asciidoctor::Reader) : Asciidoctor::Reader?
    document.attributes["preprocessor-ran"] = "true"
    nil
  end
end

# A Preprocessor that replaces lines.
class PrependLinePreprocessor < Asciidoctor::Extensions::Preprocessor
  def process(document : Asciidoctor::Document, reader : Asciidoctor::Reader) : Asciidoctor::Reader?
    new_lines = ["// Prepended by extension"] + reader.lines
    Asciidoctor::Reader.new(new_lines)
  end
end

# A TreeProcessor that sets an attribute on the document.
class SampleTreeProcessor < Asciidoctor::Extensions::TreeProcessor
  def process(document : Asciidoctor::Document) : Asciidoctor::Document?
    document.attributes["tree-processor-ran"] = "true"
    nil
  end
end

# A TreeProcessor that replaces the author attribute.
class ReplaceAuthorTreeProcessor < Asciidoctor::Extensions::TreeProcessor
  def process(document : Asciidoctor::Document) : Asciidoctor::Document?
    document.attributes["firstname"] = "Ghost"
    document.attributes["author"] = "Ghost Writer"
    document
  end
end

# A Postprocessor that uppercases the output.
class UppercasePostprocessor < Asciidoctor::Extensions::Postprocessor
  def process(document : Asciidoctor::Document, output : String) : String
    output.upcase
  end
end

# A Postprocessor that strips HTML attributes.
class StripAttributesPostprocessor < Asciidoctor::Extensions::Postprocessor
  def process(document : Asciidoctor::Document, output : String) : String
    output.gsub(/<(\w+)[^>]*>/, "<\\1>")
  end
end

# An IncludeProcessor that handles .txt targets.
class BoilerplateIncludeProcessor < Asciidoctor::Extensions::IncludeProcessor
  def handles?(target : String) : Bool
    target.ends_with?(".txt")
  end

  def process(document : Asciidoctor::Document, reader : Asciidoctor::Reader, target : String, attributes : Hash(String, String)) : Nil
    document.attributes["include-processor-ran"] = target
  end
end

# A DocinfoProcessor that injects a meta tag in the head.
class MetaRobotsDocinfoProcessor < Asciidoctor::Extensions::DocinfoProcessor
  def process(document : Asciidoctor::Document) : String
    "<meta name=\"robots\" content=\"index,follow\">"
  end
end

# A DocinfoProcessor at footer location.
class FooterDocinfoProcessor < Asciidoctor::Extensions::DocinfoProcessor
  def initialize
    super({"location" => :footer} of String => String | Bool | Int32 | Array(String) | Set(Symbol) | Symbol)
  end

  def process(document : Asciidoctor::Document) : String
    "<script>console.log('footer')</script>"
  end
end

# A BlockProcessor that uppercases paragraph content.
class UppercaseBlockProcessor < Asciidoctor::Extensions::BlockProcessor
  def initialize
    super("yell")
  end

  def process(parent : Asciidoctor::AbstractBlock, reader : Asciidoctor::Reader, attributes : Hash(String, String)) : Asciidoctor::AbstractBlock?
    lines = reader.lines.map(&.upcase)
    create_paragraph(parent, lines, attributes)
  end
end

# A BlockMacroProcessor that creates a pass block with a script tag.
class SnippetBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
  def initialize
    super("snippet")
  end

  def process(parent : Asciidoctor::AbstractBlock, target : String, attributes : Hash(String, String)) : Asciidoctor::AbstractBlock | Asciidoctor::Inline | Nil
    mode = attributes["mode"]? || "default"
    create_pass_block(parent, %(<script src="http://example.com/#{target}.js?_mode=#{mode}"></script>), {} of String => String)
  end
end

# A BlockMacroProcessor that creates an image block.
class TestImageBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
  def initialize
    super("testimg")
  end

  def process(parent : Asciidoctor::AbstractBlock, target : String, attributes : Hash(String, String)) : Asciidoctor::AbstractBlock | Asciidoctor::Inline | Nil
    create_image_block(parent, {"target" => "#{target}.png"})
  end
end

# An InlineMacroProcessor for a temperature conversion macro.
class TemperatureInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
  def initialize
    super("degrees")
  end

  def process(parent : Asciidoctor::AbstractBlock, target : String, attributes : Hash(String, String)) : Asciidoctor::AbstractBlock | Asciidoctor::Inline | Nil
    units = attributes["1"]? || "C"
    c = target.to_f
    text = case units
           when "F"
             "#{(c * 1.8 + 32).round(1)} F"
           else
             "#{c.round(1)} C"
           end
    create_inline(parent, :quoted, text, {"type" => :unquoted} of String => String | Symbol)
  end
end

# A Group that registers a preprocessor.
class SampleExtensionGroup < Asciidoctor::Extensions::Group
  def activate(registry : Asciidoctor::Extensions::Registry) : Nil
    if doc = registry.document
      doc.attributes["activate-method-called"] = ""
    end
    registry.preprocessor(SamplePreprocessor.new)
  end
end

# A Group that registers multiple extensions.
class MultiExtensionGroup < Asciidoctor::Extensions::Group
  def activate(registry : Asciidoctor::Extensions::Registry) : Nil
    registry.preprocessor(SamplePreprocessor.new)
    registry.tree_processor(SampleTreeProcessor.new)
  end
end

# =============================================================================
# Tests
# =============================================================================

describe Asciidoctor::Extensions do
  # ---------------------------------------------------------------------------
  # Global Registration
  # ---------------------------------------------------------------------------
  describe ".register and .unregister_all" do
    it "should not have any groups registered by default" do
      Asciidoctor::Extensions.unregister_all
      Asciidoctor::Extensions.groups.should be_empty
    end

    it "should register an extension group class" do
      begin
        Asciidoctor::Extensions.register(:sample, SampleExtensionGroup)
        Asciidoctor::Extensions.groups.size.should eq(1)
        Asciidoctor::Extensions.groups[:sample].should eq(SampleExtensionGroup)
      ensure
        Asciidoctor::Extensions.unregister_all
      end
    end

    it "should register an extension group instance" do
      begin
        instance = SampleExtensionGroup.new
        Asciidoctor::Extensions.register(:sample, instance)
        Asciidoctor::Extensions.groups.size.should eq(1)
        Asciidoctor::Extensions.groups[:sample].should be_a(SampleExtensionGroup)
      ensure
        Asciidoctor::Extensions.unregister_all
      end
    end

    it "should self-register an extension group class" do
      begin
        SampleExtensionGroup.register(:sample)
        Asciidoctor::Extensions.groups.size.should eq(1)
        Asciidoctor::Extensions.groups[:sample].should eq(SampleExtensionGroup)
      ensure
        Asciidoctor::Extensions.unregister_all
      end
    end

    it "should generate a name if none is given" do
      begin
        Asciidoctor::Extensions.register(nil, SampleExtensionGroup)
        Asciidoctor::Extensions.groups.size.should eq(1)
      ensure
        Asciidoctor::Extensions.unregister_all
      end
    end

    it "should unregister all groups" do
      Asciidoctor::Extensions.register(:a, SampleExtensionGroup)
      Asciidoctor::Extensions.register(:b, SampleExtensionGroup)
      Asciidoctor::Extensions.groups.size.should eq(2)
      Asciidoctor::Extensions.unregister_all
      Asciidoctor::Extensions.groups.should be_empty
    end

    it "should unregister specific groups by name" do
      begin
        Asciidoctor::Extensions.register(:a, SampleExtensionGroup)
        Asciidoctor::Extensions.register(:b, SampleExtensionGroup)
        Asciidoctor::Extensions.unregister(:a)
        Asciidoctor::Extensions.groups.size.should eq(1)
        Asciidoctor::Extensions.groups.has_key?(:b).should be_true
      ensure
        Asciidoctor::Extensions.unregister_all
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Registry
  # ---------------------------------------------------------------------------
  describe Asciidoctor::Extensions::Registry do
    describe "#initialize" do
      it "creates an empty registry" do
        registry = Asciidoctor::Extensions::Registry.new
        registry.preprocessors?.should be_false
        registry.tree_processors?.should be_false
        registry.postprocessors?.should be_false
        registry.include_processors?.should be_false
        registry.docinfo_processors?.should be_false
        registry.blocks?.should be_false
        registry.block_macros?.should be_false
        registry.inline_macros?.should be_false
      end
    end

    describe "#activate" do
      it "activates the registry with a document" do
        registry = Asciidoctor::Extensions::Registry.new
        doc = Asciidoctor::Document.new
        registry.activate(doc)
        registry.document.should eq(doc)
      end

      it "activates groups registered on the registry" do
        groups = {
          :sample => SampleExtensionGroup.new.as(Asciidoctor::Extensions::Group.class | Asciidoctor::Extensions::Group),
        }
        registry = Asciidoctor::Extensions::Registry.new(groups)
        doc = Asciidoctor::Document.new
        registry.activate(doc)
        registry.preprocessors?.should be_true
        doc.attributes["activate-method-called"]?.should eq("")
      end
    end

    # ---- Preprocessor registration ----
    describe "#preprocessor" do
      it "registers a preprocessor" do
        registry = Asciidoctor::Extensions::Registry.new
        processor = SamplePreprocessor.new
        registry.preprocessor(processor)
        registry.preprocessors?.should be_true
        registry.preprocessors.size.should eq(1)
      end

      it "registers multiple preprocessors in order" do
        registry = Asciidoctor::Extensions::Registry.new
        registry.preprocessor(SamplePreprocessor.new)
        registry.preprocessor(PrependLinePreprocessor.new)
        registry.preprocessors.size.should eq(2)
      end
    end

    # ---- TreeProcessor registration ----
    describe "#tree_processor" do
      it "registers a tree processor" do
        registry = Asciidoctor::Extensions::Registry.new
        registry.tree_processor(SampleTreeProcessor.new)
        registry.tree_processors?.should be_true
        registry.tree_processors.size.should eq(1)
      end
    end

    # ---- Postprocessor registration ----
    describe "#postprocessor" do
      it "registers a postprocessor" do
        registry = Asciidoctor::Extensions::Registry.new
        registry.postprocessor(UppercasePostprocessor.new)
        registry.postprocessors?.should be_true
        registry.postprocessors.size.should eq(1)
      end
    end

    # ---- IncludeProcessor registration ----
    describe "#include_processor" do
      it "registers an include processor" do
        registry = Asciidoctor::Extensions::Registry.new
        registry.include_processor(BoilerplateIncludeProcessor.new)
        registry.include_processors?.should be_true
        registry.include_processors.size.should eq(1)
      end
    end

    # ---- DocinfoProcessor registration ----
    describe "#docinfo_processor" do
      it "registers a docinfo processor" do
        registry = Asciidoctor::Extensions::Registry.new
        registry.docinfo_processor(MetaRobotsDocinfoProcessor.new)
        registry.docinfo_processors?.should be_true
        registry.docinfo_processors.size.should eq(1)
      end

      it "filters docinfo processors by location" do
        registry = Asciidoctor::Extensions::Registry.new
        registry.docinfo_processor(MetaRobotsDocinfoProcessor.new)
        registry.docinfo_processor(FooterDocinfoProcessor.new)
        registry.docinfo_processors(:head).size.should eq(1)
        registry.docinfo_processors(:footer).size.should eq(1)
        registry.docinfo_processors.size.should eq(2)
      end
    end

    # ---- BlockProcessor registration ----
    describe "#block" do
      it "registers a block processor" do
        registry = Asciidoctor::Extensions::Registry.new
        processor = UppercaseBlockProcessor.new
        registry.block(processor)
        registry.blocks?.should be_true
        registry.find_block_extension("yell").should_not be_nil
      end

      it "registers a block processor with explicit name" do
        registry = Asciidoctor::Extensions::Registry.new
        processor = UppercaseBlockProcessor.new
        registry.block(processor, "shout")
        registry.find_block_extension("shout").should_not be_nil
      end
    end

    # ---- BlockMacroProcessor registration ----
    describe "#block_macro" do
      it "registers a block macro processor" do
        registry = Asciidoctor::Extensions::Registry.new
        processor = SnippetBlockMacro.new
        registry.block_macro(processor)
        registry.block_macros?.should be_true
        registry.find_block_macro_extension("snippet").should_not be_nil
      end

      it "registers a block macro processor with explicit name" do
        registry = Asciidoctor::Extensions::Registry.new
        processor = SnippetBlockMacro.new
        registry.block_macro(processor, "code_snippet")
        registry.find_block_macro_extension("code_snippet").should_not be_nil
      end
    end

    # ---- InlineMacroProcessor registration ----
    describe "#inline_macro" do
      it "registers an inline macro processor" do
        registry = Asciidoctor::Extensions::Registry.new
        processor = TemperatureInlineMacro.new
        registry.inline_macro(processor)
        registry.inline_macros?.should be_true
        registry.find_inline_macro_extension("degrees").should_not be_nil
      end
    end

    # ---- Lookup methods ----
    describe "#registered_for_block?" do
      it "returns the extension when registered for the given context" do
        registry = Asciidoctor::Extensions::Registry.new
        processor = UppercaseBlockProcessor.new
        registry.block(processor)
        result = registry.registered_for_block?("yell", :paragraph)
        result.should be_a(Asciidoctor::Extensions::ProcessorExtension)
      end

      it "returns false when not registered for the given context" do
        registry = Asciidoctor::Extensions::Registry.new
        processor = UppercaseBlockProcessor.new
        registry.block(processor)
        result = registry.registered_for_block?("yell", :listing)
        result.should be_false
      end

      it "returns false when no block processor with that name exists" do
        registry = Asciidoctor::Extensions::Registry.new
        result = registry.registered_for_block?("unknown", :paragraph)
        result.should be_false
      end
    end

    describe "#registered_for_block_macro?" do
      it "returns the extension when registered" do
        registry = Asciidoctor::Extensions::Registry.new
        registry.block_macro(SnippetBlockMacro.new)
        result = registry.registered_for_block_macro?("snippet")
        result.should be_a(Asciidoctor::Extensions::ProcessorExtension)
      end

      it "returns false when not registered" do
        registry = Asciidoctor::Extensions::Registry.new
        result = registry.registered_for_block_macro?("unknown")
        result.should be_false
      end
    end

    describe "#registered_for_inline_macro?" do
      it "returns the extension when registered" do
        registry = Asciidoctor::Extensions::Registry.new
        registry.inline_macro(TemperatureInlineMacro.new)
        result = registry.registered_for_inline_macro?("degrees")
        result.should be_a(Asciidoctor::Extensions::ProcessorExtension)
      end

      it "returns false when not registered" do
        registry = Asciidoctor::Extensions::Registry.new
        result = registry.registered_for_inline_macro?("unknown")
        result.should be_false
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Processor — create_* methods
  # ---------------------------------------------------------------------------
  describe Asciidoctor::Extensions::Processor do
    describe "#create_block" do
      it "creates a block with the given context" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        block = processor.create_block(doc, :paragraph, "Hello World", {} of String => String)
        block.context.should eq(:paragraph)
        block.lines.should eq(["Hello World"])
      end

      it "creates a block with array source" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        block = processor.create_block(doc, :listing, ["line 1", "line 2"], {} of String => String)
        block.context.should eq(:listing)
        block.lines.should eq(["line 1", "line 2"])
      end
    end

    describe "#create_image_block" do
      it "creates an image block with target" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        block = processor.create_image_block(doc, {"target" => "photo.jpg"})
        block.context.should eq(:image)
        block.attributes["target"]?.should eq("photo.jpg")
        block.attributes["alt"]?.should eq("photo")
      end

      it "raises when target is missing" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        expect_raises(ArgumentError) do
          processor.create_image_block(doc, {} of String => String)
        end
      end
    end

    describe "#create_inline" do
      it "creates an inline node" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        inline = processor.create_inline(doc, :quoted, "text")
        inline.context.should eq(:quoted)
        inline.text.should eq("text")
      end
    end

    describe "#create_list" do
      it "creates a list node" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        list = processor.create_list(doc, :ulist)
        list.context.should eq(:ulist)
      end
    end

    describe "#create_list_item" do
      it "creates a list item with text" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        list = processor.create_list(doc, :ulist)
        item = processor.create_list_item(list, "Item text")
        item.text.should eq("Item text")
      end
    end

    describe "#create_paragraph" do
      it "creates a paragraph block" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        block = processor.create_paragraph(doc, "Hello", {} of String => String)
        block.context.should eq(:paragraph)
        block.lines.should eq(["Hello"])
      end
    end

    describe "#create_pass_block" do
      it "creates a pass block with raw content model" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        block = processor.create_pass_block(doc, "<b>raw</b>", {} of String => String)
        block.context.should eq(:pass)
        block.content_model.should eq(Asciidoctor::ContentModel::Raw)
      end
    end

    describe "#create_open_block" do
      it "creates an open block" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        block = processor.create_open_block(doc, "content", {} of String => String)
        block.context.should eq(:open)
      end
    end

    describe "#create_example_block" do
      it "creates an example block" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        block = processor.create_example_block(doc, "content", {} of String => String)
        block.context.should eq(:example)
      end
    end

    describe "#create_listing_block" do
      it "creates a listing block" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        block = processor.create_listing_block(doc, "code", {} of String => String)
        block.context.should eq(:listing)
      end
    end

    describe "#create_literal_block" do
      it "creates a literal block" do
        doc = Asciidoctor::Document.new
        processor = SnippetBlockMacro.new
        block = processor.create_literal_block(doc, "text", {} of String => String)
        block.context.should eq(:literal)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Group
  # ---------------------------------------------------------------------------
  describe Asciidoctor::Extensions::Group do
    it "activates and registers extensions on the registry" do
      registry = Asciidoctor::Extensions::Registry.new
      doc = Asciidoctor::Document.new
      registry.activate(doc)
      group = SampleExtensionGroup.new
      group.activate(registry)
      registry.preprocessors?.should be_true
      doc.attributes["activate-method-called"]?.should eq("")
    end
  end

  # ---------------------------------------------------------------------------
  # Extension — DocinfoProcessor location
  # ---------------------------------------------------------------------------
  describe Asciidoctor::Extensions::DocinfoProcessor do
    it "defaults to head location" do
      processor = MetaRobotsDocinfoProcessor.new
      processor.location.should eq(:head)
    end

    it "can be configured with footer location" do
      processor = FooterDocinfoProcessor.new
      processor.location.should eq(:footer)
    end
  end

  # ---------------------------------------------------------------------------
  # Extension — IncludeProcessor handles?
  # ---------------------------------------------------------------------------
  describe Asciidoctor::Extensions::IncludeProcessor do
    it "handles? returns true for matching targets" do
      processor = BoilerplateIncludeProcessor.new
      processor.handles?("readme.txt").should be_true
      processor.handles?("readme.adoc").should be_false
    end
  end

  # ---------------------------------------------------------------------------
  # Extension — BlockProcessor contexts
  # ---------------------------------------------------------------------------
  describe Asciidoctor::Extensions::BlockProcessor do
    it "has default contexts of open and paragraph" do
      processor = UppercaseBlockProcessor.new
      processor.contexts.should eq(Set{:open, :paragraph})
    end
  end

  # ---------------------------------------------------------------------------
  # Extension — InlineMacroProcessor regexp
  # ---------------------------------------------------------------------------
  describe Asciidoctor::Extensions::InlineMacroProcessor do
    it "resolves a regexp for the macro name" do
      processor = TemperatureInlineMacro.new
      rx = processor.regexp
      rx.should be_a(Regex)
      "degrees:100[C]".matches?(rx).should be_true
    end
  end

  # ---------------------------------------------------------------------------
  # Integration: Preprocessor runs during parsing
  # ---------------------------------------------------------------------------
  describe "Preprocessor integration" do
    it "runs preprocessor when extensions are set on document" do
      doc = Asciidoctor::Document.new
      registry = Asciidoctor::Extensions::Registry.new
      registry.activate(doc)
      registry.preprocessor(SamplePreprocessor.new)
      doc.extensions = registry

      reader = Asciidoctor::Reader.new("Hello World")
      Asciidoctor::Parser.parse(reader, doc)

      doc.attributes["preprocessor-ran"]?.should eq("true")
    end
  end

  # ---------------------------------------------------------------------------
  # Integration: TreeProcessor runs during parsing
  # ---------------------------------------------------------------------------
  describe "TreeProcessor integration" do
    it "runs tree processor after parsing" do
      doc = Asciidoctor::Document.new
      registry = Asciidoctor::Extensions::Registry.new
      registry.activate(doc)
      registry.tree_processor(SampleTreeProcessor.new)
      doc.extensions = registry

      reader = Asciidoctor::Reader.new("Hello World")
      Asciidoctor::Parser.parse(reader, doc)

      doc.attributes["tree-processor-ran"]?.should eq("true")
    end

    it "runs tree processor that modifies document attributes" do
      doc = Asciidoctor::Document.new
      registry = Asciidoctor::Extensions::Registry.new
      registry.activate(doc)
      registry.tree_processor(ReplaceAuthorTreeProcessor.new)
      doc.extensions = registry

      reader = Asciidoctor::Reader.new("= Title\nOriginal Author\n\nContent")
      Asciidoctor::Parser.parse(reader, doc)

      doc.attributes["author"]?.should eq("Ghost Writer")
      doc.attributes["firstname"]?.should eq("Ghost")
    end
  end

  # ---------------------------------------------------------------------------
  # Integration: BlockMacroProcessor runs during parsing
  # ---------------------------------------------------------------------------
  describe "BlockMacroProcessor integration" do
    it "processes a custom block macro during parsing" do
      doc = Asciidoctor::Document.new
      registry = Asciidoctor::Extensions::Registry.new
      registry.activate(doc)
      registry.block_macro(SnippetBlockMacro.new)
      doc.extensions = registry

      source = "= Title\n\nsnippet::app[]\n"
      reader = Asciidoctor::Reader.new(source)
      Asciidoctor::Parser.parse(reader, doc)

      # The document should contain a pass block from the macro
      found = false
      doc.blocks.each do |block|
        if block.is_a?(Asciidoctor::Block) && block.context == :pass
          found = true
          block.lines.first?.not_nil!.should contain("example.com/app.js")
        end
      end
      found.should be_true
    end

    it "processes a custom block macro that creates an image block" do
      doc = Asciidoctor::Document.new
      registry = Asciidoctor::Extensions::Registry.new
      registry.activate(doc)
      registry.block_macro(TestImageBlockMacro.new)
      doc.extensions = registry

      source = "= Title\n\ntestimg::photo[]\n"
      reader = Asciidoctor::Reader.new(source)
      Asciidoctor::Parser.parse(reader, doc)

      found = false
      doc.blocks.each do |block|
        if block.is_a?(Asciidoctor::Block) && block.context == :image
          found = true
          block.attributes["target"]?.should eq("photo.png")
        end
      end
      found.should be_true
    end
  end

  # ---------------------------------------------------------------------------
  # Integration: Multiple extensions in a group
  # ---------------------------------------------------------------------------
  describe "Extension Group integration" do
    it "activates a group that registers multiple extensions" do
      doc = Asciidoctor::Document.new
      groups = {
        :multi => MultiExtensionGroup.new.as(Asciidoctor::Extensions::Group.class | Asciidoctor::Extensions::Group),
      }
      registry = Asciidoctor::Extensions::Registry.new(groups)
      registry.activate(doc)
      doc.extensions = registry

      reader = Asciidoctor::Reader.new("Hello World")
      Asciidoctor::Parser.parse(reader, doc)

      doc.attributes["preprocessor-ran"]?.should eq("true")
      doc.attributes["tree-processor-ran"]?.should eq("true")
    end
  end

  # ---------------------------------------------------------------------------
  # Document#extensions?
  # ---------------------------------------------------------------------------
  describe "Document#extensions?" do
    it "returns false when no extensions are set" do
      doc = Asciidoctor::Document.new
      doc.extensions?.should be_false
    end

    it "returns true when extensions registry is set" do
      doc = Asciidoctor::Document.new
      registry = Asciidoctor::Extensions::Registry.new
      doc.extensions = registry
      doc.extensions?.should be_true
    end
  end
end
