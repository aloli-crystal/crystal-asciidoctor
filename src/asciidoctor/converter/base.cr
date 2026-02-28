module Asciidoctor
  module Converter
    # Backend traits for a converter.
    record BackendTraits,
      basebackend : String = "html",
      filetype : String = "html",
      htmlsyntax : String? = nil,
      outfilesuffix : String = ".html"

    # Abstract base class for converters.
    abstract class Base
      # The backend name this converter handles.
      getter backend : String

      # Backend traits for this converter.
      getter backend_traits : BackendTraits

      def initialize(@backend : String)
        @backend_traits = self.class.derive_backend_traits(@backend)
      end

      # Convert a node to its output representation.
      def convert(node : AbstractNode, transform : String? = nil) : String
        transform ||= node.node_name
        dispatch(node, transform)
      end

      # Dispatch conversion to the appropriate method.
      def dispatch(node : AbstractNode, transform : String) : String
        # Subclasses should override this method
        ""
      end

      # Return the content of the node (for pass-through).
      def content_only(node : AbstractNode) : String
        if node.is_a?(AbstractBlock)
          (node.content || "").to_s
        else
          ""
        end
      end

      # Check whether this converter handles the specified transform.
      def handles?(transform : String) : Bool
        true
      end

      # Override backend traits with explicit values.
      protected def init_backend_traits(basebackend : String? = nil, filetype : String? = nil, htmlsyntax : String? = nil, outfilesuffix : String? = nil)
        @backend_traits = BackendTraits.new(
          basebackend: basebackend || @backend_traits.basebackend,
          filetype: filetype || @backend_traits.filetype,
          htmlsyntax: htmlsyntax || @backend_traits.htmlsyntax,
          outfilesuffix: outfilesuffix || @backend_traits.outfilesuffix
        )
      end

      # Derive backend traits from the backend name.
      def self.derive_backend_traits(backend : String, basebackend : String? = nil) : BackendTraits
        bb = basebackend || backend.gsub(/\d+$/, "")
        if (outfilesuffix = DEFAULT_EXTENSIONS[bb]?)
          filetype = outfilesuffix[1..]
        else
          filetype = bb
          outfilesuffix = ".#{filetype}"
        end
        if filetype == "html"
          BackendTraits.new(basebackend: bb, filetype: filetype, htmlsyntax: "html", outfilesuffix: outfilesuffix)
        else
          BackendTraits.new(basebackend: bb, filetype: filetype, outfilesuffix: outfilesuffix)
        end
      end
    end
  end
end
