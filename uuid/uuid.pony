"""
# UUID package

The UUID package provides support for parsing and generating Universally
Unique Identifiers.
"""

use "collections"
use "crypto"
use "format"
use "itertools"
use "random"
use "time"

class val UUID is Equatable[UUID]
  """
  An UUID. Currently it can be used to generate UUIDs of versions 3, 4 and 5.

  ```
  use uuid = "uuid"

  actor Main
    new create(env: Env) =>
      let id = uuid.UUID.v4()
      env.out.print(id.string())
  ```
  """
  let _bytes: Array[U8] val

  new val v3(namespace: Namespace, data: Array[U8] val) =>
    """
    Creates a version 3 UUID (MD5) with the supplied namespace and data.
    """
    _bytes = _hash(MD5, namespace, data, 3)

  new val v4(rand: (Random iso | None) = None) =>
    """
    Creates a version 4 (random) UUID. A seeded
    [Random](https://stdlib.ponylang.io/random-Random/) instance can be given
    as an argument. Otherwise, [Rand](https://stdlib.ponylang.io/random-Rand/)
    will be used, seeded from the current time.
    """
    let rng =
      match consume rand
      | let r: Random => r
      else
        let now = Time.now()
        Rand(now._1.u64(), now._2.u64())
      end
    let bytes = recover Array[U8](Size()) end
    for i in Range(0, Size()) do
      bytes.push(rng.u8())
    end
    try
      bytes(6)? = (bytes(6)? and 0x0f) or 0x40
      bytes(8)? = (bytes(8)? and 0x3f) or 0x90
    end
    _bytes = consume bytes

  new val v5(namespace: Namespace, data: Array[U8] val) =>
    """
    Creates a version 5 UUID (SHA1) with the supplied namespace and data.
    """
    _bytes = _hash(SHA1, namespace, data, 5)

  new val from_array(bytes: Array[U8] val) ? =>
    """
    Creates an UUID from the given array of bytes. An error is raised if
    the array is not 16 bytes.
    """
    if bytes.size() != Size() then
      error
    end
    _bytes = bytes

  fun urn(): String iso^ =>
    """
    Returns a string representation of the UUID with the `urn:uuid:` prefix.
    """
    let s = recover String(36 + 9) end
    s.insert_in_place(0, "urn:uuid:")
    s.insert_in_place(9, string())
    s

  fun variant(): Variant =>
    """
    Returns the variant of the UUID.
    """
    try
      let v = _bytes(8)?
      if (v and 0xc0) == 0x80 then
        RFC4122
      elseif (v and 0xe0) == 0xc0 then
        Microsoft
      elseif (v and 0xe0) == 0xe0 then
        Future
      else
        Reserved
      end
    else
      // not reached
      Reserved
    end

  fun version(): Version =>
    """
    Returns the version of the UUID.
    """
    try _bytes(6)? >> 4 else /* not reached */ 0 end

  fun array(): Array[U8] val =>
    _bytes

  fun string(): String iso^ =>
    """
    Returns a string representation of the UUID.
    """
    let s = recover String(36) end
    s.insert_in_place(0, _hex_string(_bytes.trim(0, 4), 8))
    s.push('-')
    s.insert_in_place(9, _hex_string(_bytes.trim(4, 6), 4))
    s.push('-')
    s.insert_in_place(14, _hex_string(_bytes.trim(6, 8), 4))
    s.push('-')
    s.insert_in_place(19, _hex_string(_bytes.trim(8, 10), 4))
    s.push('-')
    s.insert_in_place(24, _hex_string(_bytes.trim(10), 12))
    s

  fun eq(other: UUID): Bool =>
    let bytes = other.array()
    try
      for i in Range(0, Size()) do
        if _bytes(i)? != bytes(i)? then
          return false
        end
      end
      true
    else
      false
    end

  fun hash(): USize =>
    let p = _bytes.cpointer()
    @ponyint_hash_block[USize](p, Size())

  fun hash64(): U64 =>
    let p = _bytes.cpointer()
    @ponyint_hash_block64[U64](p, Size())

  fun tag _hash(fn: HashFn val, namespace: Namespace, data: Array[U8] val,
                ver: U8): Array[U8] val =>
    let d = recover val
      let d = Array[U8](Size() + data.size())
      d.append(namespace().array())
      d.append(data)
      d
    end
    let bytes = recover fn(d).slice(0, Size()) end
    try
      bytes(6)? = (bytes(6)? and 0x0f) or (ver << 4)
      bytes(8)? = (bytes(8)? and 0x3f) or 0x80
    end
    consume bytes

  fun _hex_string(data: Array[U8] val, width: USize = 0): String =>
    var u: U64 = 0
    let shift = ((data.size() * 8) - 8).u64()
    for (i, v) in data.pairs() do
      u = u or (v.u64() << (shift - (i.u64() * 8)))
    end
    Format.int[U64](u, FormatHexSmallBare where width = width, fill = '0')

