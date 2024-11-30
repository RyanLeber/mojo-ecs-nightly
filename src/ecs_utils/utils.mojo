
from collections import Dict, InlineList, InlineArray, Set
from random import random_si64
from memory import UnsafePointer

# """Represents an 64-bit signed scalar integer."""
alias Component = Entity
alias ArchetypeId = Int

# alias ArchetypeRecord = Int
# """Index to a ComponentList (column) in an Archetypes component matrix"""


# alias EntityType = SmallSIMDVector[DType.int64]
alias EntityType = TypeVector[32]
"""The total set of component ids an archetype represents"""
alias ArchetypeSet = SmallSIMDVector[DType.int64]


@value
struct ArchetypeMap:
    """Used to lookup components in archetypes.

        Keys: Archetype_type
        Values: ArchetypeRecord
    """
    var data: Dict[ArchetypeId, ArchetypeRecord]

    fn __init__(inout self):
        self.data = Dict[ArchetypeId, ArchetypeRecord]()

    fn __getitem__(self, archetype_id: Int) raises -> ArchetypeRecord:
        return self.data[archetype_id]

    fn __setitem__(inout self, archetype_id: Int, archetype_record: ArchetypeRecord):
        self.data[archetype_id] = archetype_record

    fn pop(inout self, archetype_id: Int) raises -> ArchetypeRecord:
        return self.data.pop(archetype_id)

    fn __contains__(self, archetype_id: Int) -> Bool:
        return archetype_id in self.data


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
        # print(type.data)
        self.type = type
        # print(self.type.data)
        self.id = hash(type)
        self.components = List[Column]()
        self.edges = Dict[Component, ArchetypeEdge]()

    fn __init__(inout self, *components: Component) raises:
        self.type = EntityType()
        self.components = List[Column]()
        self.edges = Dict[Component, ArchetypeEdge]()

        for i in range(len(components)):
            self.type.add(components[i])

        self.id = hash(self.type)

    fn get_type(inout self) -> EntityType:
        return self.type

    fn add_entity[*Ts: CollectionElement](inout self, *component_values: *Ts) raises -> Int:
        @parameter
        for i in range(len(VariadicList(Ts))):
            self.components[i].append(component_values[i])

        # var row = len(self.components[0])
        return len(self.components[0]) - 1

    fn remove_entity(inout self, row: Int) -> Column:
        return self.components.pop(row)

@value
@register_passable
struct EntityRecord:
    """Enables us to retrive the value for a specific component.

    Attributes:

        var archetype (UnsafePointer[Archetype]): A pointer to an entities archetype
        var row (Int): Indexs into `archetype.components[row] -> Column` to retrieves the entities component values.
    """
    var archetype: UnsafePointer[Archetype]
    var row: Int
        

@value
@register_passable
struct ArchetypeEdge:
    var add: UnsafePointer[Archetype]
    var remove: UnsafePointer[Archetype]

    fn __init__[__: None](inout self):
        self.add = UnsafePointer[Archetype]()
        self.remove = UnsafePointer[Archetype]()

    # fn __init__(inout self, ,add: UnsafePointer[Archetype]):
    #     self.add = add
    #     self.remove = UnsafePointer[Archetype]()

    # fn __init__(inout self, remove: UnsafePointer[Archetype]):
    #     self.add = UnsafePointer[Archetype]()
    #     self.remove = remove

    fn __init__(inout self, *, add: UnsafePointer[Archetype]= UnsafePointer[Archetype](), remove: UnsafePointer[Archetype]= UnsafePointer[Archetype]()):
        self.add = add
        self.remove = remove

    fn add_component(inout self, ptr: UnsafePointer[Archetype]):
        self.add = ptr

    fn remove_component(inout self, ptr: UnsafePointer[Archetype]):
        self.remove = ptr


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