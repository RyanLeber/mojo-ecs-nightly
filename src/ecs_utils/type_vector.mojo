
from testing import assert_true, assert_not_equal
from sys import sizeof, llvm_intrinsic
from bit import count_trailing_zeros

# @value
@register_passable
struct TypeVector[Capacity: Int](CollectionElement, Hashable, EqualityComparable):
    alias type = DType.uint64
    var data: SIMD[Self.type, Capacity]
    var size: Int

    @staticmethod
    fn default() -> Self:
        return Self(int(UInt32.MAX))

    # @staticmethod
    # fn default() -> TypeVector:
    #     return TypeVector()

    # @staticmethod
    # fn default_hash() -> UInt:
    #     return hash(TypeVector(int(UInt32.MAX))) // 2

    @always_inline("nodebug")
    fn __init__(inout self):
        self.data = SIMD[Self.type, Capacity]()
        self.size = 0

    @always_inline("nodebug")
    fn __init__(inout self, fill_value: Int):
        self.data = SIMD[Self.type, Capacity](fill_value)
        self.size = Capacity

    @always_inline("nodebug")
    fn __init__(inout self, *elems: Scalar[Self.type]):
        self.data = SIMD[Self.type, Capacity]()

        for i in range(len(elems)):
            self.data[i] = elems[i]
        self.size = len(elems)
        self._sort()

    fn __copyinit__(inout self, other: Self):
        self.data = other.data
        self.size = other.size

    # ===-------------------------------------------------------------------===#
    # Instance Methods
    # ===-------------------------------------------------------------------===#

    @always_inline("nodebug")
    fn __getitem__(self, idx: Int) -> Entity:
        return Entity(self.data[idx])

    @always_inline("nodebug")
    fn __setitem__(inout self, idx: Int, entity: Entity):
        self.data[idx] = entity._get_value()
        self._sort()

    @always_inline("nodebug")
    fn __contains__(self, entity: Entity) -> Bool:
        return entity._get_value() in self.data

    @always_inline("nodebug")
    fn add(inout self, entity: Entity) raises:
        assert_true(entity not in self, "EnityType already contains this Id: " + str(entity.id))
        assert_not_equal(self.size, Self.Capacity, "EnityType is at capacity, Max Capacity = " + str(Self.Capacity))
        self[self.size] = entity
        self.size += 1
        self._sort()

    @always_inline("nodebug")
    fn pop(inout self: Self, idx: Int) raises -> Entity:
        assert_not_equal(self.size, Self.Capacity, "EnityType is at capacity, Max Capacity = " + str(Self.Capacity))
        var result = self.data[idx]
        self.data[idx] = 0
        self.size -= 1
        self._sort()
        return Entity(result)

    @always_inline("nodebug")
    fn pop(inout self: Self, entity: Entity) raises -> Entity:
        assert_not_equal(self.size, Self.Capacity, "EnityType is at capacity, Max Capacity = " + str(Self.Capacity))
        var idx = self.get_index(entity)
        var result = self.data[idx]
        self.data[idx] = 0
        self.size -= 1
        self._sort()
        return Entity(result)

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        return self.size

    @always_inline("nodebug")
    fn _sort(inout self):
        quick_sort[reverse=True](self.data)

    # ===-------------------------------------------------------------------===#
    # KeyElement Methods
    # ===-------------------------------------------------------------------===#

    @always_inline("nodebug")
    fn __hash__(self) -> UInt:
        return int(UInt32(hash(self.data)))

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
    fn get_index(self, entity: Entity) raises -> Int:
        constrained[Capacity >= 16, "Vector capacity must be greater than or equal to 16"]()
        alias slices = Capacity // 32

        if entity not in self:
            raise Error("Vector does not contain id:"+ str(entity.id))

        var value_mask = SIMD[Self.type, Capacity](entity._get_value())
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


