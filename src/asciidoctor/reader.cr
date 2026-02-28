module Asciidoctor
  # A Cursor tracks the file, directory, path, and line number of a position
  # in the source.
  class Cursor
    getter dir : String
    getter file : String?
    getter lineno : Int32
    getter path : String

    def initialize(file : String? = nil, dir : String? = nil, path : String? = nil, @lineno : Int32 = 1)
      @file = file
      if file
        @dir = dir || File.dirname(file)
        @path = path || File.basename(file)
      else
        @dir = dir || "."
        @path = path || "<stdin>"
      end
    end

    def advance(num : Int32) : Nil
      @lineno += num
    end

    def line_info : String
      "#{@path}: line #{@lineno}"
    end

    def to_s(io : IO) : Nil
      io << line_info
    end

    def to_source_location : SourceLocation
      SourceLocation.new(@file, @lineno, @dir, @path)
    end
  end

  # Methods for retrieving lines from AsciiDoc source files.
  class Reader
    include Logging

    getter dir : String
    getter file : String?
    getter lineno : Int32
    getter path : String
    getter source_lines : Array(String)

    property process_lines : Bool
    property unterminated : Bool?

    @lines : Array(String)
    @look_ahead : Int32
    @mark : Tuple(String?, String, String, Int32)?
    @saved : NamedTuple(
      lines: Array(String),
      file: String?,
      dir: String,
      path: String,
      lineno: Int32,
      look_ahead: Int32,
      process_lines: Bool,
    )?
    @unescape_next_line : Bool

    def initialize(data : Array(String) | String | Nil = nil, cursor : Cursor | String | Nil = nil, opts = {} of Symbol => String | Bool)
      @file = nil
      @dir = "."
      @path = "<stdin>"
      @lineno = 1

      case cursor
      when String
        @file = cursor
        @dir = File.dirname(cursor)
        @path = File.basename(cursor)
      when Cursor
        @file = cursor.file
        @dir = cursor.dir
        @path = cursor.path
        @lineno = cursor.lineno
      end

      @source_lines = prepare_lines(data, opts)
      @lines = @source_lines.reverse
      @mark = nil
      @look_ahead = 0
      @process_lines = true
      @unescape_next_line = false
      @unterminated = nil
      @saved = nil
    end

    # Check whether there are any lines left to read.
    def has_more_lines? : Bool
      if @lines.empty?
        @look_ahead = 0
        false
      else
        true
      end
    end

    # Check whether this reader is empty (contains no lines).
    def empty? : Bool
      if @lines.empty?
        @look_ahead = 0
        true
      else
        false
      end
    end

    # Alias for empty?
    def eof? : Bool
      empty?
    end

    # Peek at the next line and check if it's empty (i.e., whitespace only).
    def next_line_empty? : Bool
      line = peek_line
      line.nil? || line.empty?
    end

    # Peek at the next line of source data. Processes the line if not
    # already marked as processed, but does not consume it.
    def peek_line(direct : Bool = false) : String?
      loop do
        next_line = @lines.last?
        if direct || @look_ahead > 0
          return next_line.nil? ? nil : (@unescape_next_line ? next_line[1..] : next_line)
        end
        if next_line
          line = process_line(next_line)
          return line if line
        else
          @look_ahead = 0
          return nil
        end
      end
    end

    # Peek at the next multiple lines of source data.
    def peek_lines(num : Int32? = nil, direct : Bool = false) : Array(String)
      old_look_ahead = @look_ahead
      result = [] of String
      max = num || MAX_INT.to_i32
      max.times do
        line = direct ? shift : read_line
        if line
          result << line
        else
          @lineno -= 1 if direct
          break
        end
      end

      unless result.empty?
        unshift_all(result)
        @look_ahead = old_look_ahead if direct
      end

      result
    end

    # Get the next line of source data. Consumes the line returned.
    def read_line : String?
      shift if @look_ahead > 0 || has_more_lines?
    end

    # Get the remaining lines of source data.
    def read_lines : Array(String)
      lines = [] of String
      while has_more_lines?
        line = shift
        lines << line if line
      end
      lines
    end

    # Get the remaining lines of source data joined as a String.
    def read : String
      read_lines.join(LF)
    end

    # Advance to the next line by discarding the line at the front of the stack.
    def advance : Bool
      shift ? true : false
    end

    # Get a copy of the remaining lines.
    def lines : Array(String)
      @lines.reverse
    end

    # Get a copy of the remaining lines joined as a String.
    def string : String
      @lines.reverse.join(LF)
    end

    # Get the source lines joined as a String.
    def source : String
      @source_lines.join(LF)
    end

    # Get information about the last line read.
    def line_info : String
      "#{@path}: line #{@lineno}"
    end

    # Return a Cursor for the current position.
    def cursor : Cursor
      Cursor.new(@file, @dir, @path, @lineno)
    end

    # Return a Cursor at the specified line number.
    def cursor_at_line(lineno : Int32) : Cursor
      Cursor.new(@file, @dir, @path, lineno)
    end

    # Return a Cursor at the marked position.
    def cursor_at_mark : Cursor
      if (m = @mark)
        Cursor.new(m[0], m[1], m[2], m[3])
      else
        cursor
      end
    end

    # Return a Cursor one line before the marked position.
    def cursor_before_mark : Cursor
      if (m = @mark)
        Cursor.new(m[0], m[1], m[2], m[3] - 1)
      else
        Cursor.new(@file, @dir, @path, @lineno - 1)
      end
    end

    # Return a Cursor at the previous line.
    def cursor_at_prev_line : Cursor
      Cursor.new(@file, @dir, @path, @lineno - 1)
    end

    # Mark the current position.
    def mark : Nil
      @mark = {@file, @dir, @path, @lineno}
      nil
    end

    # Push a line onto the beginning of the Array of source data.
    def unshift_line(line_to_restore : String) : Nil
      unshift(line_to_restore)
      nil
    end

    # Push an Array of lines onto the front of the Array of source data.
    def unshift_lines(lines_to_restore : Array(String)) : Nil
      unshift_all(lines_to_restore)
    end

    # Replace the next line with the specified line.
    def replace_next_line(replacement : String) : Bool
      shift
      unshift(replacement)
      true
    end

    # Return all lines until a terminator, blank line, or block condition.
    def read_lines_until(
      terminator : String? = nil,
      break_on_blank_lines : Bool = false,
      break_on_list_continuation : Bool = false,
      skip_first_line : Bool = false,
      preserve_last_line : Bool = false,
      read_last_line : Bool = false,
      skip_line_comments : Bool = false,
      skip_processing : Bool = false,
      context : Symbol? = nil,
      cursor_at : Cursor? = nil,
      &block : String -> Bool
    ) : Array(String)
      read_lines_until_impl(
        terminator: terminator,
        break_on_blank_lines: break_on_blank_lines,
        break_on_list_continuation: break_on_list_continuation,
        skip_first_line: skip_first_line,
        preserve_last_line: preserve_last_line,
        read_last_line: read_last_line,
        skip_line_comments: skip_line_comments,
        skip_processing: skip_processing,
        context: context,
        cursor_at: cursor_at,
        &block
      )
    end

    # Overload without block.
    def read_lines_until(
      terminator : String? = nil,
      break_on_blank_lines : Bool = false,
      break_on_list_continuation : Bool = false,
      skip_first_line : Bool = false,
      preserve_last_line : Bool = false,
      read_last_line : Bool = false,
      skip_line_comments : Bool = false,
      skip_processing : Bool = false,
      context : Symbol? = nil,
      cursor_at : Cursor? = nil
    ) : Array(String)
      read_lines_until_impl(
        terminator: terminator,
        break_on_blank_lines: break_on_blank_lines,
        break_on_list_continuation: break_on_list_continuation,
        skip_first_line: skip_first_line,
        preserve_last_line: preserve_last_line,
        read_last_line: read_last_line,
        skip_line_comments: skip_line_comments,
        skip_processing: skip_processing,
        context: context,
        cursor_at: cursor_at,
      )
    end

    # Skip blank lines at the cursor.
    def skip_blank_lines : Int32?
      return nil if empty?

      num_skipped = 0
      while (next_line = peek_line)
        return num_skipped unless next_line.empty?
        shift
        num_skipped += 1
      end
      nil
    end

    # Skip consecutive comment lines and block comments.
    def skip_comment_lines : Nil
      return if empty?

      while (next_line = peek_line) && !next_line.empty?
        break unless next_line.starts_with?("//")
        if next_line.starts_with?("///")
          ll = next_line.size
          break unless ll > 3 && next_line == "/" * ll
          read_lines_until(terminator: next_line, skip_first_line: true, read_last_line: true, skip_processing: true, context: :comment)
        else
          shift
        end
      end

      nil
    end

    # Skip consecutive comment lines and return them.
    def skip_line_comments : Array(String)
      return [] of String if empty?

      comment_lines = [] of String
      while (next_line = peek_line) && !next_line.empty?
        break unless next_line.starts_with?("//")
        line = shift
        comment_lines << line if line
      end

      comment_lines
    end

    # Advance to the end of the reader, consuming all remaining lines.
    def terminate : Nil
      @lineno += @lines.size
      @lines.clear
      @look_ahead = 0
      nil
    end

    # Save the state of the reader.
    def save : Nil
      @saved = {
        lines:         @lines.dup,
        file:          @file,
        dir:           @dir,
        path:          @path,
        lineno:        @lineno,
        look_ahead:    @look_ahead,
        process_lines: @process_lines,
      }
      nil
    end

    # Restore the state of the reader.
    def restore_save : Nil
      if (saved = @saved)
        @lines = saved[:lines]
        @file = saved[:file]
        @dir = saved[:dir]
        @path = saved[:path]
        @lineno = saved[:lineno]
        @look_ahead = saved[:look_ahead]
        @process_lines = saved[:process_lines]
        @saved = nil
      end
    end

    # Discard a previous saved state.
    def discard_save : Nil
      @saved = nil
    end

    def to_s(io : IO) : Nil
      io << "#<#{self.class} {path: #{@path.inspect}, line: #{@lineno}}>"
    end

    # --------------------------------------------------------------------------
    # Protected / private methods
    # --------------------------------------------------------------------------

    # Shift the line off the stack and increment the lineno.
    protected def shift : String?
      return nil if @lines.empty?
      @lineno += 1
      @look_ahead -= 1 unless @look_ahead == 0
      @lines.pop
    end

    # Restore the line to the stack and decrement the lineno.
    protected def unshift(line : String) : Nil
      @lineno -= 1
      @look_ahead += 1
      @lines.push(line)
      nil
    end

    # Restore lines to the stack and decrement the lineno.
    protected def unshift_all(lines_to_restore : Array(String)) : Nil
      @lineno -= lines_to_restore.size
      @look_ahead += lines_to_restore.size
      lines_to_restore.reverse_each { |l| @lines.push(l) }
      nil
    end

    # Prepare the source data for parsing.
    protected def prepare_lines(data : Array(String) | String | Nil, opts = {} of Symbol => String | Bool) : Array(String)
      normalize = opts[:normalize]?
      if normalize
        case data
        when Array(String)
          Helpers.prepare_source_array(data, normalize != :chomp)
        when String
          Helpers.prepare_source_string(data, normalize != :chomp)
        else
          [] of String
        end
      else
        case data
        when Array(String)
          data.dup
        when String
          data.chomp.split(LF, remove_empty: false)
        else
          [] of String
        end
      end
    end

    # Process a previously unvisited line.
    protected def process_line(line : String) : String?
      @look_ahead += 1 if @process_lines
      line
    end

    # Internal implementation for read_lines_until.
    private def read_lines_until_impl(
      terminator : String? = nil,
      break_on_blank_lines : Bool = false,
      break_on_list_continuation : Bool = false,
      skip_first_line : Bool = false,
      preserve_last_line : Bool = false,
      read_last_line : Bool = false,
      skip_line_comments : Bool = false,
      skip_processing : Bool = false,
      context : Symbol? = nil,
      cursor_at : Cursor? = nil,
      &block : String -> Bool
    ) : Array(String)
      result = [] of String
      restore_process_lines = false
      if @process_lines && skip_processing
        @process_lines = false
        restore_process_lines = true
      end

      start_cursor = cursor_at || cursor
      line_read = false
      line_restored = false

      shift if skip_first_line

      while (line = read_line)
        should_break = if terminator
                         line == terminator
                       else
                         (break_on_blank_lines && line.empty?) ||
                           (break_on_list_continuation && line_read && line == LIST_CONTINUATION) ||
                           (yield line)
                       end

        if should_break
          result << line if read_last_line
          if preserve_last_line || (break_on_list_continuation && line_read && line == LIST_CONTINUATION)
            unshift(line)
            line_restored = true
          end
          break
        end

        unless skip_line_comments && line.starts_with?("//") && !line.starts_with?("///")
          result << line
          line_read = true
        end
      end

      if restore_process_lines
        @process_lines = true
        @look_ahead -= 1 if line_restored && !terminator
      end

      if terminator && terminator != line
        effective_context = context || terminator
        logger.warn { "unterminated #{effective_context} block at #{start_cursor}" }
        @unterminated = true
      end

      result
    end

    # Overload without block.
    private def read_lines_until_impl(
      terminator : String? = nil,
      break_on_blank_lines : Bool = false,
      break_on_list_continuation : Bool = false,
      skip_first_line : Bool = false,
      preserve_last_line : Bool = false,
      read_last_line : Bool = false,
      skip_line_comments : Bool = false,
      skip_processing : Bool = false,
      context : Symbol? = nil,
      cursor_at : Cursor? = nil
    ) : Array(String)
      result = [] of String
      restore_process_lines = false
      if @process_lines && skip_processing
        @process_lines = false
        restore_process_lines = true
      end

      start_cursor = cursor_at || cursor
      line_read = false
      line_restored = false

      shift if skip_first_line

      while (line = read_line)
        should_break = if terminator
                         line == terminator
                       else
                         (break_on_blank_lines && line.empty?) ||
                           (break_on_list_continuation && line_read && line == LIST_CONTINUATION)
                       end

        if should_break
          result << line if read_last_line
          if preserve_last_line || (break_on_list_continuation && line_read && line == LIST_CONTINUATION)
            unshift(line)
            line_restored = true
          end
          break
        end

        unless skip_line_comments && line.starts_with?("//") && !line.starts_with?("///")
          result << line
          line_read = true
        end
      end

      if restore_process_lines
        @process_lines = true
        @look_ahead -= 1 if line_restored && !terminator
      end

      if terminator && terminator != line
        effective_context = context || terminator
        logger.warn { "unterminated #{effective_context} block at #{start_cursor}" }
        @unterminated = true
      end

      result
    end
  end
end
