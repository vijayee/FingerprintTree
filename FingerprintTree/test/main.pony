use "ponytest"
use "collections"
use ".."
use "time"
use "random"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)
  new make () =>
    None
  fun tag tests(test: PonyTest) =>
    test(_TestGetBit)
    test(_TestFingerprint)
    test(_TestTree)

primitive RandomBytes
  fun apply(size: USize): Array[U8] =>
    let now = Time.now()
    var gen = Rand(now._1.u64(), now._2.u64())
    var bytes: Array[U8] = Array[U8](size)
    for j in Range(0, size) do
      bytes.push(gen.u8())
    end
    bytes

class iso _TestGetBit is UnitTest
  fun name(): String => "Testing GetBit"
  fun apply(t: TestHelper) =>
    t.long_test(5000000)
    let arr: Array[U8] val = [8]
    try
      t.assert_false(GetBit(arr, 0)?)
      t.assert_false(GetBit(arr, 1)?)
      t.assert_false(GetBit(arr, 2)?)
      t.assert_false(GetBit(arr, 3)?)
      t.assert_true(GetBit(arr, 4)?)
      t.assert_false(GetBit(arr, 5)?)
      t.assert_false(GetBit(arr, 6)?)
      t.assert_false(GetBit(arr, 7)?)
    else
      t.fail("Error Looking Up Bit")
    end
    t.expect_action("failure")
    try
      GetBit(arr, 8)?
    else
      t.complete_action("failure")
    end
    t.complete(true)

class iso _TestFingerprint is UnitTest
  fun name(): String => "Testing Fingerprint"
  fun apply(t: TestHelper) =>
    try
      let arr1: Array[U8] val = [1;2;3]
      let arr2: Array[U8] val = [1;2;3]
      let arr3: Array[U8] val = [1;2;3;4]
      let fp1: Fingerprint = Fingerprint(arr1,1)?
      let fp2: Fingerprint = Fingerprint(arr2,1)?
      let fp3: Fingerprint = Fingerprint(arr3,1)?
      let bucket: Fingerprints = Fingerprints(3)
      t.log(fp1.hash().string())
      t.log(fp2.hash().string())
      t.log(fp3.hash().string())

      t.assert_true(fp1 == fp2)
      t.assert_true(fp1.hash() == fp2.hash())
      t.assert_true(fp1 != fp3)
      t.assert_true(fp1.hash() != fp3.hash())
      bucket(fp1) = fp1
      t.assert_true(bucket.contains(fp2))
      t.assert_true(bucket.contains(fp1))
      match (bucket(fp2) = fp2)
        | None => t.fail("Old Value not returned")
        | let fp': Fingerprint =>
          t.assert_true(fp' == fp1)
      end
      t.assert_true(bucket.contains(fp2))
      t.assert_false((bucket(fp2) = fp2) is None)
      t.assert_true((bucket(fp3) = fp3) is None)
    else
      t.fail("Fingerprint Error")
    end

class iso _TestTree is UnitTest
  fun name(): String => "Testing Tree"
  fun apply(t: TestHelper) =>
    let count: USize = 1000000
    let size: USize = 4
    let fixtures: Array[Array[U8] val] = Array[Array[U8] val](count)

    for i in Range(0, count) do
      fixtures.push(recover val RandomBytes(size) end)
    end

    let tree: FingerprintTree = FingerprintTree(1, 15)
    for key in fixtures.values() do
      match tree.add(key)
        | Added =>
          t.assert_true(tree.contains(key))
        | Failed =>
          t.log("Failed to insert")
          t.assert_false(tree.contains(key))
        | Duplicate =>
          t.log("This is a duplicate key ")
        | BucketFull =>
          t.log("The bucket is full")
      end
    end

    for key in fixtures.values() do
      match tree.remove(key)
        | Removed =>
          t.assert_false(tree.contains(key))
        | Failed =>
          t.log("Failed to remove")
          t.assert_true(tree.contains(key))
        | NotFound =>
          t.log("Item was not present")
      end
    end
