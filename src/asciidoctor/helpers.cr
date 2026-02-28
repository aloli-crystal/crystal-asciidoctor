module Asciidoctor
  module Helpers
    extend self

    # Encode the data to UTF-8 and split it into an array of lines.
    # Removes trailing whitespace from every line if trim_end is true,
    # otherwise only removes the trailing newline.
    def prepare_source_array(data : Array(String), trim_end : Bool = true) : Array(String)
      return [] of String if data.empty?
      # Crystal strings are always UTF-8, so no encoding conversion needed.
      # Strip BOM if present on the first line.
      first = data[0]
      if first.starts_with?("\u{FEFF}")
        data = data.dup
        data[0] = first[1..]
      end
      if trim_end
        data.map(&.rstrip)
      else
        data.map(&.chomp)
      end
    end

    # Encode the data to UTF-8, split it into an array of lines, and
    # remove trailing whitespace from every line.
    def prepare_source_string(data : String, trim_end : Bool = true) : Array(String)
      return [] of String if data.empty?
      # Strip BOM if present.
      data = data[1..] if data.starts_with?("\u{FEFF}")
      if trim_end
        data.each_line.map(&.rstrip).to_a
      else
        data.each_line.map(&.chomp).to_a
      end
    end

    # Extract the root name of a file (without extension).
    def rootname(filename : String) : String
      if (ext_idx = filename.rindex('.'))
        filename[0...ext_idx]
      else
        filename
      end
    end

    # Check if the path has an extension.
    def extname?(path : String) : Bool
      !path.rindex('.').nil?
    end

    # Get the extension of a path.
    def extname(path : String, fallback : String = "") : String
      if (idx = path.rindex('.'))
        path[idx..]
      else
        fallback
      end
    end

    # Resolve a system path from the target and start values.
    def resolve(target : String, start : String? = nil) : String
      if target.starts_with?("/") || target.starts_with?("~")
        File.expand_path(target)
      elsif start
        File.expand_path(target, start)
      else
        File.expand_path(target)
      end
    end

    # Check if a string resembles a URI.
    def uriish?(str : String) : Bool
      !!(str =~ UriSniffRx)
    end
  end
end
