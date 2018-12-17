use "debug"
use "collections"
use "ponytest"
use uuid = "../../uuid"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestParse)
    test(_TestParseUpper)
    test(_TestVersion3)
    test(_TestVersion4)
    test(_TestVersion5)

primitive _ParseTestCases
  fun apply(): Array[(String, uuid.Version, (uuid.Variant | None))] =>
    [
      ("f47ac10b-58cc-0372-8567-0e02b2c3d479",  0, uuid.RFC4122)
      ("f47ac10b-58cc-1372-8567-0e02b2c3d479",  1, uuid.RFC4122)
      ("f47ac10b-58cc-2372-8567-0e02b2c3d479",  2, uuid.RFC4122)
      ("f47ac10b-58cc-3372-8567-0e02b2c3d479",  3, uuid.RFC4122)
      ("f47ac10b-58cc-4372-8567-0e02b2c3d479",  4, uuid.RFC4122)
      ("f47ac10b-58cc-5372-8567-0e02b2c3d479",  5, uuid.RFC4122)
      ("f47ac10b-58cc-6372-8567-0e02b2c3d479",  6, uuid.RFC4122)
      ("f47ac10b-58cc-7372-8567-0e02b2c3d479",  7, uuid.RFC4122)
      ("f47ac10b-58cc-8372-8567-0e02b2c3d479",  8, uuid.RFC4122)
      ("f47ac10b-58cc-9372-8567-0e02b2c3d479",  9, uuid.RFC4122)
      ("f47ac10b-58cc-a372-8567-0e02b2c3d479", 10, uuid.RFC4122)
      ("f47ac10b-58cc-b372-8567-0e02b2c3d479", 11, uuid.RFC4122)
      ("f47ac10b-58cc-c372-8567-0e02b2c3d479", 12, uuid.RFC4122)
      ("f47ac10b-58cc-d372-8567-0e02b2c3d479", 13, uuid.RFC4122)
      ("f47ac10b-58cc-e372-8567-0e02b2c3d479", 14, uuid.RFC4122)
      ("f47ac10b-58cc-f372-8567-0e02b2c3d479", 15, uuid.RFC4122)

      ("urn:uuid:f47ac10b-58cc-4372-0567-0e02b2c3d479", 4, uuid.Reserved)
      ("URN:UUID:f47ac10b-58cc-4372-0567-0e02b2c3d479", 4, uuid.Reserved)

      ("f47ac10b-58cc-4372-0567-0e02b2c3d479", 4, uuid.Reserved)
      ("f47ac10b-58cc-4372-1567-0e02b2c3d479", 4, uuid.Reserved)
      ("f47ac10b-58cc-4372-2567-0e02b2c3d479", 4, uuid.Reserved)
      ("f47ac10b-58cc-4372-3567-0e02b2c3d479", 4, uuid.Reserved)
      ("f47ac10b-58cc-4372-4567-0e02b2c3d479", 4, uuid.Reserved)
      ("f47ac10b-58cc-4372-5567-0e02b2c3d479", 4, uuid.Reserved)
      ("f47ac10b-58cc-4372-6567-0e02b2c3d479", 4, uuid.Reserved)
      ("f47ac10b-58cc-4372-7567-0e02b2c3d479", 4, uuid.Reserved)
      ("f47ac10b-58cc-4372-8567-0e02b2c3d479", 4, uuid.RFC4122)
      ("f47ac10b-58cc-4372-9567-0e02b2c3d479", 4, uuid.RFC4122)
      ("f47ac10b-58cc-4372-a567-0e02b2c3d479", 4, uuid.RFC4122)
      ("f47ac10b-58cc-4372-b567-0e02b2c3d479", 4, uuid.RFC4122)
      ("f47ac10b-58cc-4372-c567-0e02b2c3d479", 4, uuid.Microsoft)
      ("f47ac10b-58cc-4372-d567-0e02b2c3d479", 4, uuid.Microsoft)
      ("f47ac10b-58cc-4372-e567-0e02b2c3d479", 4, uuid.Future)
      ("f47ac10b-58cc-4372-f567-0e02b2c3d479", 4, uuid.Future)

      ("f47ac10b158cc-5372-a567-0e02b2c3d479", 0, None)
      ("f47ac10b-58cc25372-a567-0e02b2c3d479", 0, None)
      ("f47ac10b-58cc-53723a567-0e02b2c3d479", 0, None)
      ("f47ac10b-58cc-5372-a56740e02b2c3d479", 0, None)
      ("f47ac10b-58cc-5372-a567-0e02-2c3d479", 0, None)
      ("g47ac10b-58cc-4372-a567-0e02b2c3d479", 0, None)

      ("{f47ac10b-58cc-0372-8567-0e02b2c3d479}", 0, uuid.RFC4122)
      ("{f47ac10b-58cc-0372-8567-0e02b2c3d479",  0, None)
      ("f47ac10b-58cc-0372-8567-0e02b2c3d479}",  0, None)

      ("f47ac10b58cc037285670e02b2c3d479",  0, uuid.RFC4122)
      ("f47ac10b58cc037285670e02b2c3d4790", 0, None)
      ("f47ac10b58cc037285670e02b2c3d47",   0, None)
    ]

