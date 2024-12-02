

from random import random_ui64, random_si64, seed
from collections import Optional
from memory import UnsafePointer
from sys import sizeof

alias background_clear = Color(12, 8, 6, 0)

alias Range = SIMD[DType.uint32, 2]

@value
@register_passable
struct ArchetypeQuery(CollectionElement):
    var archetype: UnsafePointer[Archetype]  
    var columns: SmallSIMDVector[DType.int32, sorted=False]



@value
@register_passable("trivial")
struct Position:
    var x: Float32
    var y: Float32

@value
@register_passable("trivial")
struct Width:
    var x: Float32
    var y: Float32

@value
@register_passable("trivial")
struct Velocity:
    var x: Float32
    var y: Float32


struct World[screen_width: Int, screen_height: Int, *component_types: CollectionElement]:
    var _cameras: List[Camera]

    var entity_id_range: Range
    var component_id_range: Range

    # Store all component types and their ids for component mapping
    var component_manager: ComponentManager[*component_types]

    # Find an archetype by its list of component ids
    # A Key, Value pair containing a list of component ids and 
    var archetype_container: List[Archetype]
    var archetype_index: Dict[UInt, ArchetypeIdx]
    # var archetype_index: Dict[SmallSIMDVector[DType.int64, 32], Archetype]

    # Find the archetype for an entity
    # A Key, Value pair containing the entity_id and its archetype
    var entity_index: Dict[Entity, EntityRecord]

    # Find the archetypes for a component
    # A Key, Value pair containing a component_id and a map containing the id's of all of the archetypes with that component
    var component_index: Dict[Component, ArchetypeMap]

    #MARK: __init__
    fn __init__(inout self, renderer: Renderer) raises:
        self._cameras = List[Camera](capacity=100)
        self._cameras.append(Camera(renderer, g2.Multivector(1, g2.Vector(800, 500)), g2.Vector(800, 500), DRect[DType.float32](0, 0, 1, 1)))

        self.archetype_container = List[Archetype]()
        self.archetype_index = Dict[UInt, ArchetypeIdx]()
        self.entity_index = Dict[Entity, EntityRecord]()
        self.component_index = Dict[Component, ArchetypeMap]()

        self.component_manager = ComponentManager[*component_types]()

        self.entity_id_range = Range(1000, 2000)
        self.component_id_range = Range(0, 256)

        # Seed the random number generator
        seed()

        self._create_archetype(EntityType.default())

    fn __moveinit__(inout self, owned other: Self):
        self._cameras = other._cameras^

        self.archetype_container = other.archetype_container^
        self.archetype_index = other.archetype_index^
        self.entity_index = other.entity_index^
        self.component_index = other.component_index^

        self.component_manager = ComponentManager[*other.component_types]()

        self.entity_id_range = other.entity_id_range
        self.component_id_range = other.component_id_range


    #MARK: draw_rect
    fn draw_rect(self, renderer: Renderer) raises:
        var color = Color(204, 204, 229)
        var position: Component = self.component_manager.get_id[Position]()
        var width: Component = self.component_manager.get_id[Width]()
        
        var archetypes = self.query_components(position, width)

        fn draw(pos: Position, w: Width) raises capturing:
            var R: Mat22 = Mat22(0)
            var x: Vector2 = Vector2(pos.x, pos.y)
            var h: Vector2 = Vector2(w.x, w.y) * 0.5

            # Calculate vertices
            var v1 = x + R * Vector2(-h.x, -h.y)
            var v2 = x + R * Vector2( h.x, -h.y)
            var v3 = x + R * Vector2( h.x,  h.y)
            var v4 = x + R * Vector2(-h.x,  h.y)

            renderer.set_color(color)

            renderer.draw_line(v2.x, v2.y, v1.x, v1.y)
            renderer.draw_line(v1.x, v1.y, v4.x, v4.y)
            renderer.draw_line(v2.x, v2.y, v3.x, v3.y)
            renderer.draw_line(v3.x, v3.y, v4.x, v4.y)

        for item in archetypes.values():
            var archetype = item[].archetype
            var columns = item[].columns
            var pos_col = archetype[].components[columns[0]]
            var width_col = archetype[].components[columns[1]]
            for i in range(len(pos_col)):
                draw(pos_col.get[Position](i), width_col.get[Width](i))

             
    #MARK: draw
    fn draw(self, renderer: Renderer) raises:
        renderer.set_color(background_clear)
        renderer.clear()

        for camera in self._cameras:
            renderer.set_target(camera[].get_target())
            renderer.set_color(background_clear)
            renderer.clear()

            # camera[].draw(self, renderer, Vector2(screen_width, screen_height))

            self.draw_rect(renderer)

            renderer.reset_target()
            renderer.set_viewport(camera[].get_viewport(renderer))
            renderer.copy(camera[].get_target(), None)

    #MARK: update
    fn update(inout self, time_step: Float32, mojo_sdl: sdl.SDL) raises:
        var position: Component = self.component_manager.get_id[Position]()

        var archetypes = self.query_components(position)

        for item in archetypes.values():
            var archetype = item[].archetype
            var columns = item[].columns
            var pos_col = Pointer.address_of(archetype[].components[columns[0]])
            for i in range(len(pos_col[])):
                pos_col[].get[Position](i).x += 5


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

        return archetype_queries


    #MARK: get_component
    fn get_component[T: CollectionElement](self, entity: Entity, component: Component) raises -> Optional[T]:
        var record = self.entity_index[entity]
        var archetype = UnsafePointer.address_of(self.archetype_container[record.archetype_idx])
        # First check if archetype has component
        var archetypes = self.component_index[component]

        # if component not in archetype[].type:
        #     return None

        if archetype[].id not in archetypes:
            return None
        
        var archetype_record = archetypes[archetype[].id]
        return archetype[].components[archetype_record.column].get[T](record.row)


    #MARK: set_component
    fn set_component[T: CollectionElement](inout self, entity: Entity, component: Component, value: T) raises:
        var record = self.entity_index[entity]
        var archetype = UnsafePointer.address_of(self.archetype_container[record.archetype_idx])
        # First check if archetype has component
        var archetypes = self.component_index[component]
        #MARK: FIX %%%%%%%%%%%%%%%%%%%%%%
        # need to check for idx instead of id
        if archetype[].id not in archetypes:
            return 
        
        var archetype_record = archetypes[archetype[].id]
        archetype[].components[archetype_record.column].append[T](value)


    #MARK: _generate_entity_id
    fn _generate_entity_id(self) -> UInt32:
        var r = self.entity_id_range
        var id = random_ui64(r[0].cast[DType.uint64](), r[1].cast[DType.uint64]()).cast[DType.uint32]()
        # MARK: fix
        while id in self.entity_index or id in self.component_index:
            id = random_ui64(r[0].cast[DType.uint64](), r[1].cast[DType.uint64]()).cast[DType.uint32]()

        return id


    #MARK: _create_archetype, 
    #NOTE: need to also store indices!
    fn _create_archetype(inout self, existing_type: EntityType, new_component: Component) raises:
        var new_type = existing_type
        new_type.add(new_component)
        # get the index that the new arch will be stored at in arch_container
        var index = len(self.archetype_container)
        # add new archetype to archetype_container
        self.archetype_container.append(Archetype(new_type))
        # add arch idx into arch_container to archetype_index
        self.archetype_index[hash(new_type)] = index

    fn _create_archetype(inout self, new_type: EntityType) raises:
        # get the index that the new arch will be stored at in arch_container
        var index = len(self.archetype_container)
        # add new archetype to archetype_container
        self.archetype_container.append(Archetype(new_type))
        # add arch idx into arch_container to archetype_index
        self.archetype_index[hash(new_type)] = index

    fn _create_archetype(inout self, new_component: Component, new_type: EntityType) raises:
        # get the index that the new arch will be stored at in arch_container
        var index = len(self.archetype_container)
        # add new archetype to archetype_container
        self.archetype_container.append(Archetype(new_type))
        # add arch idx into arch_container to archetype_index
        self.archetype_index[hash(new_type)] = index

        # create archetype_map for new_component


    # MARK: get_archetype
    fn get_archetype[T: Indexer](inout self, idx: T) -> ref [self.archetype_container] Archetype:
        return self.archetype_container[idx]

    fn get_archetype[T: Indexer](inout self, entity_type: EntityType) raises -> ref [self.archetype_container] Archetype:
        var index = self.archetype_index[hash(entity_type)]
        return self.archetype_container[index]


    # fn get_archetype[T: Indexer](inout self, idx: T) -> Pointer[Archetype, __origin_of(self.archetype_container)]:
    #     return Pointer.address_of(self.archetype_container[idx])

    # fn get_archetype[T: Indexer](inout self, entity_type: EntityType) raises -> Pointer[Archetype, __origin_of(self.archetype_container)]:
    #     var index = self.archetype_index[entity_type]
    #     return Pointer.address_of(self.archetype_container[index])


    #MARK: _move_entity_add
    # fn _move_entity_add[T: CollectionElement](inout self, inout src_archetype: Archetype, inout dst_archetype: Archetype, row: Int) raises -> Int:
    fn _move_entity_add[T: CollectionElement](inout self, 
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
    fn add_component_to_entity[T: CollectionElement](inout self, entity: Entity, new_component: Component) raises:
        # say we have an entity with archetype [Position, Velocity], and we want to add Health to it.
        var record = self.entity_index[entity]
        var src_idx: Int = record.archetype_idx
        # var src_archetype = UnsafePointer.address_of(self.get_archetype(src_idx))
        # var dst_archetype: UnsafePointer[Archetype, __origin_of(self.archetype_container)]
        var src_archetype = UnsafePointer.address_of(self.get_archetype(src_idx))
        var dst_archetype: UnsafePointer[Archetype]
        var dst_idx: Int

        # check if new_component has an existing edge
        # NOTE: if dst_archetype exists, we dont need to create new_type, because it already has that type
        if new_component in src_archetype[].edges:
            dst_idx = src_archetype[].edges[new_component].add
        else:
            # find (or create) archetype [Position, Velocity, Health].
            var new_type = src_archetype[].type
            # check if new_type is default_type
            if new_type == EntityType.default():
                new_type = EntityType()

            new_type.add(new_component)

            # if dst_archetype doesn't exist create it
            if hash(new_type) not in self.archetype_index:
                self._create_archetype(new_type)

            # get dst_archetype
            dst_idx = self.archetype_index[hash(new_type)]

            # create new edge for src_archetype going to dst_archetype
            src_archetype[].edges[new_component] = ArchetypeEdge(add=dst_idx)

        dst_archetype = UnsafePointer.address_of(self.get_archetype(dst_idx))

        # if new_component edge doesnt exists in dst_archetype
        if new_component not in dst_archetype[].edges:
            # create new edge for dst_archetype going to src_archetype
            dst_archetype[].edges[new_component] = ArchetypeEdge(remove=src_idx)
        else: 
            # update edge for new_component in dst_archetype
            dst_archetype[].edges[new_component].remove_component(src_idx)

        # move entity from src to dst, and return entities new row in dst_archetype
        var row = self._move_entity_add[T](src_archetype, dst_archetype, record.row)
        # update entities record
        self.entity_index[entity] = EntityRecord(dst_idx, row)

        # get the column for new_component in dst_archetype
        var column = dst_archetype[].type.get_index(new_component)
        # Store column in new_component's Archetype map
        self.component_index[new_component][dst_idx] = ArchetypeRecord(column)


    #MARK: _move_entity_remove
    fn _move_entity_remove[T: CollectionElement](inout self, 
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
    fn remove_component_from_entity[T: CollectionElement](inout self, entity: Entity, del_component: Component) raises:
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


    #MARK: create_component_id
    fn generate_component_id[T: CollectionElement](inout self) -> Entity:
        var id = self._generate_entity_id()
        var component = Entity()
        if self.component_manager.register_component[T](id):
            component.set_id(id)

        return component


    #MARK: add_entity
    fn _add_entity_old[*Ts: CollectionElement](inout self, *components: *Ts) raises -> Entity:
        # Create an id for the entity
        var entity: Entity = self._generate_entity_id()

        # add the entity to the entity index
        self.entity_index[entity] = EntityRecord(self.archetype_index[hash(EntityType.default())], 0)

        # add each component to the entity
        @parameter
        for i in range(len(VariadicList(Ts))):
            var component = Component(self.component_manager.get_id[Ts[i]]())
            if component == Component():
                component = self.generate_component_id[Ts[i]]()

            self.add_component_to_entity[Ts[i]](entity, component)
            self.set_component(entity, component, components[i])

        return entity

    fn add_entity[*Ts: CollectionElement](inout self, *components: *Ts) raises -> Entity:
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
        
        # # Update each components entry in component_index
        # for i in range(len(new_type)):
        #     # If component does not have an entry, create one
        #     if new_type[i] not in self.component_index:
        #         self.component_index[new_type[i]] = ArchetypeMap()
        #     self.component_index[new_type[i]][archetype_id] = i
            #               [0       , 1    ,    2     ]
            # Comp_values = [Position, Width,    Health]
            # Type =        [Width   , Position, Health]
            
            # {Component= Width:    {idx= 0: Column= 0}}
            # {Component= Position: {idx= 0: Column= 1}}
            # {Component= Health:   {idx= 0: Column= 2}}


        # Archetypes store component values based on the order of it's TYPE
        # EntityType Vectors are sorted high to low, so *components does not
        # contain the components in the order they are stored in archetypes.
        # We need to map *components indices to Type indices. We have to do it
        # in a separate step from registering components because the order of 
        # components in an EntityType change as new components are added.
        # This last note could have effects on ArchetypeMaps, if not handled 
        # when adding and removing components from entities.
        # var columns = ColumnsVector() 
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
            # columns[i] = new_type.get_index(component)
            
        # set the component values of each component
        # var row = self.archetype_container[idx].add_entity(columns, components)

        self.entity_index[entity] = EntityRecord(idx, row)

        return entity


    #MARK: get_component_id
    fn get_component_id[T: CollectionElement](self) -> Component:
        return self.component_manager.get_id[T]()

















































    # fn add_entity[*Ts: CollectionElement](inout self, *components: *Ts) raises -> Entity:
    #     # Create an id for the entity
    #     var entity: Entity = self._generate_entity_id()

    #     # var entity_type = EntityType()

    #     # update the default archetype containing the new entity and return the entities row
    #     # var tmp2 = Pointer.address_of(self.archetype_index[hash(EntityType.default())])
    #     # var type_hash = hash(EntityType.default())
    #     # print(len(self.archetype_index))
    #     # var tmp_type = EntityType(234532, 342385, 458723)
    #     # var arch: Archetype = Archetype(tmp_type)

    #     # for item in self.archetype_index.items():
    #     #     var key = item[].key
    #     #     arch = item[].value
    #     #     print(key, arch.type.data)


    #     var type_hash = hash(EntityType.default())
    #     # arch = self.archetype_index[type_hash]
    #     var tmp2 = UnsafePointer.address_of(self.archetype_index[type_hash])
    #     # self.entity_index[entity] = EntityRecord(tmp2, 0)

    #     # _ = arch



    #     # _ = tmp2

    #     # add the entity to the entity index
    #     # self.entity_index[entity] = EntityRecord(UnsafePointer[Archetype].address_of(self.archetype_index[hash(EntityType.default())]), 0)

    #     # @parameter
    #     # for i in range(len(VariadicList(Ts))):
    #     #     var component = Component(self.component_manager.get_id[Ts[i]]())
    #     #     if component == Component():
    #     #         component = self.create_component_id[Ts[i]]()
    #     #         entity_type.add(component)



    #     # if hash(entity_type) not in self.archetype_index:
    #     #     var new_archetype = Archetype(entity_type)
    #     #     self.archetype_index[new_archetype.id] = new_archetype

        
    #     # var ptr = UnsafePointer.address_of(self.archetype_index[hash(entity_type)])
    #     # self.entity_index[entity] = EntityRecord(ptr, 0)
    #     # # self.archetype_index[hash(entity_type)] = EntityRecord(ptr, 0)



    #     # # add each component to the entity
    #     # @parameter
    #     # for i in range(len(VariadicList(Ts))):
    #     #     var component = Component(self.component_manager.get_id[Ts[i]]())
    #     #     if component == Component():
    #     #         component = self.create_component_id[Ts[i]]()

    #     #     self.add_component_to_entity[Ts[i]](entity, component)
    #     #     self.set_component(entity, component, components[i])

    #     return entity
