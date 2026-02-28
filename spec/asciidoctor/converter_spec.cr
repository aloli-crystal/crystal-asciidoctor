require "../spec_helper"

# A simple test converter for testing the registry.
class TestConverter < Asciidoctor::Converter::Base
  register_for "test"

  def initialize(backend : String = "test")
    super(backend)
  end

  def dispatch(node : Asciidoctor::AbstractNode, transform : String) : String
    "<test>#{transform}</test>"
  end
end

# A converter that only handles specific transforms.
class PartialConverter < Asciidoctor::Converter::Base
  SUPPORTED = Set{"paragraph", "section"}

  def initialize(backend : String = "partial")
    super(backend)
  end

  def dispatch(node : Asciidoctor::AbstractNode, transform : String) : String
    "<partial>#{transform}</partial>"
  end

  def handles?(transform : String) : Bool
    SUPPORTED.includes?(transform)
  end
end

describe Asciidoctor::Converter do
  describe "BackendTraits" do
    it "creates backend traits with default values" do
      traits = Asciidoctor::Converter::BackendTraits.new
      traits.basebackend.should eq "html"
      traits.filetype.should eq "html"
      traits.outfilesuffix.should eq ".html"
      traits.supports_templates.should be_false
    end

    it "creates backend traits with custom values" do
      traits = Asciidoctor::Converter::BackendTraits.new(
        basebackend: "docbook",
        filetype: "xml",
        htmlsyntax: "xml",
        outfilesuffix: ".xml"
      )
      traits.basebackend.should eq "docbook"
      traits.filetype.should eq "xml"
      traits.htmlsyntax.should eq "xml"
      traits.outfilesuffix.should eq ".xml"
    end
  end

  describe "Base" do
    describe ".derive_backend_traits" do
      it "derives traits for html5 backend" do
        traits = Asciidoctor::Converter::Base.derive_backend_traits("html5")
        traits.basebackend.should eq "html"
        traits.filetype.should eq "html"
        traits.htmlsyntax.should eq "html"
        traits.outfilesuffix.should eq ".html"
      end

      it "derives traits for docbook5 backend" do
        traits = Asciidoctor::Converter::Base.derive_backend_traits("docbook5")
        traits.basebackend.should eq "docbook"
        traits.filetype.should eq "xml"
        traits.outfilesuffix.should eq ".xml"
      end

      it "derives traits for unknown backend" do
        traits = Asciidoctor::Converter::Base.derive_backend_traits("custom")
        traits.basebackend.should eq "custom"
        traits.filetype.should eq "custom"
        traits.outfilesuffix.should eq ".custom"
      end

      it "uses explicit basebackend when provided" do
        traits = Asciidoctor::Converter::Base.derive_backend_traits("myhtml5", "html")
        traits.basebackend.should eq "html"
        traits.filetype.should eq "html"
        traits.htmlsyntax.should eq "html"
      end
    end

    describe "#convert" do
      it "delegates to dispatch" do
        converter = TestConverter.new
        doc = Asciidoctor::Document.new
        block = Asciidoctor::Block.new(doc, :paragraph)
        result = converter.convert(block)
        result.should eq "<test>paragraph</test>"
      end

      it "uses explicit transform when provided" do
        converter = TestConverter.new
        doc = Asciidoctor::Document.new
        block = Asciidoctor::Block.new(doc, :paragraph)
        result = converter.convert(block, "custom_transform")
        result.should eq "<test>custom_transform</test>"
      end
    end

    describe "#handles?" do
      it "returns true by default" do
        converter = TestConverter.new
        converter.handles?("anything").should be_true
      end

      it "can be overridden to limit transforms" do
        converter = PartialConverter.new
        converter.handles?("paragraph").should be_true
        converter.handles?("section").should be_true
        converter.handles?("listing").should be_false
      end
    end

    describe "#supports_templates?" do
      it "returns false by default" do
        converter = TestConverter.new
        converter.supports_templates?.should be_false
      end

      it "can be set to true" do
        converter = TestConverter.new
        converter.supports_templates(true)
        converter.supports_templates?.should be_true
      end
    end
  end

  describe "DefaultRegistry" do
    it "registers a converter for a backend" do
      # TestConverter is registered for "test" via register_for macro
      klass = Asciidoctor::Converter::DefaultRegistry.converter_for("test")
      klass.should eq TestConverter
    end

    it "creates a converter instance for a registered backend" do
      converter = Asciidoctor::Converter::DefaultRegistry.create("test")
      converter.should_not be_nil
      converter.not_nil!.backend.should eq "test"
    end

    it "returns nil for an unregistered backend" do
      klass = Asciidoctor::Converter::DefaultRegistry.converter_for("nonexistent_backend_xyz")
      klass.should be_nil
    end

    it "lists registered converters" do
      converters = Asciidoctor::Converter::DefaultRegistry.converters
      converters.has_key?("test").should be_true
      converters.has_key?("html5").should be_true
    end
  end

  describe "CustomFactory" do
    it "creates an empty factory" do
      factory = Asciidoctor::Converter::CustomFactory.new
      factory.converter_for("html5").should be_nil
    end

    it "registers and retrieves a converter" do
      factory = Asciidoctor::Converter::CustomFactory.new
      factory.register(TestConverter, "mybackend")
      klass = factory.converter_for("mybackend")
      klass.should eq TestConverter
    end

    it "creates a converter instance" do
      factory = Asciidoctor::Converter::CustomFactory.new
      factory.register(TestConverter, "mybackend")
      converter = factory.create("mybackend")
      converter.should_not be_nil
      converter.not_nil!.backend.should eq "mybackend"
    end

    it "registers converter for specific backend" do
      factory = Asciidoctor::Converter::CustomFactory.new
      factory.register(TestConverter, "anything")
      converter = factory.converter_for("anything")
      converter.should eq TestConverter
    end

    it "unregisters all converters" do
      factory = Asciidoctor::Converter::CustomFactory.new
      factory.register(TestConverter, "mybackend")
      factory.unregister_all
      factory.converter_for("mybackend").should be_nil
    end

    it "initializes with a seed registry" do
      seed = {"seeded" => TestConverter.as(Asciidoctor::Converter::Base.class)}
      factory = Asciidoctor::Converter::CustomFactory.new(seed)
      factory.converter_for("seeded").should eq TestConverter
    end
  end

  describe "CompositeConverter" do
    it "delegates to the first converter that handles the transform" do
      html5 = Asciidoctor::Converter::Html5Converter.new
      partial = PartialConverter.new

      composite = Asciidoctor::Converter::CompositeConverter.new(
        "html5",
        [partial, html5] of Asciidoctor::Converter::Base
      )

      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.lines = ["Hello"]

      # PartialConverter handles "paragraph"
      result = composite.convert(block, "paragraph")
      result.should eq "<partial>paragraph</partial>"
    end

    it "falls back to the next converter for unhandled transforms" do
      html5 = Asciidoctor::Converter::Html5Converter.new
      partial = PartialConverter.new

      composite = Asciidoctor::Converter::CompositeConverter.new(
        "html5",
        [partial, html5] of Asciidoctor::Converter::Base
      )

      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :listing)
      block.lines = ["code"]

      # PartialConverter does NOT handle "listing", so Html5Converter is used
      result = composite.convert(block, "listing")
      result.should contain "listingblock"
    end

    it "uses backend traits from the source converter" do
      html5 = Asciidoctor::Converter::Html5Converter.new
      partial = PartialConverter.new

      composite = Asciidoctor::Converter::CompositeConverter.new(
        "html5",
        [partial, html5] of Asciidoctor::Converter::Base,
        backend_traits_source: html5
      )

      composite.backend_traits.basebackend.should eq "html"
      composite.backend_traits.filetype.should eq "html"
    end

    it "caches converter lookups" do
      html5 = Asciidoctor::Converter::Html5Converter.new
      composite = Asciidoctor::Converter::CompositeConverter.new(
        "html5",
        [html5] of Asciidoctor::Converter::Base
      )

      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.lines = ["Hello"]

      # First call
      composite.convert(block, "paragraph")
      # Second call should use cache
      result = composite.convert(block, "paragraph")
      result.should contain "paragraph"
    end

    it "raises when no converter handles the transform" do
      partial = PartialConverter.new
      composite = Asciidoctor::Converter::CompositeConverter.new(
        "html5",
        [partial] of Asciidoctor::Converter::Base
      )

      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :listing)
      block.lines = ["code"]

      expect_raises(Exception, /Could not find a converter/) do
        composite.convert(block, "listing")
      end
    end
  end
end
