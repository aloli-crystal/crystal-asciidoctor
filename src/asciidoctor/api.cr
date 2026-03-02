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
      # Support both comma-separated and space-separated attributes
      # e.g. "toc,icons=font" or "asciidoctor foobar" or "toc sectnums"
      # But if it contains '=', treat as a single attribute (value may contain spaces)
      # e.g. "man-linkstyle=cyan B \[fo] \[fc]" -> man-linkstyle=cyan B \[fo] \[fc]
      if attrs.includes?(",")
        # Comma-separated: split by comma
        attrs.split(",").each do |entry|
          entry = entry.strip
          next if entry.empty?
          if entry.includes?("=")
            key, _, val = entry.partition("=")
            attributes[key.strip] = val.strip
          else
            attributes[entry] = ""
          end
        end
      elsif attrs.includes?("=")
        # Single attribute with value (may contain spaces)
        key, _, val = attrs.partition("=")
        attributes[key.strip] = val.strip
      else
        # Space-separated attribute names (no values)
        attrs.split(" ").each do |entry|
          entry = entry.strip
          next if entry.empty?
          attributes[entry] = ""
        end
      end
    end

    # Known option keys
    known_options = Set{"attributes", "backend", "doctype", "header_footer", "standalone", "safe", "sourcemap", "to_file", "parse"}
    # Treat unknown keys as document attributes
    options.each do |key, value|
      next if known_options.includes?(key)
      attributes[key] = value
    end

    raw_backend = attributes.delete("backend") || options.fetch("backend", "html5")
    # Normalize backend name
    backend = case raw_backend
              when "docbook" then "docbook5"
              when "html" then "html5"
              when "xhtml" then "xhtml5"
              else raw_backend
              end
    doctype = attributes.delete("doctype") || options.fetch("doctype", "article")
    # header_footer=false is equivalent to standalone=false (embedded mode)
    # By default, standalone=true (full HTML document) to match Ruby AsciiDoctor behavior
    standalone = if options.has_key?("header_footer")
                   options["header_footer"] != "false"
                 elsif options.has_key?("standalone")
                   options["standalone"] != "false"
                 elsif options.has_key?("embedded") && options["embedded"] == "true"
                   false
                 else
                   true
                 end
    safe_mode_str = options.fetch("safe", "secure")
    safe_mode = SafeMode.value_for_name(safe_mode_str) || SafeMode::SECURE
    sourcemap = options.has_key?("sourcemap") && options["sourcemap"] != "false"

    doc = Document.new(
      backend: backend,
      doctype: doctype,
      safe: safe_mode,
      sourcemap: sourcemap
    )

    # Initialize default attributes
    DEFAULT_ATTRIBUTES.each { |k, v| doc.attributes[k] = v }
    doc.attributes["standalone"] = "" if standalone

    # Determine base backend and file type
    basebackend = case backend
                  when "html5", "html", "xhtml5", "xhtml" then "html"
                  when "docbook5", "docbook", "docbook45" then "docbook"
                  when "manpage" then "manpage"
                  else "html"
                  end
    filetype = case basebackend
               when "html" then "html"
               when "docbook" then "xml"
               when "manpage" then "man"
               else "html"
               end
    outfilesuffix = case filetype
                    when "html" then ".html"
                    when "xml" then ".xml"
                    when "man" then ".man"
                    else ".html"
                    end

    # Set intrinsic attributes
    doc.attributes["backend"] = backend
    doc.attributes["backend-#{backend}"] = ""
    doc.attributes["backend-#{backend}-doctype-#{doctype}"] = ""
    doc.attributes["basebackend"] = basebackend
    doc.attributes["basebackend-#{basebackend}"] = ""
    doc.attributes["basebackend-#{basebackend}-doctype-#{doctype}"] = ""
    doc.attributes["doctype"] = doctype
    doc.attributes["doctype-#{doctype}"] = ""
    doc.attributes["filetype"] = filetype
    doc.attributes["filetype-#{filetype}"] = ""
    doc.attributes["outfilesuffix"] = outfilesuffix
    safe_name = SafeMode.name_for_value(safe_mode) || "secure"
    doc.attributes["safe-mode-name"] = safe_name
    doc.attributes["safe-mode-level"] = safe_mode.to_s
    doc.attributes["safe-mode-#{safe_name}"] = ""
    doc.attributes["safe-mode-unsafe"] = "" if safe_mode <= SafeMode::UNSAFE
    doc.attributes["safe-mode-safe"] = "" if safe_mode <= SafeMode::SAFE
    doc.attributes["safe-mode-server"] = "" if safe_mode <= SafeMode::SERVER
    doc.attributes["safe-mode-secure"] = "" if safe_mode <= SafeMode::SECURE
    # Process attributes: handle !, @ modifiers for attribute set/unset/soft-set
    attributes.each do |k, v|
      name = k.downcase
      soft = false
      negate = false

      # Check for soft modifier @ on name
      if name.ends_with?('@')
        name = name[0...-1]
        soft = true
      end

      # Check for negate modifier ! on name
      if name.ends_with?('!')
        name = name[0...-1]
        negate = true
      elsif name.starts_with?('!')
        name = name[1..]
        negate = true
      end

      # Check for soft modifier @ on value
      if !soft && v.ends_with?('@')
        soft = true
        v = v[0...-1]
      end

      # Check for false value (equivalent to soft unset)
      if v == "false"
        negate = true
        soft = true
      end

      if negate
        doc.attributes.delete(name)
        # Only lock if not soft
        doc.attribute_overrides[name] = nil unless soft
      else
        doc.attributes[name] = v
        # Only lock if not soft
        doc.attribute_overrides[name] = v unless soft
      end
    end

    # Assign converter based on backend
    doc.converter = create_converter(backend)

    # Parse the document using PreprocessorReader to handle conditional directives
    parse_now = !(options.has_key?("parse") && options["parse"] == "false")
    # Create a cursor with the document file if available
    reader_cursor = if (docfile = doc.attributes["docfile"]?)
      Cursor.new(docfile, doc.attributes["docdir"]?, doc.attributes["docname"]?)
    else
      nil
    end
    reader = PreprocessorReader.new(doc, source, reader_cursor)
    doc.reader = reader
    if parse_now
      Parser.parse(reader, doc)
      doc.parsed = true
    end

    # Initialize syntax highlighter based on document attributes
    doc.init_syntax_highlighter

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
    options["docfilesuffix"] = File.extname(filename)
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
