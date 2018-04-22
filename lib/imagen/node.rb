# frozen_string_literal: true

module Imagen
  module Node
    # Abstract base class
    class Base
      attr_reader :ast_node,
                  :children,
                  :name

      def initialize
        @children = []
      end

      def build_from_ast(ast_node)
        tap { @ast_node = ast_node }
      end

      def file_path
        ast_node.location.name.source_buffer.name
      end

      def first_line
        ast_node.location.first_line
      end

      def last_line
        ast_node.location.last_line
      end

      def source
        source_lines.join("\n")
      end

      def source_lines_with_numbers
        (first_line..last_line).zip(source_lines)
      end

      def source_lines
        ast_node.location.expression.source_buffer.source_lines[
          first_line - 1,
          last_line
        ]
      end

      def find_all(matcher, ret = [])
        ret.tap do
          ret << self if matcher.call(self)
          children.each { |child| child.find_all(matcher, ret) }
        end
      end
    end

    # Root node for a given directory
    class Root < Base
      attr_reader :dir

      def build_from_dir(dir)
        @dir = dir
        list_files.each do |path|
          begin
            Imagen::Visitor.traverse(Parser::CurrentRuby.parse_file(path), self)
          rescue Parser::SyntaxError => err
            warn "#{path}: #{err} #{err.message}"
          end
        end
        self
      end

      # TODO: fix wrong inheritance
      def file_path
        dir
      end

      def first_line
        nil
      end

      def last_line
        nil
      end

      def source
        nil
      end

      private

      def list_files
        return [dir] if File.file?(dir)
        Dir.glob("#{dir}/**/*.rb").reject { |path| path =~ Imagen::EXCLUDE_RE }
      end
    end

    # Represents a Ruby module
    class Module < Base
      def build_from_ast(ast_node)
        super
        tap { @name = ast_node.children[0].children[1].to_s }
      end
    end

    # Represents a Ruby class
    class Class < Base
      def build_from_ast(ast_node)
        super
        tap { @name = ast_node.children[0].children[1].to_s }
      end
    end

    # Represents a Ruby class method
    class CMethod < Base
      def build_from_ast(ast_node)
        super
        tap { @name = ast_node.children[1].to_s }
      end
    end

    # Represents a Ruby instance method
    class IMethod < Base
      def build_from_ast(ast_node)
        super
        tap { @name = ast_node.children[0].to_s }
      end
    end
  end
end
