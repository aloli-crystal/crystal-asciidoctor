module Asciidoctor
  # Internal: Struct to hold block match data returned by is_delimited_block?
  record BlockMatchData, context : Symbol, masq : Set(String), tip : String, terminator : String

  # Internal: Methods to parse lines of AsciiDoc into an object hierarchy
  # representing the structure of the document. All methods are module methods
  # and should be invoked from the Parser module.
  #
  # The object hierarchy created by the Parser consists of zero or more Section
  # and Block objects. Section objects may be nested and a Section object
  # contains zero or more Block objects.
  module Parser
    extend self
    include Logging

    TAB = '\t'

    TabIndentRx = /^\t+/

    # A Hash mapping horizontal alignment abbreviations to alignments
    TableCellHorzAlignments = {
      '<' => "left",
      '>' => "right",
      '^' => "center",
    }

    # A Hash mapping vertical alignment abbreviations to alignments
    TableCellVertAlignments = {
      '<' => "top",
      '>' => "bottom",
      '^' => "middle",
    }

    # A Hash mapping style abbreviations to styles for table cells
    TableCellStyles = {
      'd' => :none,
      's' => :strong,
      'e' => :emphasis,
      'm' => :monospaced,
      'h' => :header,
      'l' => :literal,
      'a' => :asciidoc,
    }

    AuthorKeys = Set{"author", "authorinitials", "firstname", "middlename", "lastname", "email"}

    # --------------------------------------------------------------------------
    # Utility methods (sorted alphabetically)
    # --------------------------------------------------------------------------

    # Remove the block indentation, replace tabs with spaces, and indent by margin.
    def adjust_indentation!(lines : Array(String), indent_size : Int32 = 0, tab_size : Int32 = 0) : Nil
      return if lines.empty?

      # expand tabs if a tab character is detected and tab_size > 0
      if tab_size > 0 && lines.any? { |line| line.includes?('\t') }
        full_tab_space = " " * tab_size
        lines.map! do |line|
          if line.empty? || !(tab_idx = line.index('\t'))
            line
          else
            if tab_idx == 0
              leading_tabs = 0
              line.each_byte do |b|
                break unless b == 9_u8
                leading_tabs += 1
              end
              line = "#{full_tab_space * leading_tabs}#{line[leading_tabs..]}"
              next line unless line.includes?('\t')
            end
            spaces_added = 0
            idx = 0
            result = String::Builder.new
            line.each_char do |c|
              if c == '\t'
                offset = idx + spaces_added
                if offset % tab_size == 0
                  spaces_added += tab_size - 1
                  result << full_tab_space
                else
                  spaces = tab_size - offset % tab_size
                  spaces_added += spaces - 1 unless spaces == 1
                  result << (" " * spaces)
                end
              else
                result << c
              end
              idx += 1
            end
            result.to_s
          end
        end
      end

      return if indent_size < 0

      # determine block indent
      block_indent : Int32? = nil
      lines.each do |line|
        next if line.empty?
        line_indent = line.size - line.lstrip.size
        if line_indent == 0
          block_indent = nil
          break
        end
        block_indent = line_indent unless block_indent && block_indent < line_indent
      end

      # remove block indent then apply indent_size
      if indent_size == 0
        lines.map! { |line| line.empty? ? line : line[block_indent..] } if block_indent
      else
        new_block_indent = " " * indent_size
        if block_indent
          lines.map! { |line| line.empty? ? line : "#{new_block_indent}#{line[block_indent..]}" }
        else
          lines.map! { |line| line.empty? ? line : "#{new_block_indent}#{line}" }
        end
      end

      nil
    end

    # Check whether the line given is an atx section title.
    def atx_section_title?(line : String) : Int32?
      if line.starts_with?('=') && (m = AtxSectionTitleRx.match(line))
        m[1].size - 1
      elsif COMPLIANCE_MARKDOWN_SYNTAX && line.starts_with?('#') && (m = ExtAtxSectionTitleRx.match(line))
        m[1].size - 1
      else
        nil
      end
    end

    # Determine whether this line is the start of a known delimited block.
    def is_delimited_block?(line : String, return_match_data : Bool = false) : BlockMatchData?
      line_len = line.size
      return nil unless line_len > 1 && DELIMITED_BLOCK_HEADS.has_key?(line[0, 2])

      if line_len == 2
        tip = line
        tip_len = 2
      else
        if line_len < 5
          tip = line
          tip_len = line_len
        else
          tip = line[0, 4]
          tip_len = 4
        end
        # special case for fenced code blocks
        if COMPLIANCE_MARKDOWN_SYNTAX && tip.starts_with?('`')
          if tip_len == 4
            if tip == "````" || (tip = tip[0, 3]) != "```"
              return nil
            end
            line_len = tip_len = 3
          elsif tip != "```"
            return nil
          end
        elsif tip_len == 3
          return nil
        end
      end

      if (entry = DELIMITED_BLOCKS[tip]?)
        context = entry[0]
        masq = entry[1]
        tail_char = DELIMITED_BLOCK_TAILS[tip]?
        if line_len == tip_len || (tail_char && uniform?(line[1..], tail_char, line_len - 1))
          return_match_data ? BlockMatchData.new(context, masq, tip, line) : BlockMatchData.new(context, masq, tip, line)
        else
          nil
        end
      else
        nil
      end
    end

    # Check if the next line on the Reader is the document title.
    def is_next_line_doctitle?(reader : Reader, attributes : Hash(String, String), leveloffset : String?) : Bool
      if leveloffset
        (sect_level = is_next_line_section?(reader, attributes)) != nil && (sect_level.not_nil! + leveloffset.to_i == 0)
      else
        is_next_line_section?(reader, attributes) == 0
      end
    end

    # Check if the next line on the Reader is a section title.
    def is_next_line_section?(reader : Reader, attributes : Hash(String, String)) : Int32?
      style = attributes["1"]?
      return nil if style && (style == "discrete" || style == "float")
      if COMPLIANCE_UNDERLINE_STYLE_SECTION_TITLES
        next_lines = reader.peek_lines(2, style != nil && style == "comment")
        is_section_title?(next_lines[0]? || "", next_lines[1]?)
      else
        atx_section_title?(reader.peek_line || "")
      end
    end

    # Check whether the lines given are a section title (atx or setext).
    def is_section_title?(line1 : String, line2 : String? = nil) : Int32?
      atx_section_title?(line1) || (line2 && !line2.empty? ? setext_section_title?(line1, line2) : nil)
    end

    # Check whether a line is a sibling list item.
    def is_sibling_list_item?(line : String, list_type : Symbol, sibling_trait : String | Regex) : Bool
      case sibling_trait
      when Regex
        sibling_trait.matches?(line)
      when String
        if (m = LIST_RX_MAP[list_type.to_s]?.try(&.match(line)))
          sibling_trait == resolve_list_marker(list_type, m[1])
        else
          false
        end
      else
        false
      end
    end

    # Public: Parses AsciiDoc source read from the Reader into the Document.
    def parse(reader : Reader, document : Document, header_only : Bool = false) : Document
      # Hook: run Preprocessors before parsing
      if document.extensions?
        registry = document.extensions!
        if registry.preprocessors?
          registry.preprocessors.each do |ext|
            preprocessor = ext.instance.as(Extensions::Preprocessor)
            result = preprocessor.process(document, reader)
            reader = result if result
          end
        end
      end

      block_attributes = parse_document_header(reader, document, header_only)

      unless header_only
        while reader.has_more_lines?
          new_section, block_attributes = next_section(reader, document, block_attributes)
          if new_section
            document.assign_numeral(new_section)
            document.blocks << new_section
          end
        end
      end

      # Hook: run TreeProcessors after parsing
      if document.extensions?
        registry = document.extensions!
        if registry.tree_processors?
          registry.tree_processors.each do |ext|
            tree_processor = ext.instance.as(Extensions::TreeProcessor)
            result = tree_processor.process(document)
            # If the tree processor returns a new document, use it
          end
        end
      end

      document
    end

    # Parse blocks from this reader until there are no more lines.
    def parse_blocks(reader : Reader, parent : AbstractBlock, attributes : Hash(String, String)? = nil) : Nil
      attrs = attributes ? attributes.dup : {} of String => String
      while (block = next_block(reader, parent, attrs)) || reader.has_more_lines?
        if block
          parent.blocks << block
        end
        attrs = {} of String => String unless attributes
      end
    end

    # Parse the document header.
    def parse_document_header(reader : Reader, document : Document, header_only : Bool = false) : Hash(String, String)
      block_attrs = reader.skip_blank_lines ? parse_block_metadata_lines(reader, document) : {} of String => String
      doc_attrs = document.attributes

      # check for implicit document title
      if is_next_line_doctitle?(reader, block_attrs, doc_attrs["leveloffset"]?) && (block_attrs.has_key?("title") || block_attrs.has_key?("style"))
        doc_attrs["authorcount"] = "0"
        return document.finalize_header(block_attrs, false)
      end

      unless (val = doc_attrs["doctitle"]?).nil? || val.empty?
        document.title = val
      end

      if is_next_line_doctitle?(reader, block_attrs, doc_attrs["leveloffset"]?)
        _sect_id, _, l0_section_title, _, atx = parse_section_title(reader, document)
        if doc_attrs["doctitle"]? && !doc_attrs["doctitle"]?.try(&.empty?)
          l0_section_title = nil
        else
          document.title = l0_section_title
          doc_attrs["doctitle"] = l0_section_title || ""
        end

        if (doc_id = block_attrs["id"]?)
          document.id = doc_id
        end
        if (role = block_attrs["role"]?)
          doc_attrs["role"] = role
        end
        if (reftext = block_attrs["reftext"]?)
          doc_attrs["reftext"] = reftext
        end
        block_attrs.clear
        parse_header_metadata(reader, document)
      elsif (author = doc_attrs["author"]?)
        author_metadata = process_authors(author, true, false)
        doc_attrs.merge!(author_metadata)
      else
        doc_attrs["authorcount"] = "0"
      end

      document.finalize_header(block_attrs)
    end

    # Parse the section title from the current position of the reader.
    def parse_section_title(reader : Reader, document : Document, sect_id : String? = nil) : Tuple(String?, String?, String, Int32, Bool)
      sect_reftext = nil
      line1 = reader.read_line.not_nil!

      if line1.starts_with?('=') && (m = AtxSectionTitleRx.match(line1))
        sect_level = m[1].size - 1
        sect_title = m[2]
        atx = true
        if !sect_id && sect_title.ends_with?("]]") && (am = InlineSectionAnchorRx.match(sect_title)) && !am[1]?
          sect_title = sect_title[0, sect_title.size - am[0].size]
          sect_id = am[2]
          sect_reftext = am[3]?
        end
      elsif COMPLIANCE_MARKDOWN_SYNTAX && line1.starts_with?('#') && (m = ExtAtxSectionTitleRx.match(line1))
        sect_level = m[1].size - 1
        sect_title = m[2]
        atx = true
        if !sect_id && sect_title.ends_with?("]]") && (am = InlineSectionAnchorRx.match(sect_title)) && !am[1]?
          sect_title = sect_title[0, sect_title.size - am[0].size]
          sect_id = am[2]
          sect_reftext = am[3]?
        end
      elsif COMPLIANCE_UNDERLINE_STYLE_SECTION_TITLES && (line2 = reader.peek_line(direct: true)) &&
            (line2_ch0 = line2[0]?) && (sect_level = SETEXT_SECTION_LEVELS[line2_ch0.to_s]?) &&
            uniform?(line2, line2_ch0.to_s, line2.size) &&
            (m = SetextSectionTitleRx.match(line1)) && (line1.size - line2.size).abs < 2
        sect_title = m[1]
        atx = false
        if !sect_id && sect_title.ends_with?("]]") && (am = InlineSectionAnchorRx.match(sect_title)) && !am[1]?
          sect_title = sect_title[0, sect_title.size - am[0].size]
          sect_id = am[2]
          sect_reftext = am[3]?
        end
        reader.advance
      else
        raise "Unrecognized section at #{reader.cursor_at_prev_line}"
      end

      if (lo = document.attributes["leveloffset"]?)
        sect_level = sect_level.not_nil! + lo.to_i
        sect_level = 0 if sect_level < 0
      end

      {sect_id, sect_reftext, sect_title.not_nil!, sect_level.not_nil!, atx.not_nil!}
    end

    # Parse consecutive lines of block metadata.
    def parse_block_metadata_lines(reader : Reader, document : Document, attributes : Hash(String, String) = {} of String => String) : Hash(String, String)
      while parse_block_metadata_line(reader, document, attributes)
        reader.advance
        reader.skip_blank_lines || break
      end
      attributes
    end

    # Parse the next line if it contains metadata for the following block.
    def parse_block_metadata_line(reader : Reader, document : Document, attributes : Hash(String, String), text_only : Bool = false) : Bool
      next_line = reader.peek_line
      return false unless next_line

      if text_only
        return false unless next_line.starts_with?('[') || next_line.starts_with?('/')
      else
        return false unless next_line.starts_with?('[') || next_line.starts_with?('.') || next_line.starts_with?('/') || next_line.starts_with?(':')
      end

      if next_line.starts_with?('[')
        if next_line.starts_with?("[[")
          if next_line.ends_with?("]]") && (m = BlockAnchorRx.match(next_line))
            attributes["id"] = m[1]
            if (reftext = m[2]?)
              attributes["reftext"] = reftext
            end
            return true
          end
        elsif next_line.ends_with?(']') && (m = BlockAttributeListRx.match(next_line))
          if (raw = m[1]?) && !raw.empty?
            parse_block_attribute_list(raw, attributes)
          end
          return true
        end
      elsif !text_only && next_line.starts_with?('.')
        if (m = BlockTitleRx.match(next_line))
          attributes["title"] = m[1]
          return true
        end
      elsif next_line.starts_with?("//")
        if next_line == "//"
          return true
        elsif !next_line.starts_with?("///") && next_line.starts_with?("//")
          return true
        elsif uniform?(next_line, "/", next_line.size) && next_line.size > 3
          reader.read_lines_until(terminator: next_line, skip_first_line: true, preserve_last_line: true, skip_processing: true, context: :comment)
          return true
        end
      elsif !text_only && next_line.starts_with?(':') && (m = AttributeEntryRx.match(next_line))
        process_attribute_entry(reader, document, attributes, m)
        return true
      end

      false
    end

    # Parse a block attribute list into a Hash.
    def parse_block_attribute_list(raw : String, attributes : Hash(String, String)) : Hash(String, String)
      # Simple parsing: split by comma for positional, handle key=value
      return attributes if raw.empty?

      if raw.includes?(',') || raw.includes?('=')
        idx = 0
        raw.split(',').each do |part|
          part = part.strip
          if part.includes?('=')
            key, _, value = part.partition('=')
            key = key.strip
            value = value.strip.strip('"')
            attributes[key] = value
          else
            idx += 1
            attributes[idx.to_s] = part
          end
        end
      else
        attributes["1"] = raw
      end

      # Parse style attribute (shorthand: style#id.role%option)
      if (raw_style = attributes["1"]?) && !raw_style.includes?(' ')
        parse_style_attribute(attributes)
      end

      attributes
    end

    # Parse the style attribute shorthand (style#id.role%option).
    def parse_style_attribute(attributes : Hash(String, String)) : String?
      raw_style = attributes["1"]?
      return nil unless raw_style && !raw_style.includes?(' ')

      name : Symbol? = nil
      accum = String::Builder.new
      parsed_style : String? = nil
      parsed_id : String? = nil
      parsed_roles = [] of String
      parsed_options = [] of String

      raw_style.each_char do |c|
        case c
        when '.'
          flush_shorthand(name, accum.to_s, parsed_style, parsed_id, parsed_roles, parsed_options).try do |ps, pi, pr, po|
            parsed_style, parsed_id, parsed_roles, parsed_options = ps, pi, pr, po
          end
          accum = String::Builder.new
          name = :role
        when '#'
          flush_shorthand(name, accum.to_s, parsed_style, parsed_id, parsed_roles, parsed_options).try do |ps, pi, pr, po|
            parsed_style, parsed_id, parsed_roles, parsed_options = ps, pi, pr, po
          end
          accum = String::Builder.new
          name = :id
        when '%'
          flush_shorthand(name, accum.to_s, parsed_style, parsed_id, parsed_roles, parsed_options).try do |ps, pi, pr, po|
            parsed_style, parsed_id, parsed_roles, parsed_options = ps, pi, pr, po
          end
          accum = String::Builder.new
          name = :option
        else
          accum << c
        end
      end

      if name
        flush_shorthand(name, accum.to_s, parsed_style, parsed_id, parsed_roles, parsed_options).try do |ps, pi, pr, po|
          parsed_style, parsed_id, parsed_roles, parsed_options = ps, pi, pr, po
        end

        attributes["style"] = parsed_style if parsed_style
        attributes["id"] = parsed_id if parsed_id
        attributes["role"] = parsed_roles.join(' ') unless parsed_roles.empty?
        parsed_options.each { |opt| attributes["#{opt}-option"] = "" }
        parsed_style
      else
        attributes["style"] = raw_style
        raw_style
      end
    end

    private def flush_shorthand(name : Symbol?, value : String, style : String?, id : String?, roles : Array(String), options : Array(String)) : Tuple(String?, String?, Array(String), Array(String))?
      return nil if value.empty? && name
      case name
      when :id
        {style, value, roles, options}
      when :role
        roles << value unless value.empty?
        {style, id, roles, options}
      when :option
        options << value unless value.empty?
        {style, id, roles, options}
      else # style (first positional)
        {value.empty? ? style : value, id, roles, options}
      end
    end

    # Parse the header metadata (author line, revision line, attribute entries).
    def parse_header_metadata(reader : Reader, document : Document) : Nil
      doc_attrs = document.attributes
      process_attribute_entries(reader, document)

      if reader.has_more_lines? && !reader.next_line_empty?
        author_metadata = process_authors(reader.read_line.not_nil!)
        if (authorcount = author_metadata["authorcount"]?) && authorcount.to_i > 0
          author_metadata.each do |key, val|
            doc_attrs[key] = val unless doc_attrs.has_key?(key)
          end
        end
        doc_attrs["authorcount"] = authorcount || "0"

        process_attribute_entries(reader, document)

        if reader.has_more_lines? && !reader.next_line_empty?
          rev_line = reader.read_line.not_nil!
          if (match = RevisionInfoLineRx.match(rev_line))
            doc_attrs["revnumber"] = match[1].rstrip if match[1]?
            component = match[2]?.try(&.strip) || ""
            unless component.empty?
              if !match[1]? && component.starts_with?('v')
                doc_attrs["revnumber"] = component[1..]
              else
                doc_attrs["revdate"] = component
              end
            end
            doc_attrs["revremark"] = match[3].rstrip if match[3]?
          else
            reader.unshift_line(rev_line)
          end
        end

        process_attribute_entries(reader, document)
        reader.skip_blank_lines
      end

      nil
    end

    # Return the next section from the Reader.
    def next_section(reader : Reader, parent : AbstractBlock, attributes : Hash(String, String) = {} of String => String) : Tuple(Section?, Hash(String, String))
      preamble : Block? = nil
      intro : Block? = nil
      part = false

      if parent.context == :document && parent.blocks.empty?
        document = parent.as(Document)
        book = document.doctype == "book"
        has_header = document.header?
        if has_header || (book && attributes["1"]? != "abstract") || !is_next_line_section?(reader, attributes)
          if has_header || (book && attributes["1"]? != "abstract")
            preamble = intro = Block.new(parent, :preamble, content_model: ContentModel::Compound)
            parent.blocks << preamble
          end
          section = parent
          current_level = 0
          if parent.attributes.has_key?("fragment")
            expected_next_level = -1
          elsif book
            expected_next_level = 1
          else
            expected_next_level = 1
          end
        else
          document = parent.as(Document)
          book = document.doctype == "book"
          section = initialize_section(reader, parent, attributes)
          attributes = attributes.has_key?("title") ? {"title" => attributes["title"]} : {} of String => String
          expected_next_level = (current_level = section.level) + 1
          if current_level == 0
            part = book
          end
        end
      else
        document = parent.document
        book = document.doctype == "book"
        section = initialize_section(reader, parent, attributes)
        attributes = attributes.has_key?("title") ? {"title" => attributes["title"]} : {} of String => String
        expected_next_level = (current_level = section.level) + 1
        if current_level == 0
          part = book
        end
      end

      reader.skip_blank_lines

      while reader.has_more_lines?
        parse_block_metadata_lines(reader, document, attributes)
        if (next_level = is_next_line_section?(reader, attributes))
          if (lo = document.attributes["leveloffset"]?)
            next_level += lo.to_i
            next_level = 0 if next_level < 0
          end
          if next_level > current_level
            new_section, attributes = next_section(reader, section, attributes)
            if new_section
              section.assign_numeral(new_section)
              section.blocks << new_section
            end
          elsif next_level == 0 && section == parent
            new_section, attributes = next_section(reader, section, attributes)
            if new_section
              section.assign_numeral(new_section)
              section.blocks << new_section
            end
          else
            break
          end
        else
          block_cursor = reader.cursor
          if (new_block = next_block(reader, intro || section, attributes))
            (intro || section).blocks << new_block
            attributes.clear
          end
        end

        reader.skip_blank_lines || break
      end

      if preamble
        if preamble.blocks?
          # keep preamble
        else
          parent.as(AbstractBlock).blocks.delete(preamble)
        end
      end

      {section == parent ? nil : section.as(Section), attributes.dup}
    end

    # Parse and return the next Block at the Reader's current location.
    def next_block(reader : Reader, parent : AbstractBlock, attributes : Hash(String, String) = {} of String => String, parse_metadata : Bool = true) : AbstractBlock?
      skipped = reader.skip_blank_lines
      return nil unless skipped

      document = parent.document

      if parse_metadata
        while parse_block_metadata_line(reader, document, attributes)
          reader.advance
          reader.skip_blank_lines || return nil
        end
      end

      reader.mark
      this_line = reader.read_line
      return nil unless this_line

      doc_attrs = document.attributes
      style = attributes["1"]?
      block : AbstractBlock? = nil
      block_context : Symbol? = nil
      cloaked_context : Symbol? = nil
      terminator : String? = nil

      if (delimited_block = is_delimited_block?(this_line, true))
        block_context = cloaked_context = delimited_block.context
        terminator = delimited_block.terminator
        if style
          unless style == block_context.to_s
            if delimited_block.masq.includes?(style)
              block_context = string_to_block_context(style) || block_context
            elsif delimited_block.masq.includes?("admonition") && ADMONITION_STYLES.includes?(style)
              block_context = :admonition
            else
              style = block_context.to_s
            end
          end
        else
          style = block_context.to_s
          attributes["style"] = style
        end
      end

      # Process non-delimited blocks
      unless delimited_block
        indented = this_line.starts_with?(' ') || this_line.starts_with?(TAB)
        ch0 = this_line[0]?

        unless indented
          # Check for layout breaks
          if ch0 && LAYOUT_BREAK_CHARS.has_key?(ch0.to_s) && uniform?(this_line, ch0.to_s, this_line.size) && this_line.size > 2
            block = Block.new(parent, LAYOUT_BREAK_CHARS[ch0.to_s], content_model: ContentModel::Empty)
            return finalize_block(block, document, reader, attributes, style)
          end

          # Check for block macros
          if this_line.ends_with?(']') && this_line.includes?("::")
            # Hook: check for BlockMacroProcessor extensions
            if document.extensions?
              registry = document.extensions!
              if registry.block_macros?
                if (bm_match = CustomBlockMacroRx.match(this_line))
                  macro_name = bm_match[1]
                  if (ext = registry.find_block_macro_extension(macro_name))
                    macro_target = bm_match[2]? || ""
                    raw_attrs = bm_match[3]? || ""
                    macro_attrs = {} of String => String
                    parse_block_attribute_list(raw_attrs, macro_attrs) unless raw_attrs.empty?
                    processor = ext.instance.as(Extensions::BlockMacroProcessor)
                    result = processor.process(parent, macro_target, macro_attrs)
                    if result.is_a?(AbstractBlock)
                      return finalize_block(result, document, reader, attributes, style)
                    end
                  end
                end
              end
            end

            if (ch0 == 'i' || this_line.starts_with?("video:") || this_line.starts_with?("audio:")) && (m = BlockMediaMacroRx.match(this_line))
              blk_ctx = string_to_block_context(m[1]) || :image
              target = m[2]
              block = Block.new(parent, blk_ctx, content_model: ContentModel::Empty)
              attributes["target"] = target
              return finalize_block(block, document, reader, attributes, style)
            elsif ch0 == 't' && this_line.starts_with?("toc:") && BlockTocMacroRx.matches?(this_line)
              block = Block.new(parent, :toc, content_model: ContentModel::Empty)
              return finalize_block(block, document, reader, attributes, style)
            end
          end

          # Check for lists
          if (m = UnorderedListRx.match(this_line))
            reader.unshift_line(this_line)
            block = parse_list(reader, :ulist, parent, attributes)
            return finalize_block(block, document, reader, attributes, style)
          elsif (m = OrderedListRx.match(this_line))
            reader.unshift_line(this_line)
            block = parse_list(reader, :olist, parent, attributes)
            return finalize_block(block, document, reader, attributes, style)
          elsif (this_line.includes?("::") || this_line.includes?(";;")) && (m = DescriptionListRx.match(this_line))
            reader.unshift_line(this_line)
            block = parse_description_list(reader, parent, attributes)
            return finalize_block(block, document, reader, attributes, style)
          elsif (m = CalloutListRx.match(this_line))
            reader.unshift_line(this_line)
            block = parse_list(reader, :colist, parent, attributes)
            return finalize_block(block, document, reader, attributes, style)
          end

          # Check for admonition paragraph
          if ADMONITION_STYLE_HEADS.includes?(ch0.to_s) && this_line.includes?(':') && (m = AdmonitionParagraphRx.match(this_line))
            reader.unshift_line(this_line)
            lines = read_paragraph_lines(reader)
            lines[0] = this_line[(m[0].size)..]
            admonition_name = m[1].downcase
            attributes["style"] = m[1]
            attributes["name"] = admonition_name
            attributes["textlabel"] = doc_attrs["#{admonition_name}-caption"]? || m[1]
            block = Block.new(parent, :admonition, content_model: ContentModel::Simple, source: lines)
            return finalize_block(block, document, reader, attributes, style)
          end
        end

        # Normal or literal paragraph
        reader.unshift_line(this_line)
        if indented && style != "normal"
          lines = read_paragraph_lines(reader)
          adjust_indentation!(lines)
          block = Block.new(parent, :literal, content_model: ContentModel::Verbatim, source: lines)
        else
          lines = read_paragraph_lines(reader)
          if indented && style == "normal"
            adjust_indentation!(lines)
          end
          block = Block.new(parent, :paragraph, content_model: ContentModel::Simple, source: lines)
        end

        return finalize_block(block, document, reader, attributes, style)
      end

      # Process delimited blocks
      case block_context
      when :listing, :source
        block = build_block(:listing, ContentModel::Verbatim, terminator, parent, reader, attributes)
      when :fenced_code
        attributes["style"] = "source"
        term = terminator.not_nil!
        term = term[0, 3] if term.size > 3
        block = build_block(:listing, ContentModel::Verbatim, term, parent, reader, attributes)
      when :table
        block_cursor = reader.cursor
        table_lines = reader.read_lines_until(terminator: terminator, skip_line_comments: true, context: :table)
        block_reader = Reader.new(table_lines, block_cursor)
        block = parse_table(block_reader, parent, attributes)
      when :sidebar
        block = build_block(:sidebar, ContentModel::Compound, terminator, parent, reader, attributes)
      when :admonition
        admonition_name = (style || "note").downcase
        attributes["name"] = admonition_name
        attributes["textlabel"] = doc_attrs["#{admonition_name}-caption"]? || (style || "Note")
        block = build_block(:admonition, ContentModel::Compound, terminator, parent, reader, attributes)
      when :open, :abstract, :partintro
        block = build_block(:open, ContentModel::Compound, terminator, parent, reader, attributes)
      when :literal
        block = build_block(:literal, ContentModel::Verbatim, terminator, parent, reader, attributes)
      when :example
        block = build_block(:example, ContentModel::Compound, terminator, parent, reader, attributes)
      when :quote
        block = build_block(:quote, ContentModel::Compound, terminator, parent, reader, attributes)
      when :verse
        block = build_block(:verse, ContentModel::Verbatim, terminator, parent, reader, attributes)
      when :stem, :latexmath, :asciimath
        block = build_block(:stem, ContentModel::Raw, terminator, parent, reader, attributes)
      when :pass
        block = build_block(:pass, ContentModel::Raw, terminator, parent, reader, attributes)
      when :comment
        build_block(:comment, ContentModel::Skip, terminator, parent, reader, attributes)
        attributes.clear
        return nil
      else
        block = Block.new(parent, block_context || :paragraph, content_model: ContentModel::Simple)
      end

      return nil unless block
      finalize_block(block, document, reader, attributes, style)
    end

    # Finalize a block: assign source_location, title, caption, style, id.
    private def finalize_block(block : AbstractBlock, document : Document, reader : Reader, attributes : Hash(String, String), style : String?) : AbstractBlock
      block.source_location = reader.cursor_at_mark.to_source_location if document.sourcemap?
      if (title = attributes.delete("title"))
        block.title = title
        if CAPTION_ATTRIBUTE_NAMES.has_key?(block.context.to_s)
          block.assign_caption(attributes.delete("caption"))
        end
      end
      block.style = style || attributes["style"]?
      if (block_id = attributes["id"]?)
        block.id = block_id
      end
      block.update_attributes(attributes) unless attributes.empty?
      block
    end

    # Build a block from delimited content.
    def build_block(block_context : Symbol, content_model : ContentModel, terminator : String?, parent : AbstractBlock, reader : Reader, attributes : Hash(String, String)) : Block?
      case content_model
      when ContentModel::Skip
        if terminator
          reader.read_lines_until(terminator: terminator, skip_processing: true, context: block_context)
        end
        return nil
      when ContentModel::Raw
        lines = if terminator
                  reader.read_lines_until(terminator: terminator, skip_processing: false, context: block_context)
                else
                  read_paragraph_lines(reader)
                end
        block = Block.new(parent, block_context, content_model: content_model, source: lines)
      when ContentModel::Verbatim
        lines = if terminator
                  reader.read_lines_until(terminator: terminator, skip_processing: false, context: block_context)
                else
                  reader.read_lines_until(break_on_blank_lines: true, break_on_list_continuation: true)
                end
        tab_size = (attributes["tabsize"]? || parent.document.attributes["tabsize"]?).try(&.to_i) || 0
        if (indent = attributes["indent"]?)
          adjust_indentation!(lines, indent.to_i, tab_size)
        elsif tab_size > 0
          adjust_indentation!(lines, -1, tab_size)
        end
        block = Block.new(parent, block_context, content_model: content_model, source: lines)
      when ContentModel::Compound
        lines = nil.as(Array(String)?)
        if terminator
          block_cursor = reader.cursor
          block_lines = reader.read_lines_until(terminator: terminator, skip_processing: false, context: block_context)
          block_reader = Reader.new(block_lines, block_cursor)
          block = Block.new(parent, block_context, content_model: content_model)
          parse_blocks(block_reader, block)
        else
          block = Block.new(parent, block_context, content_model: content_model)
        end
      else # Simple
        lines = if terminator
                  reader.read_lines_until(terminator: terminator, context: block_context)
                else
                  read_paragraph_lines(reader)
                end
        block = Block.new(parent, block_context, content_model: content_model, source: lines)
      end

      block
    end

    # Initialize a new Section from the reader.
    def initialize_section(reader : Reader, parent : AbstractBlock, attributes : Hash(String, String) = {} of String => String) : Section
      document = parent.document
      book = document.doctype == "book"
      sect_style = attributes["1"]?
      sect_id, sect_reftext, sect_title, sect_level, _sect_atx = parse_section_title(reader, document, attributes["id"]?)

      sect_name = "section"
      sect_special = false
      sect_numbered = false

      if sect_style
        if book && sect_style == "abstract"
          sect_name = "chapter"
          sect_level = 1
        elsif sect_style.starts_with?("sect") && SectionLevelStyleRx.matches?(sect_style)
          sect_name = "section"
        else
          sect_name = sect_style
          sect_special = true
          sect_level = 1 if sect_level == 0
          sect_numbered = sect_name == "appendix"
        end
      elsif book
        sect_name = sect_level == 0 ? "part" : (sect_level > 1 ? "section" : "chapter")
      end

      section = Section.new(document, parent, sect_level)
      section.id = sect_id
      section.title = sect_title
      section.sectname = sect_name
      if sect_special
        section.special = true
        section.numbered = true if sect_numbered
      elsif document.attributes.has_key?("sectnums") && sect_level > 0
        section.numbered = true
      end

      if (reftext = sect_reftext || attributes["reftext"]?)
        section.attributes["reftext"] = reftext
      end

      # Generate an ID if one was not provided
      if (id = section.id)
        section.id = nil if id.empty?
      elsif document.attributes.has_key?("sectids")
        section.id = Section.generate_id(sect_title, document)
      end

      section.update_attributes(attributes) unless attributes.empty?
      reader.skip_blank_lines

      section
    end

    # Parse a list (unordered, ordered, or callout).
    def parse_list(reader : Reader, list_type : Symbol, parent : AbstractBlock, attributes : Hash(String, String) = {} of String => String, start : String? = nil) : List
      list = List.new(parent, list_type)
      list.attributes.merge!(attributes)

      if list_type == :olist && start
        list.attributes["start"] = start
      end

      list_rx = LIST_RX_MAP[list_type.to_s]? || UnorderedListRx

      while reader.has_more_lines?
        line = reader.peek_line
        break unless line

        if (m = list_rx.match(line))
          reader.advance
          marker = m[1]
          text = m[2]

          item = ListItem.new(list, text)
          item.marker = marker

          # Read continuation lines for this list item
          while reader.has_more_lines?
            next_line = reader.peek_line
            break unless next_line
            if next_line.empty?
              reader.advance
              # Check if next non-blank line continues the list
              reader.skip_blank_lines
              cont_line = reader.peek_line
              break unless cont_line
              if cont_line == LIST_CONTINUATION
                reader.advance
                # Read the next block as continuation
                if (cont_block = next_block(reader, item))
                  item.blocks << cont_block
                end
              elsif list_rx.matches?(cont_line)
                break # sibling list item
              else
                break
              end
            elsif next_line == LIST_CONTINUATION
              reader.advance
              if (cont_block = next_block(reader, item))
                item.blocks << cont_block
              end
            elsif list_rx.matches?(next_line)
              break # sibling list item
            elsif is_delimited_block?(next_line)
              break
            else
              reader.advance
              item.text = "#{item.text}\n#{next_line}"
            end
          end

          list.items << item
        else
          break
        end
      end

      list
    end

    # Parse a description list.
    def parse_description_list(reader : Reader, parent : AbstractBlock, attributes : Hash(String, String) = {} of String => String) : List
      list = List.new(parent, :dlist)
      list.attributes.merge!(attributes)

      while reader.has_more_lines?
        line = reader.peek_line
        break unless line

        if (m = DescriptionListRx.match(line))
          reader.advance
          term_text = m[1]
          delimiter = m[2]
          desc_text = m[3]?

          term = ListItem.new(list, term_text)
          desc : ListItem? = nil

          if desc_text && !desc_text.empty?
            desc = ListItem.new(list, desc_text)
          else
            # Read continuation for description
            reader.skip_blank_lines
            if reader.has_more_lines?
              next_line = reader.peek_line
              if next_line && !next_line.empty? && !DescriptionListRx.matches?(next_line) && !is_delimited_block?(next_line)
                reader.advance
                desc = ListItem.new(list, next_line)
              end
            end
          end

          list.items << term
          list.items << desc if desc
        else
          break
        end
      end

      list
    end

    # Parse a table from a reader.
    def parse_table(table_reader : Reader, parent : AbstractBlock, attributes : Hash(String, String)) : Table
      table = Table.new(parent, attributes)

      # Parse column specs if provided
      if (cols = attributes["cols"]?)
        colspecs = parse_colspecs(cols)
        table.create_columns(colspecs) unless colspecs.empty?
      end

      format = attributes["format"]? || "psv"
      separator = case format
                  when "csv" then ","
                  when "dsv" then ":"
                  else            "|"
                  end

      has_header = attributes.has_key?("header-option")
      row_index = 0

      while (line = table_reader.read_line)
        next if line.empty?

        cells = line.split(separator)
        cells.shift if cells.first?.try(&.empty?) && format == "psv"

        row = [] of Table::Cell
        cells.each_with_index do |cell_text, col_idx|
          # Ensure column exists
          while table.columns.size <= col_idx
            col = Table::Column.new(table, table.columns.size)
            table.columns << col
          end
          cell = Table::Cell.new(table.columns[col_idx], cell_text.strip)
          row << cell
        end

        if has_header && row_index == 0
          table.rows.head << row
        else
          table.rows.body << row
        end
        row_index += 1
      end

      table
    end

    # Parse column specs for a table.
    def parse_colspecs(records : String) : Array(Hash(String, String | Int32))
      records = records.delete(' ') if records.includes?(' ')

      # Check for simple number (equal column spread)
      if records == records.to_i?.try(&.to_s)
        return Array.new(records.to_i) { {"width" => 1} of String => String | Int32 }
      end

      specs = [] of Hash(String, String | Int32)
      delimiter = records.includes?(',') ? ',' : ';'
      records.split(delimiter, remove_empty: false).each do |record|
        if record.empty?
          specs << {"width" => 1} of String => String | Int32
        elsif (m = ColumnSpecRx.match(record))
          spec = {} of String => String | Int32
          if (align = m[2]?)
            colspec, rowspec = align.split('.')
            if !colspec.empty? && TableCellHorzAlignments.has_key?(colspec)
              spec["halign"] = TableCellHorzAlignments[colspec]
            end
            if rowspec && !rowspec.empty? && TableCellVertAlignments.has_key?(rowspec)
              spec["valign"] = TableCellVertAlignments[rowspec]
            end
          end
          if (width = m[3]?)
            spec["width"] = width == "~" ? -1 : width.to_i
          else
            spec["width"] = 1
          end
          if (repeat = m[1]?)
            repeat.to_i.times { specs << spec.dup }
          else
            specs << spec
          end
        end
      end
      specs
    end

    # Process consecutive attribute entry lines.
    def process_attribute_entries(reader : Reader, document : Document, attributes : Hash(String, String)? = nil) : Nil
      reader.skip_comment_lines
      while process_attribute_entry(reader, document, attributes)
        reader.advance
        reader.skip_comment_lines
      end
    end

    # Process a single attribute entry line.
    def process_attribute_entry(reader : Reader, document : Document, attributes : Hash(String, String)? = nil, match : Regex::MatchData? = nil) : Bool
      unless match
        return false unless reader.has_more_lines?
        line = reader.peek_line
        return false unless line
        match = AttributeEntryRx.match(line)
        return false unless match
      end

      value = match[2]? || ""
      if value.ends_with?(" \\")
        value = value[0, value.size - 2].rstrip
        while reader.advance
          next_line = reader.peek_line || ""
          break if next_line.empty?
          next_line = next_line.lstrip
          keep_open = next_line.ends_with?(" \\")
          next_line = next_line[0, next_line.size - 2].rstrip if keep_open
          value = "#{value} #{next_line}"
          break unless keep_open
        end
      end

      store_attribute(match[1], value, document, attributes)
      true
    end

    # Read paragraph lines until a break condition is met.
    def read_paragraph_lines(reader : Reader) : Array(String)
      reader.read_lines_until(break_on_blank_lines: true, break_on_list_continuation: true, preserve_last_line: true)
    end

    # Resolve the 0-index marker for a list item.
    def resolve_list_marker(list_type : Symbol, marker : String) : String
      case list_type
      when :ulist
        marker
      when :olist
        resolve_ordered_list_marker(marker)
      else # :colist
        "<1>"
      end
    end

    # Resolve the 0-index marker for an ordered list item.
    def resolve_ordered_list_marker(marker : String) : String
      return marker if marker.starts_with?('.')
      if marker.matches?(/^\d+\./)
        "1."
      elsif marker.matches?(/^[a-z]\./)
        "a."
      elsif marker.matches?(/^[A-Z]\./)
        "A."
      elsif marker.matches?(/^[ivx]+\)/)
        "i)"
      elsif marker.matches?(/^[IVX]+\)/)
        "I)"
      else
        marker
      end
    end

    # Convert a string to a legal attribute name.
    def sanitize_attribute_name(name : String) : String
      name.gsub(InvalidAttributeNameCharsRx, "").downcase
    end

    # Store an attribute in the document.
    def store_attribute(name : String, value : String, doc : Document? = nil, attrs : Hash(String, String)? = nil) : Tuple(String, String?)
      actual_value : String? = value
      if name.ends_with?('!')
        name = name[0, name.size - 1]
        actual_value = nil
      elsif name.starts_with?('!')
        name = name[1..]
        actual_value = nil
      end

      name = sanitize_attribute_name(name)
      name = "sectnums" if name == "numbered"
      name = "hardbreaks-option" if name == "hardbreaks"

      if doc
        if actual_value
          if name == "leveloffset" && (actual_value.starts_with?('+') || actual_value.starts_with?('-'))
            current = (doc.attributes["leveloffset"]? || "0").to_i
            offset = actual_value.to_i
            actual_value = (current + offset).to_s
          end
          doc.attributes[name] = actual_value
          attrs[name] = actual_value if attrs
        else
          doc.attributes.delete(name)
          attrs.try(&.delete(name))
        end
      elsif attrs
        if actual_value
          attrs[name] = actual_value
        else
          attrs.delete(name)
        end
      end

      {name, actual_value}
    end

    # Setext (two-line) section title levels.
    SETEXT_SECTION_LEVELS = {
      '=' => 0,
      '-' => 1,
      '~' => 2,
      '^' => 3,
      '+' => 4,
    }

    # Check whether the two lines form a setext-style section title.
    def setext_section_title?(line1 : String, line2 : String) : Int32?
      return nil if line2.empty?
      ch0 = line2[0]
      if (level = SETEXT_SECTION_LEVELS[ch0]?) &&
         uniform?(line2, ch0.to_s, line2.size) &&
         SetextSectionTitleRx.matches?(line1) &&
         (line1.size - line2.size).abs < 2
        level
      else
        nil
      end
    end

    # Convert a string to a block context Symbol.
    def string_to_block_context(name : String) : Symbol?
      BLOCK_CONTEXT_MAP[name]?
    end

    BLOCK_CONTEXT_MAP = {
      "abstract"     => :abstract,
      "admonition"   => :admonition,
      "asciimath"    => :asciimath,
      "audio"        => :audio,
      "colist"       => :colist,
      "comment"      => :comment,
      "dlist"        => :dlist,
      "example"      => :example,
      "fenced_code"  => :fenced_code,
      "floating_title" => :floating_title,
      "image"        => :image,
      "latexmath"    => :latexmath,
      "listing"      => :listing,
      "literal"      => :literal,
      "olist"        => :olist,
      "open"         => :open,
      "page_break"   => :page_break,
      "paragraph"    => :paragraph,
      "partintro"    => :partintro,
      "pass"         => :pass,
      "preamble"     => :preamble,
      "quote"        => :quote,
      "sidebar"      => :sidebar,
      "source"       => :source,
      "stem"         => :stem,
      "table"        => :table,
      "thematic_break" => :thematic_break,
      "toc"          => :toc,
      "ulist"        => :ulist,
      "verse"        => :verse,
      "video"        => :video,
    }

    # Check if a string is uniform (all the same character).
    def uniform?(str : String, chr : String, len : Int32) : Bool
      return false if str.empty? || chr.empty?
      str.count(chr[0]) == len
    end

    # Process authors from an author line.
    def process_authors(author_line : String, names_only : Bool = false, multiple : Bool = true) : Hash(String, String)
      author_metadata = {} of String => String
      author_idx = 0
      entries = multiple && author_line.includes?(';') ? author_line.split(AuthorDelimiterRx) : [author_line]

      entries.each do |author_entry|
        next if author_entry.empty?
        author_idx += 1

        key_suffix = author_idx == 1 ? "" : "_#{author_idx}"
        segments = author_entry.strip.split(/\s+/, 3)

        if segments.size >= 1
          fname = segments[0].tr("_", " ")
          author = fname
          initials = fname[0].to_s

          author_metadata["firstname#{key_suffix}"] = fname
          if segments.size == 3
            mname = segments[1].tr("_", " ")
            lname = segments[2].tr("_", " ")
            author = "#{fname} #{mname} #{lname}"
            initials = "#{fname[0]}#{mname[0]}#{lname[0]}"
            author_metadata["middlename#{key_suffix}"] = mname
            author_metadata["lastname#{key_suffix}"] = lname
          elsif segments.size == 2
            lname = segments[1].tr("_", " ")
            author = "#{fname} #{lname}"
            initials = "#{fname[0]}#{lname[0]}"
            author_metadata["lastname#{key_suffix}"] = lname
          end

          author_metadata["author#{key_suffix}"] = author
          author_metadata["authorinitials#{key_suffix}"] = initials
        end

        if author_idx == 1
          author_metadata["authors"] = author_metadata["author"]? || ""
        else
          if author_idx == 2
            AuthorKeys.each do |key|
              author_metadata["#{key}_1"] = author_metadata[key] if author_metadata.has_key?(key)
            end
          end
          author_metadata["authors"] = "#{author_metadata["authors"]?}, #{author_metadata["author#{key_suffix}"]?}"
        end
      end

      author_metadata["authorcount"] = author_idx.to_s
      author_metadata
    end

    # --------------------------------------------------------------------------
    # Compliance flags (can be made configurable later)
    # --------------------------------------------------------------------------

    COMPLIANCE_MARKDOWN_SYNTAX                = true
    COMPLIANCE_UNDERLINE_STYLE_SECTION_TITLES = true
  end
end
