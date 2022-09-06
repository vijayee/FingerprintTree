use "collections"

primitive GetBit
  fun apply(data: Array[U8] box, index: USize = 0) : Bool ? =>
    if index >= (data.size() * 8) then
      error
    end
    let byte: USize = index / 8 // which byte in the array
    let byteIndex: USize = index % 8 // index of the bit in the bytes
    ((data(byte)? and (1 << (byteIndex.u8() -1))) != 0)

type Fingerprints is Map[Fingerprint val, Fingerprint val]

class FingerprintTree
  let _tree: Tree
  let _fpSize: USize
  new create(fpSize: USize, bucketSize: USize) =>
    _tree = Tree(bucketSize)
    _fpSize = fpSize

  new _duplicate (fpSize: USize, tree: Tree) =>
    _tree = tree
    _fpSize = fpSize

  fun ref add(key: Array[U8] val) : Status =>
    try
      _tree.add(Fingerprint(key, _fpSize)?)
    else
      Failed
    end

  fun ref remove(key: Array[U8] val): Status =>
    try
      _tree.remove(Fingerprint(key, _fpSize)?)
    else
      Failed
    end

  fun contains (key: Array[U8] val): Bool =>
    try
      _tree.contains(Fingerprint(key, _fpSize)?)
    else
      false
    end
  fun ref size (): USize =>
    _tree.size()

  fun copy() : FingerprintTree iso^ =>
    let tree = _tree.copy()
    recover FingerprintTree._duplicate(_fpSize, consume tree) end

class Tree
  var _bucket: (Fingerprints | None)
  var _left: (Tree | None)
  var _right: (Tree | None)
  var _bucketSize: USize

  new create(bucketSize: USize, bucket': (Fingerprints |  None) = None, left': (Tree | None) = None, right': (Tree | None) = None) =>
    match bucket'
      | None =>
        _bucket = Fingerprints(bucketSize + 1)
      else
        _bucket = bucket'
    end
    _left = left'
    _right = right'
    _bucketSize = bucketSize

  new _duplicate(bucketSize: USize, bucket': (Fingerprints |  None) = None, left': (Tree | None) = None, right': (Tree | None) = None) =>
    _bucket = bucket'
    _left = left'
    _right = right'
    _bucketSize = bucketSize

  fun size() : USize =>
    match _bucket
      | None => // this is an internal Node
        try
          let right : Tree box = _right as Tree box
          let left: Tree box = _left as Tree box
          (right.size() + left.size())
        else
          0
        end
      | let bucket': this->Fingerprints =>
        bucket'.size()
    end
  fun ref add(fp: Fingerprint val, index: USize = 0) : Status =>
    match _bucket
      | None => // this is an internal Node
        match (_right, _left)
          | (let right: Tree, let left : Tree) =>
            try
              if GetBit(fp.data, index + 1)? then
                right.add(fp, index + 1)
              else
                left.add(fp, index + 1)
              end
            else
              Failed
            end
          else
            Failed
        end
      | let bucket': Fingerprints =>
        let inserted: Bool = ((bucket'(fp) = fp) is None)
        if (bucket'.size() >= _bucketSize) then
          if index >= (fp.data.size() * 8) then
            if inserted then
              try bucket'.remove(fp)? end
            end
            return BucketFull
          else
            _split(index)
          end
        end
        Added
    end

  fun ref remove(fp: Fingerprint val, index: USize = 0): Status =>
    match _bucket
      | None => // this is an internal Node
        match (_right, _left)
          | (let right: Tree, let left : Tree) =>
            try
              if GetBit(fp.data, index + 1)? then
                right.remove(fp, index + 1)
              else
                left.remove(fp, index + 1)
              end
            else
              Failed
            end
        else
          Failed
        end
      | let bucket': Fingerprints =>
        try
          bucket'.remove(fp)?
          Removed
        else
          NotFound
        end
    end

  fun contains (fp: Fingerprint val,  index: USize = 0): Bool =>
    match _bucket
      | None => // this is an internal Node
        match (_right, _left)
        | (let right: this->Tree, let left : this->Tree) =>
            try
              if GetBit(fp.data, index + 1)? then
                right.contains(fp, index + 1)
              else
                left.contains(fp, index + 1)
              end
            else
              false
            end
        else
          false
        end
      | let bucket': this->Fingerprints =>
        bucket'.contains(fp)
    end

  fun ref _split(index: USize) =>
    match _bucket
    | let bucket': Fingerprints =>
        let left = Tree(_bucketSize)
        let right = Tree(_bucketSize)
        for fp in bucket'.values() do
          try
            if GetBit(fp.data, index + 1)? then
              right.add(fp, index + 1)
            else
              left.add(fp, index + 1)
            end
          end
        end
        _bucket = None
        _left = left
        _right = right
    end

  fun copy(): Tree iso^ =>
    match _bucket
      | None => // this is an internal Node
        match (_right, _left)
        | (let right: this->Tree, let left : this->Tree) =>
            let right' = right.copy()
            let left' = left.copy()
            recover Tree._duplicate(_bucketSize, None, consume left', consume right') end
        else
          recover Tree(_bucketSize) end
        end
      | let bucket': this->Fingerprints =>
        let newBucket: Fingerprints iso = recover Fingerprints(_bucketSize + 1) end
        for fp in bucket'.values() do
          newBucket(fp) = fp
        end
        recover Tree._duplicate(_bucketSize, consume newBucket) end
    end

  primitive BucketFull
  primitive Added
  primitive Duplicate
  primitive Failed
  primitive Removed
  primitive NotFound
  type Status is (BucketFull | Added | Duplicate | Failed  | Removed | NotFound)
