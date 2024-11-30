
from sys import sizeof
from memory import UnsafePointer, memset_zero


fn _move_pointee_into_many_elements[T: CollectionElement](dest: UnsafePointer[T], src: UnsafePointer[T], size: Int):
    for i in range(size):
        (src + i).move_pointee_into(dest + i)


struct Column:
    var data: UnsafePointer[Int64]
    var capacity: Int
    var element_count: Int
    var element_size: Int

    fn __init__(inout self):
        self.data = UnsafePointer[Int64]()
        self.element_count = 0
        self.capacity = 0
        self.element_size = 0

    fn __init__(inout self, capacity: Int):
        self.data = UnsafePointer[Int64]()
        self.element_count = 0
        self.capacity = capacity
        self.element_size = 0


    fn __moveinit__(inout self, owned existing: Self):
        self.data = existing.data
        self.capacity = existing.capacity
        self.element_size = existing.element_size
        self.element_count = existing.element_count

    fn __copyinit__(inout self, existing: Self):
        self = Column(capacity= existing.capacity)

        var size = existing.element_count * existing.element_size

        var new_data = existing.data.bitcast[UInt8]()
        var tmp_data = UnsafePointer[UInt8].alloc(size)
        for i in range(size):
            (tmp_data + i).init_pointee_copy(new_data[i])

        self.data = tmp_data.bitcast[Int64]()
        self.element_size = existing.element_size
        self.element_count = existing.element_count


    fn _realloc[T: CollectionElement](inout self, new_capacity: Int):
        var new_data = UnsafePointer[T].alloc(new_capacity)

        _move_pointee_into_many_elements(
            dest=new_data,
            src=self.data.bitcast[T](),
            size=self.element_count,
        )

        if self.data:
            self.data.free()
        self.data = new_data.bitcast[Int64]()
        self.capacity = new_capacity

    fn __len__(self) -> Int:
        return self.element_count

    fn append[T: CollectionElement](inout self, owned value: T) raises:
        if self.element_size == 0:
            self.element_size = sizeof[T]()
        
        elif self.element_size != sizeof[T]():
            # best option without having type Info
            raise Error("Size of T does not match existing size of T in Column.append[T]()")
        
        if self.element_count >= self.capacity:
            self._realloc[T](max(1, self.capacity * 2))

        var data_ptr = self.data.bitcast[T]()

        (data_ptr + self.element_count).init_pointee_move(value^)

        # self.data = data_ptr.bitcast[NoneType]()
        self.element_count += 1

    fn append[T: CollectionElement](inout self) raises:
        if self.element_size == 0:
            self.element_size = sizeof[T]()
        
        elif self.element_size != sizeof[T]():
            # best option without having type Info
            raise Error("Size of T does not match existing size of T in Column.append[T]()")
        
        if self.element_count >= self.capacity:
            self._realloc[T](max(1, self.capacity * 2))

        var data_ptr = self.data.bitcast[T]()

        memset_zero(data_ptr + self.element_count, 1)

        # self.data = data_ptr.bitcast[NoneType]()
        self.element_count += 1

    fn get[T: CollectionElement](inout self, idx: Int) raises -> ref [__origin_of(self)] T:
        var normalized_idx = idx
        if idx < 0:
            normalized_idx += len(self)

        if idx >= self.element_count or normalized_idx >= self.element_count:
            raise Error("Index:" + str(idx) +" is out of bounds.")

        if self.element_size != sizeof[T]():
            raise Error("Size of T does not match existing size of T in Column.append[T]()")

        return self.data.bitcast[T]()[idx]

    fn pop[T: CollectionElement](inout self, i: Int = -1) -> T:
        """Pops a value from the list at the given index.

        Args:
            i: The index of the value to pop.

        Returns:
            The popped value.
        """
        debug_assert(-len(self) <= i < len(self), "pop index out of range")

        var normalized_idx = i
        if i < 0:
            normalized_idx += len(self)

        var data_ptr = self.data.bitcast[T]()

        var ret_val = (data_ptr + normalized_idx).take_pointee()
        for j in range(normalized_idx + 1, self.element_count):
            (self.data + j).move_pointee_into(self.data + j - 1)
        self.element_count -= 1
        if self.element_count * 4 < self.capacity:
            if self.capacity > 1:
                self._realloc[T](self.capacity // 2)
        return ret_val^


    fn __del__(owned self):
        var data = self.data.bitcast[UInt8]()
        for i in range(self.element_count * self.element_size):
            (data + i).destroy_pointee()
        self.data.free()