primitive Size
  fun apply(): USize => 16

primitive Nil
  """
  The empty UUID, consisting solely of zeros.
  """
  fun apply(): UUID =>
    let z = recover Array[U8].init(0, Size()) end
    _FromArray(consume z)

type Namespace is (DNS | URL | OID | X500)
  """
  Well-known namespace UUIDs.
  """

primitive DNS
  """
  The DNS namespace.
  """
  fun apply(): UUID =>
    _FromArray([107; 167; 184; 16
                157; 173
                 17; 209
                128; 180
                  0; 192; 79; 212; 48; 200])

primitive URL
  """
  The URL namespace.
  """
  fun apply(): UUID =>
    _FromArray([107; 167; 184; 17
                157; 173
                 17; 209
                128; 180
                  0; 192; 79; 212; 48; 200])

primitive OID
  """
  The OID namespace.
  """
  fun apply(): UUID =>
    _FromArray([107; 167; 184; 18
                157; 173
                 17; 209
                128; 180
                  0; 192; 79; 212; 48; 200])

primitive X500
  """
  The X500 namespace.
  """
  fun apply(): UUID =>
    _FromArray([107; 167; 184; 20
                157; 173
                 17; 209
                128; 180
                  0; 192;  79; 212; 48; 200])

primitive _FromArray
  fun apply(a: Array[U8] val): UUID =>
    try
      UUID.from_array(a)?
    else
      // not reached
      Nil()
    end

type Version is U8

type Variant is (RFC4122 | Reserved | Microsoft | Future)
  """
  The variant determines how the remaining fields of the UUID are interpreted.
  """

primitive RFC4122
  """
  UUIDs as specified by RFC 4122.
  """
  fun string(): String iso^ => "RFC4122".clone()

primitive Reserved
  """
  Reserved, NCS backward compatibility.
  """
  fun string(): String iso^ => "Reserved".clone()

primitive Microsoft
  """
  Reserved, Microsoft Corporation backward compatibility.
  """
  fun string(): String iso^ => "Microsoft".clone()

primitive Future
  """
  Reserved for future definition.
  """
  fun string(): String iso^ => "Future".clone()

primitive Parse
  """
  Parse a string representation of an UUID. The following representations
  are supported:

  * `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (standard form).
  * `urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (urn-prefixed).
  * `{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}` (Microsoft encoding).
  * `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` (raw hex encoding).

  Returns `ParseError` if an invalid string representation is given.
  """
  fun apply(s: String): (UUID | ParseError) =>
    let size = s.size()
    try
      let t =
        match size
        // xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        | 36 => s
        // urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        | 45 if s.trim(0, 9).lower() == "urn:uuid:" => s.trim(9)
        | 45 => return InvalidPrefix
        // {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
        | 38 if (s(0)? == '{') and (s(37)? == '}') => s.trim(1, 37)
        // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        | 32 =>
          let range = Range(0, Size())
          let iter = Iter[USize](range).map[(USize, USize)]({(i) => (i, i*2)})
          return _make_bytes(s, iter)?
        else
          return InvalidLength
        end
      // Must be xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx now
      if (t(8)?  != '-') or
         (t(13)? != '-') or
         (t(18)? != '-') or
         (t(23)? != '-') then
        return InvalidFormat
      end
      let positions: Array[USize] =
        [ 0; 2; 4; 6; 9; 11; 14; 16; 19; 21; 24; 26; 28; 30; 32; 34 ]
      _make_bytes(t, positions.pairs())?
    else
      InvalidFormat
    end

  fun _make_bytes(s: String, iter: Iterator[(USize, USize)]): UUID ? =>
    let bytes = recover Array[U8](Size()) end
    for (i, j) in iter do
      let b1 = s(j)?
      let b2 = s(j + 1)?
      let byte = _chars_to_byte(b1, b2)?
      bytes.push(byte)
    end
    UUID.from_array(consume bytes)?

  fun _chars_to_byte(x1: U8, x2: U8): U8 ? =>
    let b1 = _byte(x1)?
    let b2 = _byte(x2)?
    (b1 << 4) or b2

  fun _byte(x: U8): U8 ? =>
    if (x >= '0') and (x <= '9') then return x - '0' end
    if (x >= 'A') and (x <= 'F') then return (x + 10) - 'A' end
    if (x >= 'a') and (x <= 'f') then return (x + 10) - 'a' end
    error

type ParseError is (InvalidPrefix | InvalidFormat | InvalidLength)
  """
  Possible errors from UUID parsing attempts.
  """

primitive InvalidPrefix
  """
  The UUID string has a prefix which is not `urn:uuid:`
  """

primitive InvalidFormat
  """
  An UUID string in standard form doesn't have the dash separators
  in the expected places.
  """

primitive InvalidLength
  """
  The UUID string has the wrong length.
  """
