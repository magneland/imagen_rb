# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

describe Imagen::Node::Base do
  let(:ast) { Parser::CurrentRuby.parse_file('spec/fixtures/class.rb') }

  it 'stores filename, first_line and last_line' do
    node = described_class.new.build_from_ast(ast)

    expect(node.first_line).to eq(3)
    expect(node.last_line).to eq(18)
    expect(node.file_path).to eq('spec/fixtures/class.rb')
  end

  it 'has access to source code' do
    input = <<-STR
      if 2 + 2 == 5
        puts 'wow'
      end
    STR

    node = described_class.new.build_from_ast(
      Parser::CurrentRuby.parse(input)
    )

    # TODO: do we need the trailing newline?
    expect(node.source + "\n").to eq <<-STR
      if 2 + 2 == 5
        puts 'wow'
      end
    STR

    expect(node.source_lines_with_numbers).to eq(
      [
        [1, '      if 2 + 2 == 5'],
        [2, "        puts 'wow'"],
        [3, '      end']
      ]
    )
  end
end

describe Imagen::Node::Root do
  let(:input) do
    <<-STR
      if 2 + 2 == 5
        puts 'wow'
      end
    STR
  end

  describe '#human_name' do
    let(:node) do
      described_class.new.build_from_ast(Parser::CurrentRuby.parse(input))
    end

    it 'has human name' do
      expect(node.human_name).to eq('root')
    end
  end

  it 'builds from file' do
    node = described_class.new.build_from_file('spec/fixtures/class.rb')

    expect(node).to be_a(Imagen::Node::Root)
    expect(node.children[0].source_lines.length).to eq(17)
  end

  it 'prints syntax errors' do
    Tempfile.open do |f|
      f.write("do puts 'incomplete' end")
      f.flush
      expect { described_class.new.build_from_file(f.path) }
        .to output(/unexpected token kDO/).to_stderr
    end
  end
end

describe Imagen::Node::Module do
  let(:input) do
    <<-STR
      module Foo
        if 2 + 2 == 5
          puts 'wow'
        end
      end
    STR
  end

  let(:node) do
    described_class.new.build_from_ast(Parser::CurrentRuby.parse(input))
  end

  it 'has human name' do
    expect(node.human_name).to eq('module')
  end
end

describe Imagen::Node::Class do
  let(:input) do
    <<-STR
      class Bar
        if 2 + 2 == 5
          puts 'wow'
        end
      end
    STR
  end

  let(:node) do
    described_class.new.build_from_ast(Parser::CurrentRuby.parse(input))
  end

  it 'has human name' do
    expect(node.human_name).to eq('class')
  end
end

describe Imagen::Node::CMethod do
  let(:input) do
    <<-STR
      class Tom
        def self.taylor
          puts 'wow'
        end
      end
    STR
  end

  let(:node) do
    described_class.new.build_from_ast(Parser::CurrentRuby.parse(input))
  end

  it 'has human name' do
    expect(node.human_name).to eq('class method')
  end
end

describe Imagen::Node::IMethod do
  let(:input) do
    <<-STR
      class Hello
        def darkness
          puts 'my old friend'
        end
      end
    STR
  end

  let(:node) do
    described_class.new.build_from_ast(Parser::CurrentRuby.parse(input))
  end

  it 'has human name' do
    expect(node.human_name).to eq('instance method')
  end
end
