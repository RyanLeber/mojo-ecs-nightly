
from memory import UnsafePointer

alias IdRange = SIMD[DType.uint32, 2]

alias Component = Entity
alias ArchetypeId = UInt
alias ArchetypeIdx = Int

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

    Attributes:

        Dict[ArchetypeId, ArchetypeRecord]
    """
    var data: Dict[ArchetypeId, ArchetypeRecord]

    fn __init__(out self):
        self.data = Dict[ArchetypeId, ArchetypeRecord]()

    fn __getitem__(self, id: UInt) raises -> ArchetypeRecord:
        return self.data[id]

    fn __setitem__(mut self, id: UInt, archetype_record: ArchetypeRecord):
        self.data[id] = archetype_record

    fn pop(mut self, id: Int) raises -> ArchetypeRecord:
        return self.data.pop(id)

    fn __contains__(self, id: Int) -> Bool:
        return id in self.data


@value
@register_passable
struct EntityRecord:
    """Enables us to retrive the value for a specific component.

    Attributes:

        var archetype (Int): The index to an entities archetype
        var row (Int): The row in an Archetypes component matrix that the entities component values are located.
    """
    var archetype_idx: Int 
    var row: Int
        

@value
@register_passable
struct ArchetypeEdge:
    var add: ArchetypeIdx
    var remove: ArchetypeIdx

    fn __init__[__: None](out self):
        self.add = -1
        self.remove = -1

    fn __init__(out self, *, add: Int= -1, remove: Int= -1):
        self.add = add
        self.remove = remove

    fn add_component(mut self, idx: Int):
        self.add = idx

    fn remove_component(mut self, idx: Int):
        self.remove = idx


@value
@register_passable("trivial")
struct ArchetypeRecord:
    """Index to a ComponentList (column) in an Archetypes component matrix.

    Attributes: 

        var column (Int)
    """
    var column: Int