use @ponyint_hash_block[USize](ptr: Pointer[None] tag, size: USize)
use @ponyint_hash_block64[U64](ptr: Pointer[None] tag, size: USize)
use "Murmur3"
use "collections"

class val Fingerprint
  let data : Array[U8] val

  new val create (data': Array[U8] val, size: USize) ? =>
    data = recover val Murmur32(data')?.slice(0, size) end

  fun hash(): USize =>
    @ponyint_hash_block(data.cpointer(), data.size())

  fun hash64(): U64 =>
     @ponyint_hash_block64(data.cpointer(), data.size())

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
