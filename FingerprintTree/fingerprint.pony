use "Murmur3"
use "collections"

class val Fingerprint
  let data : Array[U8] val

  new val create (data': Array[U8] val, size: USize) ? =>
    data = recover val Murmur32(data')?.slice(0, size) end

  fun hash (): USize =>
    var hash': USize = 0
    var first: Bool = true
    try
      for i in Range(0, data.size()) do
        if i >= 8 then
          break
        end
        if not first then
          hash' = hash' << 8
        end
        hash' = hash' or (data(i)?.usize() and 0xFF)
      end
    end
    hash'

  fun hash64 (): U64 =>
    var hash': U64 = 0
    var first: Bool = true
    try
      for i in Range(0, data.size()) do
        if i >= 8 then
          break
        end
        if not first then
          hash' = hash' << 8
        end
        hash' = hash' or (data(i)?.u64() and 0xFF)
      end
    end
    hash'

  fun box eq (that: box->Fingerprint) : Bool =>
    try
      if (data.size() != that.data.size()) then
        return false
      end
      for i in Range(0, data.size()) do
        if data(i)? != that.data(i)? then
          return false
        end
      end
      true
    else
      false
    end

  fun box ne (that: box->Fingerprint): Bool =>
    not eq(that)
