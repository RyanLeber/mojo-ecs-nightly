
from collections import Dict, InlineList, InlineArray, Set
from random import random_si64
from memory import UnsafePointer
from sys import sizeof

# """Represents an 64-bit signed scalar integer."""
alias Component = Entity
alias ArchetypeId = UInt
alias ArchetypeIdx = Int

# alias ArchetypeRecord = Int
# """Index to a ComponentList (column) in an Archetypes component matrix"""


# alias EntityType = SmallSIMDVector[DType.int64]
alias EntityType = TypeVector[16]
"""The total set of component ids an archetype represents"""
alias ArchetypeSet = SmallSIMDVector[DType.int64]

alias ColumnsVector = SmallSIMDVector[DType.uint8, EntityType.capacity, False]

alias ArchetypeQueryMap = Dict[ArchetypeIdx, ArchetypeQuery]

@value
@register_passable
struct ArchetypeQuery(CollectionElement):
    var archetype: UnsafePointer[Archetype]  
    var columns: SmallSIMDVector[DType.int32, sorted=False]




@value
struct ArchetypeMap:
    """Used to lookup components in archetypes.

        Keys: Archetype_id
        Values: ArchetypeRecord
    """
    var data: Dict[ArchetypeId, ArchetypeRecord]

    fn __init__(inout self):
        self.data = Dict[ArchetypeId, ArchetypeRecord]()

    fn __getitem__(self, id: UInt) raises -> ArchetypeRecord:
        return self.data[id]

    fn __setitem__(inout self, id: UInt, archetype_record: ArchetypeRecord):
        self.data[id] = archetype_record

    fn pop(inout self, id: Int) raises -> ArchetypeRecord:
        return self.data.pop(id)

    fn __contains__(self, id: Int) -> Bool:
        return id in self.data


# Type used to store each unique component list only once
@value
struct Archetype:
    """Stores all entities that have the same components.

    Attributes:

        var id (Int): A unique integer identifier to an archetype
        var type (EntityType): The total Set of components an archetype represents
        var components (List[Column]): Stores one List corresponding to each component
        var edges (Dict[Component, ArchetypeEdge]): A Map between similar components
    """
    var id: UInt
    var type: EntityType
    var components: List[Column]
    var edges: Dict[Component, ArchetypeEdge]

    @staticmethod
    fn default() raises -> Self:
        return Self(EntityType.default())

    fn __init__(inout self, type: EntityType) raises:
        self.type = type
        self.id = hash(type)
        self.components = List[Column]()
        self.edges = Dict[Component, ArchetypeEdge]()

        for _ in range(len(type)):
            self.components.append(Column())

    fn __init__(inout self, *components: Component) raises:
        self.type = EntityType()
        self.components = List[Column]()
        self.edges = Dict[Component, ArchetypeEdge]()

        for i in range(len(components)):
            self.type.add(components[i])
            self.components.append(Column())

        self.id = hash(self.type)

    fn get_type(inout self) -> EntityType:
        return self.type

    fn add_entity[*Ts: CollectionElement](inout self, columns: ColumnsVector, *component_values: *Ts) raises -> Int:
        alias count = len(VariadicList(Ts))
        @parameter
        if count == 0:
            return -1

        @parameter
        for i in range(count):
            self.components[columns[i]].append(component_values[i])
        # returns the the enititys row in component matrix
        return len(self.components[0]) - 1

    fn _add_entity[T: CollectionElement](inout self, column: Int, component_value: T) raises -> Int:
        self.components[column].append(component_value)
        # returns the the enititys row in component matrix
        return len(self.components[column]) - 1

    fn remove_entity(inout self, row: Int) -> Column:
        return self.components.pop(row)

    fn get_column[is_mutable: Bool, //, origin: Origin[is_mutable]](ref [origin] self, column: Int) -> Pointer[Column, __origin_of(self.components)]:
        return Pointer.address_of(self.components[column])

@value
@register_passable
struct EntityRecord:
    """Enables us to retrive the value for a specific component.

    Attributes:

        var archetype (UnsafePointer[Archetype]): A pointer to an entities archetype
        var row (Int): Indexs into `archetype.components[row] -> Column` to retrieves the entities component values.
    """
    var archetype_idx: Int 
    var row: Int
        

@value
@register_passable
struct ArchetypeEdge:
    var add: ArchetypeIdx
    var remove: ArchetypeIdx

    fn __init__[__: None](inout self):
        self.add = -1
        self.remove = -1

    # fn __init__(inout self, ,add: UnsafePointer[Archetype]):
    #     self.add = add
    #     self.remove = UnsafePointer[Archetype]()

    # fn __init__(inout self, remove: UnsafePointer[Archetype]):
    #     self.add = UnsafePointer[Archetype]()
    #     self.remove = remove

    fn __init__(inout self, *, add: Int= -1, remove: Int= -1):
        self.add = add
        self.remove = remove

    fn add_component(inout self, idx: Int):
        self.add = idx

    fn remove_component(inout self, idx: Int):
        self.remove = idx



@value
@register_passable("trivial")
struct ArchetypeRecord:
    """Index to a ComponentList (column) in an Archetypes component matrix.
    
    Record in component index with component column for archetype.

    Column index for a components value in an archetypes component list.

    Archetype.components[ArchetypeRecord.column][EntityRecord.row] -> Value

    Attributes:

        var column (Int)
    """
    var column: Int