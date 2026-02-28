module Asciidoctor
  # Public: Parse the AsciiDoc source input into a Document.
  #
  # Accepts input as a String.
  #
  # source  - the AsciiDoc source as a String
  # options - a Hash of options to control processing (default: {})
  #
  # Returns the Document
  def self.load(source : String, options : Hash(String, String) = {} of String => String) : Document
    attrs = options.fetch("attributes", "")
    attributes = {} of String => String
    if attrs.is_a?(String) && !attrs.empty?
      attrs.split(",").each do |entry|
        key, _, val = entry.partition("=")
        attributes[key.strip] = val.strip
      end
    end

    backend = attributes.delete("backend") || options.fetch("backend", "html5")
    doctype = attributes.delete("doctype") || options.fetch("doctype", "article")
    standalone = options.has_key?("standalone") ? options["standalone"] != "false" : false
    safe_mode_str = options.fetch("safe", "unsafe")
    safe_mode = SafeMode.value_for_name(safe_mode_str) || SafeMode::UNSAFE
    sourcemap = options.has_key?("sourcemap") && options["sourcemap"] != "false"

    doc = Document.new(
      backend: backend,
      doctype: doctype,
      safe: safe_mode,
      sourcemap: sourcemap
    )

    doc.attributes["standalone"] = "" if standalone
    attributes.each { |k, v| doc.attributes[k] = v }

    # Assign converter based on backend
    doc.converter = create_converter(backend)

    # Parse the document
    reader = Reader.new(source)
    Parser.parse(reader, doc)

    doc
  end

  # Public: Parse the AsciiDoc source input into a Document and convert it
  # to the specified backend format.
  #
  # source  - the AsciiDoc source as a String
  # options - a Hash of options to control processing (default: {})
  #
  # Returns the converted String
  def self.convert(source : String, options : Hash(String, String) = {} of String => String) : String
    doc = load(source, options)
    converter = doc.converter || create_converter(doc.backend)
    converter.convert(doc)
  end

  # Public: Parse the contents of the AsciiDoc source file into a Document.
  #
  # filename - the String AsciiDoc source filename
  # options  - a Hash of options to control processing (default: {})
  #
  # Returns the Document
  def self.load_file(filename : String, options : Hash(String, String) = {} of String => String) : Document
    source = File.read(filename)
    options["docfile"] = File.expand_path(filename)
    options["docdir"] = File.dirname(File.expand_path(filename))
    options["docname"] = File.basename(filename, File.extname(filename))
    load(source, options)
  end

  # Public: Parse the contents of the AsciiDoc source file and convert it
  # to the specified backend format.
  #
  # filename - the String AsciiDoc source filename
  # options  - a Hash of options to control processing (default: {})
  #
  # Returns the converted String
  def self.convert_file(filename : String, options : Hash(String, String) = {} of String => String) : String
    doc = load_file(filename, options)
    converter = doc.converter || create_converter(doc.backend)
    converter.convert(doc)
  end

  # Create a converter for the given backend
  protected def self.create_converter(backend : String) : Converter::Base
    case backend
    when "html5", "html", "xhtml5", "xhtml"
      Converter::Html5Converter.new(backend)
    when "docbook5", "docbook", "docbook45"
      Converter::DocBook5Converter.new(backend)
    when "manpage"
      Converter::ManPageConverter.new(backend)
    else
      Converter::Html5Converter.new("html5")
    end
  end
end
