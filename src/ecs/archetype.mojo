


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

    fn __init__(out self, type: EntityType) raises:
        self.type = type
        self.id = hash(type)
        self.components = List[Column]()
        self.edges = Dict[Component, ArchetypeEdge]()

        for _ in range(len(type)):
            self.components.append(Column())

    fn __init__(out self, *components: Component) raises:
        self.type = EntityType()
        self.components = List[Column]()
        self.edges = Dict[Component, ArchetypeEdge]()

        for i in range(len(components)):
            self.type.add(components[i])
            self.components.append(Column())

        self.id = hash(self.type)

    fn get_type(mut self) -> EntityType:
        return self.type

    fn add_entity[*Ts: CollectionElement](mut self, columns: ColumnsVector, *component_values: *Ts) raises -> Int:
        alias count = len(VariadicList(Ts))
        @parameter
        if count == 0:
            return -1

        @parameter
        for i in range(count):
            self.components[columns[i]].append(component_values[i])
        # returns the the enititys row in component matrix
        return len(self.components[0]) - 1

    fn _add_entity[T: CollectionElement](mut self, column: Int, component_value: T) raises -> Int:
        self.components[column].append(component_value)
        # returns the the enititys row in component matrix
        return len(self.components[column]) - 1

    fn remove_entity(mut self, row: Int) -> Column:
        return self.components.pop(row)

    fn get_column[is_mutable: Bool, //, origin: Origin[is_mutable]](ref [origin] self, column: Int) -> Pointer[Column, __origin_of(self.components)]:
        return Pointer.address_of(self.components[column])