class iso _TestParse is UnitTest
  fun name(): String => "test parse"

  fun apply(h: TestHelper) =>
    for test in _ParseTestCases().values() do
      (let str, let version, let variant_or_none) = test
      match variant_or_none
      | let variant: uuid.Variant =>
				match uuid.Parse(str)
				| let id: uuid.UUID =>
					h.assert_eq[uuid.Version](version, id.version())
					h.assert_is[uuid.Variant](variant, id.variant())
				else
					h.assert_true(false)
				end
      | None =>
        match uuid.Parse(str)
        | let id: uuid.UUID => h.assert_true(false)
        end
			end
    end

class iso _TestParseUpper is UnitTest
  fun name(): String => "test parse uppercase"

  fun apply(h: TestHelper) =>
    for test in _ParseTestCases().values() do
      (let str, let version, let variant_or_none) = test
      match variant_or_none
      | let variant: uuid.Variant =>
				match uuid.Parse(str.upper())
				| let id: uuid.UUID =>
					h.assert_eq[uuid.Version](version, id.version())
					h.assert_is[uuid.Variant](variant, id.variant())
				else
					h.assert_true(false)
				end
      | None =>
        match uuid.Parse(str)
        | let id: uuid.UUID => h.assert_true(false)
        end
			end
    end

class _TestVersion3 is UnitTest
  fun name(): String => "test uuid v3 (md5)"

  fun apply(h: TestHelper) =>
    let id = uuid.UUID.v3(uuid.DNS, "ponylang.io".array())
    h.assert_eq[String]("e75628a8-a90c-3efb-a268-62817a99758b", id.string())

class iso _TestVersion4 is UnitTest
  fun name(): String => "test uuid v4"

  fun apply(h: TestHelper) =>
    let set = Set[uuid.UUID]
    for i in Range(0, 1000) do
      let id = uuid.UUID.v4()
      h.assert_false(set.contains(id))
      set.set(id)
      match uuid.Parse(id.string())
      | let id': uuid.UUID =>
        h.assert_eq[uuid.UUID](id, id')
        h.assert_eq[uuid.Version](4, id.version())
        h.assert_is[uuid.Variant](uuid.RFC4122, id.variant())
      else
        h.assert_true(false)
      end
    end

class _TestVersion5 is UnitTest
  fun name(): String => "test uuid v5 (sha1)"

  fun apply(h: TestHelper) =>
    let id = uuid.UUID.v5(uuid.DNS, "ponylang.io".array())
    h.assert_eq[String]("1ab6d83f-a59b-5db3-888b-a14262e00ad8", id.string())
