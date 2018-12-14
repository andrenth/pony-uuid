use "collections"
use "crypto"
use "format"
use "itertools"
use "random"
use "time"

class val UUID is Equatable[UUID]
  let _bytes: Array[U8] val

  new val v3(namespace: Namespace, data: Array[U8] val) =>
    _bytes = _hash(MD5, namespace, data, 3)

  new val v4(rand: (Random iso | None) = None) =>
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
    _bytes = _hash(SHA1, namespace, data, 5)

  new val from_array(bytes: Array[U8] val) ? =>
    if bytes.size() != Size() then
      error
    end
    _bytes = bytes

  fun tag _hash(hash: HashFn val, namespace: Namespace, data: Array[U8] val,
                ver: U8): Array[U8] val =>
    let d = recover val
      let d = Array[U8](Size() + data.size())
      d.append(namespace().array())
      d.append(data)
      d
    end
    let bytes = recover hash(d).slice(0, Size()) end
    try
      bytes(6)? = (bytes(6)? and 0x0f) or (ver << 4)
      bytes(8)? = (bytes(8)? and 0x3f) or 0x80
    end
    consume bytes

  fun urn(): String iso^ =>
    let s = recover String(36 + 9) end
    s.insert_in_place(0, "urn:uuid:")
    s.insert_in_place(9, string())
    s

  fun variant(): Variant =>
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
    try _bytes(6)? >> 4 else /* not reached */ 0 end

  fun array(): Array[U8] val =>
    _bytes

  fun string(): String iso^ =>
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
  fun apply(): UUID =>
    let z = recover Array[U8].init(0, Size()) end
    _FromArray(consume z)

type Namespace is (DNS | URL | OID | X500)

primitive DNS
  fun apply(): UUID =>
    _FromArray([107; 167; 184; 16
                157; 173
                 17; 209
                128; 180
                  0; 192; 79; 212; 48; 200])

primitive URL
  fun apply(): UUID =>
    _FromArray([107; 167; 184; 17
                157; 173
                 17; 209
                128; 180
                  0; 192; 79; 212; 48; 200])

primitive OID
  fun apply(): UUID =>
    _FromArray([107; 167; 184; 18
                157; 173
                 17; 209
                128; 180
                  0; 192; 79; 212; 48; 200])

primitive X500
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

primitive Invalid
  fun string(): String iso^ => "Invalid".clone()

primitive RFC4122
  fun string(): String iso^ => "RFC4122".clone()

primitive Reserved
  fun string(): String iso^ => "Reserved".clone()

primitive Microsoft
  fun string(): String iso^ => "Microsoft".clone()

primitive Future
  fun string(): String iso^ => "Future".clone()

type Variant is (Invalid | RFC4122 | Reserved | Microsoft | Future)

type ParseError is (InvalidPrefix | InvalidFormat | InvalidLength)

primitive InvalidPrefix
primitive InvalidFormat
primitive InvalidLength

primitive Parse
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
        | 38 => return InvalidFormat
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
