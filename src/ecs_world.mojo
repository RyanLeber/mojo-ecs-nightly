

from random import random_ui64, seed
from sys import sizeof
from collections import Optional

struct ECS[*component_types: CollectionElement]:
    var _cameras: List[Camera]
    var entity_id_range: IdRange
    var component_id_range: IdRange

    # Store all component types and their ids for component mapping
    var component_manager: ComponentManager[*component_types]
    # Stores all archetypes
    var archetype_container: List[Archetype]
    # Find an archetype by it's id, id=hash(archetype.type)
    var archetype_index: Dict[UInt, ArchetypeIdx]
    # Find an Entities archetype
    var entity_index: Dict[Entity, EntityRecord]
    # Find the archetypes with a Component
    var component_index: Dict[Component, ArchetypeMap]


    #MARK: __init__
    fn __init__(out self, renderer: Renderer) raises:
        self._cameras = List[Camera](capacity=100)
        self._cameras.append(Camera(renderer, g2.Multivector(1, g2.Vector(800, 500)), g2.Vector(800, 500), DRect[DType.float32](0, 0, 1, 1)))
        self.entity_id_range = IdRange(1000, 2000)
        self.component_id_range = IdRange(0, 256)

        self.component_manager = ComponentManager[*component_types]()
        self.archetype_container = List[Archetype]()
        self.archetype_index = Dict[UInt, ArchetypeIdx]()
        self.entity_index = Dict[Entity, EntityRecord]()
        self.component_index = Dict[Component, ArchetypeMap]()
        # create the default archetype
        self._create_archetype(EntityType.default())


    fn __moveinit__(out self, owned other: Self):
        self._cameras = other._cameras^

        self.archetype_container = other.archetype_container^
        self.archetype_index = other.archetype_index^
        self.entity_index = other.entity_index^
        self.component_index = other.component_index^

        self.component_manager = ComponentManager[*other.component_types]()

        self.entity_id_range = other.entity_id_range
        self.component_id_range = other.component_id_range


    #MARK: query_components
    fn query_components(self, *components: Component) raises -> Dict[Int, ArchetypeQuery]:
        alias ColumnType = SmallSIMDVector[DType.int32, sorted=False]
        var archetype_queries = Dict[Int, ArchetypeQuery]()
        var archetype_indices = List[Int]()

        # Get all archetype ids for each queried component and add them to a list
        for component in components:
            var arch_map = self.component_index[component]
            for item in arch_map.data.items():
                var idx = self.archetype_index[item[].key]
                archetype_indices.append(idx)

        # Find each archetype by their id
        for idx in archetype_indices:
            var archetype = Pointer.address_of(self.archetype_container[idx[]])
            var has_components = True
            var component_columns = ColumnType()

            # Check if the archetype has all queried components
            for component in components:
                var type = archetype[].type
                # If archetype has component, add that components column to component_columns
                if component in type:
                    component_columns.add(type.get_index(component))
                elif component not in type:
                    has_components = False
                    break
            
            # Archetype has all queried components, add the archetype to results
            if has_components == True:
                if idx[] not in archetype_queries:
                    archetype_queries[idx[]] = ArchetypeQuery(UnsafePointer.address_of(archetype[]), component_columns)

        # return a Dict[key: arch_idx, value: ArchetypeQuery[archetype: UnsafePointer, columns: ColumnsVector]]
        return archetype_queries


    # #MARK: get_component
    # fn get_component[T: CollectionElement](ref [_] self, entity: Entity, component: Component) raises -> ref [self] T:
    #     var record = self.entity_index[entity]
    #     var archetype = UnsafePointer.address_of(self.archetype_container[record.archetype_idx])
    #     # Check if archetype has component
    #     var archetypes = self.component_index[component]
    #     # if archetype[].id not in archetypes:
    #     #     return
        
    #     var archetype_record = archetypes[archetype[].id]
    #     return archetype[].components[archetype_record.column].get[T](record.row)

    # #MARK: get_component
    # fn get_component[T: CollectionElement](ref self, entity: Entity, component: Component) raises -> Optional[UnsafePointer[T, alignment=1]]:
    #     var record = self.entity_index[entity]
    #     var archetype = UnsafePointer.address_of(self.archetype_container[record.archetype_idx])
    #     # Check if archetype has component
    #     var archetypes = self.component_index[component]
    #     if archetype[].id not in archetypes:
    #         return None
        
    #     var archetype_record = archetypes[archetype[].id]
    #     return UnsafePointer.address_of(archetype[].components[archetype_record.column].get[T](record.row))

    #MARK: get_component
    fn get_component[T: CollectionElement](ref self, entity: Entity, component: Component
    ) raises -> Optional[Pointer[T, __origin_of(self.archetype_container[0].components[0].get[T](0))]]:
    # ) raises -> Optional[__type_of(__get_mvalue_as_litref(self.archetype_container[0].components[0].get[T](0)))]:
        var record = self.entity_index[entity]
        var archetype = Pointer.address_of(self.archetype_container[record.archetype_idx])
        # Check if archetype has component
        var archetypes = self.component_index[component]
        if archetype[].id not in archetypes:
            return None

        var archetype_record = archetypes[archetype[].id]
        return Pointer.address_of(archetype[].components[archetype_record.column].get[T](record.row))


    #MARK: set_component
    fn set_component[T: CollectionElement](mut self, entity: Entity, component: Component, value: T) raises:
        var record = self.entity_index[entity]
        var archetype = UnsafePointer.address_of(self.archetype_container[record.archetype_idx])
        # Check if archetype has component
        var archetypes = self.component_index[component]
        if archetype[].id not in archetypes:
            return 
        
        var archetype_record = archetypes[archetype[].id]
        archetype[].components[archetype_record.column].append[T](value)


    #MARK: _move_entity_add
    fn _move_entity_add[T: CollectionElement](mut self, 
            src_archetype: UnsafePointer[Archetype], 
            dst_archetype: UnsafePointer[Archetype], 
            row: Int
        ) raises -> Int:

        var src_type = src_archetype[].type
        var dst_type = dst_archetype[].type
        var dst_row = 0
        # for each component in src_archetype.components
        for i in range(len(src_type)):
            # get component row in dst corisponding to component row in src
            dst_row = dst_type.get_index(src_type[i])
            # pop component value from src and store in dst
            _ = dst_archetype[].components[dst_row].append(src_archetype[].components[i].pop[T](row))

        # add entry in dst for new component and return its column
        dst_archetype[].components[dst_row].append[T]()
        return len(dst_archetype[].components[dst_row]) - 1


    #MARK: add_component_to_entity
    fn add_component_to_entity[T: CollectionElement](mut self, entity: Entity, new_component: Component) raises:
        var record = self.entity_index[entity]
        var src_idx: Int = record.archetype_idx
        var dst_idx: Int
        var src_archetype = UnsafePointer.address_of(self.get_archetype(src_idx))
        var dst_archetype: UnsafePointer[Archetype]

        # Check if new_component has an existing edge
        # NOTE: If dst_archetype exists, we dont need to create new_type, because it already has that type
        if new_component in src_archetype[].edges:
            dst_idx = src_archetype[].edges[new_component].add
        else:
            var new_type = src_archetype[].type
            # Check if new_type is default_type
            if new_type == EntityType.default():
                new_type = EntityType()
            new_type.add(new_component)

            # If dst_archetype doesn't exist create it
            if hash(new_type) not in self.archetype_index:
                self._create_archetype(new_type)
            # Get the dst_archetype
            dst_idx = self.archetype_index[hash(new_type)]
            # Create a new edge from src_archetype to dst_archetype
            src_archetype[].edges[new_component] = ArchetypeEdge(add=dst_idx)

        dst_archetype = UnsafePointer.address_of(self.get_archetype(dst_idx))

        # If new_component edge doesnt exists in dst_archetype
        if new_component not in dst_archetype[].edges:
            # Create new edge from dst_archetype to src_archetype
            dst_archetype[].edges[new_component] = ArchetypeEdge(remove=src_idx)
        else: 
            # Update edge for new_component in dst_archetype
            dst_archetype[].edges[new_component].remove_component(src_idx)

        # Move entity from src to dst, and return entities new row in dst_archetype
        var row = self._move_entity_add[T](src_archetype, dst_archetype, record.row)
        # update entities record
        self.entity_index[entity] = EntityRecord(dst_idx, row)

        # get the column for new_component in dst_archetype
        var column = dst_archetype[].type.get_index(new_component)
        # Store column in new_component's Archetype map
        self.component_index[new_component][dst_idx] = ArchetypeRecord(column)


    #MARK: _move_entity_remove
    fn _move_entity_remove[T: CollectionElement](mut self, 
            src_archetype: UnsafePointer[Archetype], 
            dst_archetype: UnsafePointer[Archetype], 
            row: Int, del_component: Component
        ) raises -> Int:

        var src_type = src_archetype[].type
        var dst_type = dst_archetype[].type
        var dst_type_len = len(dst_type)
        # for each component in src_archetype.components
        for i in range(dst_type_len):
            # get component  in dst corisponding to component row in src
            var src_col = src_type.get_index(dst_type[i])
            # pop component value from src and store in dst
            dst_archetype[].components[i].append(src_archetype[].components[src_col].pop[T](row))

        _ = src_archetype[].components[src_type.get_index(del_component)].pop[T](row)
        # add entry in dst for new component and return its column
        return dst_type_len - 1


    #MARK: remove_component_from_entity
    fn remove_component_from_entity[T: CollectionElement](mut self, entity: Entity, del_component: Component) raises:
        # say we have an entity with archetype [Position, Velocity], and we want to add Health to it.
        var record = self.entity_index[entity]
        var src_idx: Int = record.archetype_idx
        var dst_idx: Int
        var src_archetype = UnsafePointer.address_of(self.get_archetype(src_idx))
        var dst_archetype: UnsafePointer[Archetype]


        # check if new_component has an existing edge
        # NOTE: if dst_archetype exists, we dont need to create new_type, because it already has that type
        if del_component in src_archetype[].edges:
            dst_idx = src_archetype[].edges[del_component].remove
        else:
            # find (or create) archetype [Position, Velocity, Health].
            var new_type = src_archetype[].type
            _ = new_type.pop(del_component)
            # if dst_archetype doesn't exist create it
            if hash(new_type) not in self.archetype_index:
                self._create_archetype(new_type)
            # get dst_archetype idx
            dst_idx = self.archetype_index[hash(new_type)]
            # create new edge for src_archetype going to dst_archetype
            src_archetype[].edges[del_component] = ArchetypeEdge(remove=dst_idx)

        dst_archetype = UnsafePointer.address_of(self.get_archetype(dst_idx))
        # if new_component edge doesnt exists in dst_archetype
        if del_component not in dst_archetype[].edges:
            # create new edge for dst_archetype going to src_archetype
            dst_archetype[].edges[del_component] = ArchetypeEdge(add=src_idx)
        else: 
            # update edge for new_component in dst_archetype
            dst_archetype[].edges[del_component].add_component(src_idx)

        # move entity from src to dst, and return entities new row in dst_archetype
        var row = self._move_entity_remove[T](src_archetype, dst_archetype, record.row, del_component)
        # update entities record
        self.entity_index[entity] = EntityRecord(dst_idx, row)

        # # remove the ArchetypeRecord (column) for dst_arch in del_component's Archetype map
        # _ = self.component_index[del_component].pop(dst_archetype[].id)


    #MARK: add_entity
    fn add_entity[*Ts: CollectionElement](mut self, *components: *Ts) raises -> Entity:
        # Generate a new entity_id
        var entity: Entity = self._generate_entity_id()
        # Generate an empty entity_type
        var new_type = EntityType()

        # For each component that is being added to the entity
        @parameter
        for i in range(len(VariadicList(Ts))):
            # Get component_id from component_manager
            var component = Component(self.component_manager.get_id[Ts[i]]())
            # Check if it has already been registered, register it if not
            if component == Component():
                component = self.generate_component_id[Ts[i]]()
            # Add the component the the entity_type
            new_type.add(component)
        
        # If archetype with new_type not in archetype_index create archetype
        if hash(new_type) not in self.archetype_index:
            self._create_archetype(new_type)

        # return the archetypes idx in archetype_container
        var idx = self.archetype_index[hash(new_type)]
        var archetype_id = self.archetype_container[idx].id
        
        var row: Int = 0
        @parameter
        for i in range(len(VariadicList(Ts))):
            if new_type[i] not in self.component_index:
                self.component_index[new_type[i]] = ArchetypeMap()
            self.component_index[new_type[i]][archetype_id] = i
            # Get component_id from component_manager
            var component = Component(self.component_manager.get_id[Ts[i]]())
            col = new_type.get_index(component)
            row = self.archetype_container[idx]._add_entity(col, components[i])

        self.entity_index[entity] = EntityRecord(idx, row)

        return entity

    #MARK: add_entity
    fn add_entity[T: CollectionElement](mut self, component_value: T) raises -> Entity:
        # Generate a new entity_id
        var entity: Entity = self._generate_entity_id()
        # Generate an empty entity_type
        var new_type = EntityType()

        # Get component_id from component_manager
        var component = Component(self.component_manager.get_id[T]())
        # Check if it has already been registered, register it if not
        if component == Component():
            component = self.generate_component_id[T]()
        # Add the component the the entity_type
        new_type.add(component)
        
        # If archetype with new_type not in archetype_index create archetype
        if hash(new_type) not in self.archetype_index:
            self._create_archetype(new_type)

        # return the archetypes idx in archetype_container
        var idx = self.archetype_index[hash(new_type)]
        var archetype_id = self.archetype_container[idx].id

        if component not in self.component_index:
            self.component_index[component] = ArchetypeMap()
        self.component_index[component][archetype_id] = 0
        col = new_type.get_index(component)
        var row = self.archetype_container[idx]._add_entity(col, component_value)

        self.entity_index[entity] = EntityRecord(idx, row)

        return entity


    #MARK: create_component_id
    fn generate_component_id[T: CollectionElement](mut self) -> Entity:
        var id = self._generate_entity_id()
        var component = Entity()
        if self.component_manager.register_component[T](id):
            component.set_id(id)
        return component

    #MARK: _generate_entity_id
    fn _generate_entity_id(self) -> UInt32:
        seed()
        var r = self.entity_id_range
        var id = random_ui64(r[0].cast[DType.uint64](), r[1].cast[DType.uint64]()).cast[DType.uint32]()

        while id in self.entity_index or id in self.component_index:
            id = random_ui64(r[0].cast[DType.uint64](), r[1].cast[DType.uint64]()).cast[DType.uint32]()

        return id

    #MARK: _create_archetype
    fn _create_archetype(mut self, existing_type: EntityType, new_component: Component) raises:
        var new_type = existing_type
        new_type.add(new_component)
        # get the index that the new arch will be stored at in arch_container
        var index = len(self.archetype_container)
        # add new archetype to archetype_container
        self.archetype_container.append(Archetype(new_type))
        # add arch idx into arch_container to archetype_index
        self.archetype_index[hash(new_type)] = index

    fn _create_archetype(mut self, new_type: EntityType) raises:
        # get the index that the new arch will be stored at in arch_container
        var index = len(self.archetype_container)
        # add new archetype to archetype_container
        self.archetype_container.append(Archetype(new_type))
        # add arch idx into arch_container to archetype_index
        self.archetype_index[hash(new_type)] = index

    # MARK: get_archetype
    fn get_archetype[T: Indexer](mut self, idx: T) -> ref [self.archetype_container] Archetype:
        return self.archetype_container[idx]

    fn get_archetype(mut self, entity_type: EntityType) raises -> ref [self.archetype_container] Archetype:
        var index = self.archetype_index[hash(entity_type)]
        return self.archetype_container[index]

    #MARK: get_component_id
    fn get_component_id[T: CollectionElement](self) -> Component:
        return self.component_manager.get_id[T]()

    fn set_entity_flag(mut self, mut entity: Entity, flag: UInt8) raises:
        var record = self.entity_index.pop(entity)
        entity.set_flag(flag)
        self.entity_index[entity] = record
