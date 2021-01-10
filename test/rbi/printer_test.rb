# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class PrinterTest < Minitest::Test
    extend T::Sig
    # Scope

    def test_scope_nested
      rbi = RBI.new do |m|
        m << Module.new("M0") do |m0|
          m0 << Module.new("M1") do |m1|
            m1 << Module.new("M11")
            m1 << Module.new("M12")
          end
          m0 << Module.new("M2")
        end
      end

      assert_equal(<<~RBI, rbi.to_rbi)
        module M0
          module M1
            module M11; end
            module M12; end
          end

          module M2; end
        end
      RBI
    end

    def test_module
      rbi = RBI.new
      rbi << Module.new("M")

      assert_equal(<<~RBI, rbi.to_rbi)
        module M; end
      RBI
    end

    def test_module_with_modifiers
      rbi = RBI.new
      rbi << Module.new("M", interface: true)

      assert_equal(<<~RBI, rbi.to_rbi)
        module M
          interface!
        end
      RBI
    end

    def test_class
      rbi = RBI.new
      rbi << Class.new("C")

      assert_equal(<<~RBI, rbi.to_rbi)
        class C; end
      RBI
    end

    def test_class_with_modifiers
      rbi = RBI.new
      rbi << Class.new("C", superclass: "A", abstract: true, sealed: true)

      assert_equal(<<~RBI, rbi.to_rbi)
        class C < A
          abstract!
          sealed!
        end
      RBI
    end

    def test_class_with_superclass
      rbi = RBI.new
      rbi << Class.new("C", superclass: "A")

      assert_equal(<<~RBI, rbi.to_rbi)
        class C < A; end
      RBI
    end

    def test_tstruct
      rbi = RBI.new
      rbi << TStruct.new("C")

      assert_equal(<<~RBI, rbi.to_rbi)
        class C < T::Struct; end
      RBI
    end

    # Props

    def test_props
      rbi = RBI.new
      rbi << Const.new("FOO")
      rbi << Const.new("FOO", value: "42")
      rbi << AttrReader.new(:foo)
      rbi << AttrAccessor.new(:foo)
      rbi << Method.new("foo")
      rbi << Method.new("foo", params: [Arg.new("a")])
      rbi << Method.new("foo", params: [Arg.new("a"), Arg.new("b"), Arg.new("c")])
      rbi << Include.new("Foo")
      rbi << Extend.new("Foo")
      rbi << Prepend.new("Foo")

      assert_equal(<<~RBI, rbi.to_rbi)
        FOO
        FOO = 42
        attr_reader :foo
        attr_accessor :foo
        def foo; end
        def foo(a); end
        def foo(a, b, c); end
        include Foo
        extend Foo
        prepend Foo
      RBI
    end

    def test_props_nested
      rbi = RBI.new
      foo = Class.new("Foo")
      foo << Const.new("FOO")
      foo << Const.new("FOO", value: "42")
      foo << AttrReader.new(:foo)
      foo << AttrAccessor.new(:foo)
      foo << Method.new("foo")
      foo << Method.new("foo", params: [Arg.new("a")])
      foo << Method.new("foo", params: [
        Arg.new("a"),
        OptArg.new("b", value: "_"),
        KwArg.new("c"),
        KwOptArg.new("d", value: "_"),
      ])
      foo << Include.new("Foo")
      foo << Extend.new("Foo")
      foo << Prepend.new("Foo")
      rbi << foo

      assert_equal(<<~RBI, rbi.to_rbi)
        class Foo
          FOO
          FOO = 42
          attr_reader :foo
          attr_accessor :foo
          def foo; end
          def foo(a); end
          def foo(a, b = _, c:, d: _); end
          include Foo
          extend Foo
          prepend Foo
        end
      RBI
    end

    # Sorbet

    def test_attr_sigs
      rbi = RBI.new
      rbi << AttrReader.new(:foo)
      rbi << AttrReader.new(:foo, type: nil)
      rbi << AttrReader.new(:foo, type: "Foo")
      rbi << AttrAccessor.new(:foo, type: "Foo")
      rbi << AttrAccessor.new(:foo)

      assert_equal(<<~RBI, rbi.to_rbi)
        attr_reader :foo
        attr_reader :foo

        sig { returns(Foo) }
        attr_reader :foo

        sig { params(foo: Foo).returns(Foo) }
        attr_accessor :foo

        attr_accessor :foo
      RBI
    end

    def test_method_sigs
      rbi = RBI.new
      rbi << Method.new("foo")
      rbi << Method.new("foo", return_type: "String")
      rbi << Method.new("foo", return_type: "void", params: [Arg.new("a", type: "String")])
      rbi << Method.new("foo", return_type: "Integer", params: [Arg.new("a", type: "String")])
      rbi << Method.new("foo", return_type: "void", params: [
        Arg.new("a", type: "String"),
        OptArg.new("b", value: "_", type: "String"),
        KwArg.new("c", type: "String"),
        KwOptArg.new("d", value: "_", type: "String"),
      ])

      assert_equal(<<~RBI, rbi.to_rbi)
        def foo; end

        sig { returns(String) }
        def foo; end

        sig { params(a: String).void }
        def foo(a); end

        sig { params(a: String).returns(Integer) }
        def foo(a); end

        sig { params(a: String, b: String, c: String, d: String).void }
        def foo(a, b = _, c:, d: _); end
      RBI
    end

    # Sorbet

    def test_print_sigs
      rbi = RBI.new
      rbi << Sig.new
      rbi << Sig.new
      rbi << Sig.new
      rbi << Sig.new
      rbi << Sig.new
      rbi << Sig.new

      assert_equal(<<~RBI, rbi.to_rbi)
        sig {}
        sig {}
        sig {}
        sig {}
        sig {}
        sig {}
      RBI
    end
  end
end
