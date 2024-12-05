
from sys import sizeof, simdwidthof, bitwidthof, alignof
from bit import bit_reverse


@register_passable("trivial")
struct Entity(CollectionElementNew, KeyElement):
    var value: SIMD[DType.uint64, 1]

    fn __init__(out self):
        self.value = 0
        self._set_generation((self.generation + 1))

    @implicit
    fn __init__(out self, id: UInt32):
        self.value = 0
        self.set_id(id)
        self._set_generation((self.generation + 1))

    fn __init__(mut self, data: UInt64):
        self.value = data

    fn __init__(mut self, other: Entity):
        self.value = other.value

    @staticmethod
    fn _cast[type: DType](value: Scalar[type]) -> UInt64:
        return value.cast[DType.uint64]()


    fn set_id(mut self, id: UInt32):
        self.value = (self.relation << 32 | self._cast(id))

    fn set_relation(mut self, relation: UInt32):
        self.value = (self._cast(relation) << 32 | self.id)

    fn set_flag(mut self, flag: UInt8):
        self.value = (self._cast(flag) << 60) | (self.generation << 32) | self.id

    fn _set_generation(mut self, generation: UInt16):
        self.value = (self.flag << 60) | (self._cast(generation) << 32) | self.id

    fn get_id(self) -> UInt32:
        return (self.value & ((1 << 32) - 1)).cast[DType.uint32]()

    fn get_flag(self) -> UInt8:
        return ((self.value >> 60) & ((1 << 4) - 1)).cast[DType.uint8]() 

    fn get_relation(self) -> UInt32:
        return ((self.value >> 32) & ((1 << 28) - 1)).cast[DType.uint32]()

    fn _get_generation(self) -> UInt16:
        return ((self.value >> 32) & ((1 << 28) - 1)).cast[DType.uint16]()

    fn _get_value(self) -> UInt:
        return int(self.value)


    fn __getattr__[name: StringLiteral](self) -> UInt:
        constrained[name == "flag" or name == "id" or name == "relation" or name == "generation", "Cannot access Enitity with field: "]()
        @parameter
        if name == "flag":
            return int(((self.value >> 60) & ((1 << 4) - 1)))
        elif name == "generation":
            return int(((self.value >> 32) & ((1 << 28) - 1)))
        elif name == "relation":
            return int(((self.value >> 32) & ((1 << 28) - 1)))
        elif name == "id":
            return int((self.value & ((1 << 32) - 1)))
        else: 
            return 0

    fn __hash__(self) -> UInt:
        return hash(self.value)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value
        