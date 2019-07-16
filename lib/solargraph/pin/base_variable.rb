# frozen_string_literal: true

module Solargraph
  module Pin
    class BaseVariable < Base
      include Solargraph::Source::NodeMethods

      # @return [Parser::AST::Node, nil]
      attr_reader :assignment

      # @param assignment [Parser::AST::Node, nil]
      def initialize assignment: nil, **splat
        super(splat)
        @assignment = assignment
      end

      def signature
        @signature ||= resolve_node_signature(@assignment)
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      # @return [Integer]
      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::VARIABLE
      end

      def return_type
        @return_type ||= generate_complex_type
      end

      def nil_assignment?
        return_type.nil?
      end

      def variable?
        true
      end

      def probe api_map
        return ComplexType::UNDEFINED if @assignment.nil?
        types = []
        returns_from(@assignment).each do |node|
          pos = Solargraph::Position.new(node.loc.expression.last_line, node.loc.expression.last_column)
          clip = api_map.clip_at(location.filename, pos)
          result = clip.infer
          types.push result unless result.undefined?
        end
        return ComplexType::UNDEFINED if types.empty?
        ComplexType.try_parse(*types.map(&:tag))
      end

      def == other
        return false unless super
        assignment == other.assignment
      end

      def try_merge! pin
        return false unless super
        @assignment = pin.assignment
        @return_type = pin.return_type
        true
      end

      private

      # @return [ComplexType]
      def generate_complex_type
        tag = docstring.tag(:type)
        return ComplexType.try_parse(*tag.types) unless tag.nil? || tag.types.nil? || tag.types.empty?
        ComplexType.new
      end
    end
  end
end
