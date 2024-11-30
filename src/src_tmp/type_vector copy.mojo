
from testing import assert_true, assert_not_equal
from sys import sizeof, llvm_intrinsic
from bit import count_trailing_zeros

@value
@register_passable
# struct TypeVector[Capacity: Int= 32](CollectionElement, Hashable, EqualityComparable):
struct TypeVector[type: DType, Capacity: Int= 32](CollectionElement, Hashable, EqualityComparable):
    # alias _type = SIMD[DType.uint64, 32]
    # alias type = DType.uint64
    # var data: SIMD[Self.type, Capacity]
    var data: SIMD[type, Capacity]
    var size: Int

    @always_inline("nodebug")
    fn __init__(inout self):
        self.data = SIMD[type, Capacity]()
        self.size = 0

    @always_inline("nodebug")
    fn __init__(inout self, fill_value: Int):
        self.data = SIMD[type, Capacity](fill_value)
        self.size = Capacity

    @always_inline("nodebug")
    fn __init__(inout self, *elems: Scalar[type]):
        self.data = SIMD[type, Capacity]()

        for i in range(len(elems)):
            self.data[i] = elems[i]
        self.size = len(elems)
        self._sort()

    @always_inline("nodebug")
    fn __getitem__(self, idx: Int) -> Int:
        return int(self.data[idx])

    @always_inline("nodebug")
    fn __setitem__(inout self, idx: Int, val: Scalar[type]):
        self.data[idx] = val
        self._sort()

    @always_inline("nodebug")
    fn __contains__(self, val: Scalar[type]) -> Bool:
        return val in self.data

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        return self.size

    @always_inline("nodebug")
    fn _sort(inout self):
        quick_sort[reverse=True](self.data)

    @always_inline("nodebug")
    fn add(inout self, val: Int) raises:
        assert_true(val not in self, "EnityType already contains this Id: " + str(val))
        assert_not_equal(self.size, Self.Capacity, "EnityType is at capacity, Max Capacity = " + str(Self.Capacity))

        self.size += 1
        self[self.size - 1] = val
        self._sort()

    @always_inline("nodebug")
    fn pop(inout self, idx: Int) raises -> Scalar[type]:
        assert_not_equal(self.size, Self.Capacity, "EnityType is at capacity, Max Capacity = " + str(Self.Capacity))
        var result = self.data[idx]
        self.data[self.size - 1] = 0
        self.size -= 1
        self._sort()
        return int(result)

    @always_inline("nodebug")
    fn __hash__(self) -> UInt:
        return hash(self.data)

    @always_inline("nodebug")
    fn __eq__(self, other: Self) -> Bool:
        var mask = self.data == other.data
        if False in mask: return False
        return True

    @always_inline("nodebug")
    fn __ne__(self, other: Self) -> Bool:
        var mask = self.data != other.data
        if False in mask: return False
        return True

    @always_inline("nodebug")
    fn get_index(self, value: Int) raises -> Int:
        constrained[Capacity >= 16, "Vector capacity must be greater than or equal to 16"]()
        alias slices = Capacity // 32

        if value not in self:
            raise Error("Array does not contain value:"+ str(value))

        var value_mask = SIMD[type, Capacity](value)
        var cmp_mask = (self.data == value_mask).cast[DType.int8]()

        cmp_mask = cmp_mask << 7

        var scalar_mask: Int32 = 0

        @parameter
        if Capacity > 32:
            @parameter
            for i in range(0, Capacity, 32):
                tmp_mask = llvm_intrinsic["llvm.x86.avx2.pmovmskb", Int32, has_side_effect=False](cmp_mask.slice[32,offset=i]())
                if tmp_mask != 0:
                    scalar_mask = tmp_mask
                    break

        elif Capacity == 32:
            scalar_mask = llvm_intrinsic["llvm.x86.avx2.pmovmskb", Int32, has_side_effect=False](cmp_mask)
        elif Capacity == 16:
            scalar_mask = llvm_intrinsic["llvm.x86.sse2.pmovmskb.128", Int32, has_side_effect=False](cmp_mask)

        return int(count_trailing_zeros(scalar_mask))


    # ===-------------------------------------------------------------------===#
    # Entity Methods
    # ===-------------------------------------------------------------------===#

    @always_inline("nodebug")
    fn __getitem__[__: None=None](self, idx: Int) -> Entity:
        return Entity(self.data[idx].cast[DType.uint64]())

    @always_inline("nodebug")
    fn __setitem__(inout self, idx: Int, entity: Entity):
        self.data[idx] = entity._get_value()
        self._sort()

    @always_inline("nodebug")
    fn __contains__(self, entity: Entity) -> Bool:
        return entity._get_value() in self.data

    @always_inline("nodebug")
    fn add(inout self, val: Entity) raises:
        assert_true(val not in self, "EnityType already contains this Id: " + str(val.id))
        assert_not_equal(self.size, Self.Capacity, "EnityType is at capacity, Max Capacity = " + str(Self.Capacity))

        self[self.size] = val._get_value()
        self.size += 1
        self._sort()

    @always_inline("nodebug")
    fn pop_Entity(inout self: Self, idx: Int) raises -> Entity:
        assert_not_equal(self.size, Self.Capacity, "EnityType is at capacity, Max Capacity = " + str(Self.Capacity))
        var result = self.data[idx]
        self.data[idx] = 0
        self.size -= 1
        self._sort()
        return Entity(result.cast[DType.uint64]())

    @always_inline("nodebug")
    fn pop[__: None=None](inout self: Self, idx: Int) raises -> Entity:
        assert_not_equal(self.size, Self.Capacity, "EnityType is at capacity, Max Capacity = " + str(Self.Capacity))
        var result = self.data[idx]
        self.data[idx] = 0
        self.size -= 1
        self._sort()
        return Entity(result.cast[DType.uint64]())
