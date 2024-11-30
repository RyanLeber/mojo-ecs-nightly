

from random import random_ui64, random_si64
from collections import Optional

from memory import UnsafePointer

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


# @value
struct World[screen_width: Int, screen_height: Int, *component_types: CollectionElement]:
    alias default_type = EntityType(UInt64.MAX-1, UInt64.MAX-2, UInt64.MAX-3, UInt64.MAX-4)
    var _cameras: List[Camera]

    var entity_id_range: Range
    var component_id_range: Range
    var archetype_id_range: Range

    # Store all component types and their ids for component mapping
    var component_manager: ComponentManager[component_types]

    # Find an archetype by its list of component ids
    # A Key, Value pair containing a list of component ids and 
    var archetype_index: Dict[Int, Archetype]
    # var archetype_index: Dict[SmallSIMDVector[DType.int64, 32], Archetype]

    # Find the archetype for an entity
    # A Key, Value pair containing the entity_id and its archetype
    var entity_index: Dict[Entity, EntityRecord]

    # Find the archetypes for a component
    # A Key, Value pair containing a component_id and a map containing the id's of all of the archetypes with that component
    var component_index: Dict[Component, ArchetypeMap]

    fn __init__(inout self) raises:
        self._cameras = List[Camera](capacity=100)
        # self._cameras.append(Camera(renderer, g2.Multivector(1, g2.Vector(800, 500)), g2.Vector(800, 500), DRect[DType.float32](0, 0, 1, 1)))

        self.archetype_index = Dict[Int, Archetype]()
        self.entity_index = Dict[Entity, EntityRecord]()
        self.component_index = Dict[Component, ArchetypeMap]()

        self.component_manager = ComponentManager[component_types]()

        self.entity_id_range = Range(1000, 2000)
        self.component_id_range = Range(0, 256)
        self.archetype_id_range = Range(100000, 200000)

        self._add_default_archetype()

    fn _add_default_archetype(inout self) raises:
        self.archetype_index[hash(Self.default_type)] = Archetype(Self.default_type)


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
                # var pos = pos_col.get[Position](i)
                # var w = width_col.get[Width](i)
                # var R: Mat22 = Mat22(0)
                # var x: Vector2 = Vector2(pos.x, pos.y)
                # var h: Vector2 = Vector2(w.x, w.y) * 0.5

                # # Calculate vertices
                # var v1 = x + R * Vector2(-h.x, -h.y)
                # var v2 = x + R * Vector2( h.x, -h.y)
                # var v3 = x + R * Vector2( h.x,  h.y)
                # var v4 = x + R * Vector2(-h.x,  h.y)

                # renderer.set_color(color)

                # renderer.draw_line(v2.x, v2.y, v1.x, v1.y)
                # renderer.draw_line(v1.x, v1.y, v4.x, v4.y)
                # renderer.draw_line(v2.x, v2.y, v3.x, v3.y)
                # renderer.draw_line(v3.x, v3.y, v4.x, v4.y)
             

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


    fn update(inout self, time_step: Float32, mojo_sdl: sdl.SDL) raises:
        # self.world.step(time_step)
        pass


    # fn has_component(self, entity_id: Int, component_id: Int) raises -> Bool:
    #     var record = self.entity_index[entity_id]
    #     var archetype = record.archetype
    #     return archetype[].id in self.component_index[component_id]

    fn query_components(self, *components: Component) raises -> Dict[Int, ArchetypeQuery]:
        alias ColumnType = SmallSIMDVector[DType.int32, sorted=False]
        var archetype_queries = Dict[Int, ArchetypeQuery]()
        var archetype_ids = List[Int]()

        # Get all archetype ids for each queried component and add them to a list
        for component in components:
            var arch_map = self.component_index[component]
            for item in arch_map.data.items():
                archetype_ids.append(item[].key)


        # Find each archetype by their id
        for id in archetype_ids:
            var archetype = Reference(self.archetype_index[id[]])
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
                if id[] not in archetype_queries:
                    archetype_queries[id[]] = ArchetypeQuery(UnsafePointer.address_of(archetype[]), component_columns)

        return archetype_queries


    # fn query_components[count: Int](self, *components: Component) raises -> Dict[Int, ArchetypeQuery]:
    #     if len(components) != count:
    #         raise Error("Count must equal the number of queried components.")
    #     alias ColumnType = SmallSIMDVector[DType.int32, sorted=False]
    #     var archetype_queries = Dict[Int, ArchetypeQuery]()
    #     var archetype_ids = List[Int]()

    #     # Get all archetype ids for each queried component and add them to a list
    #     for component in components:
    #         var arch_map = self.component_index[component]
    #         for item in arch_map.data.items():
    #             archetype_ids.append(item[].key)


    #     # Find each archetype by their id
    #     for id in archetype_ids:
    #         var archetype = Reference(self.archetype_index[id[]])
    #         var has_components = True
            
    #         var component_columns = ColumnType()

    #         # Check if the archetype has all queried components
    #         for component in components:
    #             var type = archetype[].type
    #             # If archetype has component, add that components column to component_columns
    #             if component in type:
    #                 component_columns.add(type.get_index(component))
    #             elif component not in type:
    #                 has_components = False
    #                 break
            
    #         # Archetype has all queried components, add the archetype to results
    #         if has_components == True:
    #             if id[] not in archetype_queries:
    #                 archetype_queries[id[]] = ArchetypeQuery(UnsafePointer.address_of(archetype[]), component_columns)

    #     return archetype_queries


    fn get_component[T: CollectionElement](self, entity: Entity, component: Component) raises -> Optional[T]:
        var record = self.entity_index[entity]
        var archetype = record.archetype
        # First check if archetype has component
        var archetypes = self.component_index[component]
        if archetype[].id not in archetypes:
            return None
        
        var archetype_record = archetypes[archetype[].id]
        return archetype[].components[archetype_record.column].get[T](record.row)

    fn set_component[T: CollectionElement](inout self, entity: Entity, component: Component, value: T) raises:
        var record = self.entity_index[entity]
        var archetype = record.archetype
        # First check if archetype has component
        var archetypes = self.component_index[component]
        if archetype[].id not in archetypes:
            return 
        
        var archetype_record = archetypes[archetype[].id]
        archetype[].components[archetype_record.column].append[T](value)

    fn _generate_entity_id(self) -> UInt32:
        var r = self.entity_id_range
        var id: UInt32 = random_ui64(r[0].cast[DType.uint64](), r[1].cast[DType.uint64]()).cast[DType.uint32]()
        # MARK: fix
        while id in self.entity_index or id in self.component_index:
            id = random_ui64(r[0].cast[DType.uint64](), r[1].cast[DType.uint64]()).cast[DType.uint32]()

        return id


    fn _create_archetype(inout self, existing_type: EntityType, new_component: Component) raises:
        var new_type = existing_type
        new_type.add(new_component)
        self.archetype_index[hash(new_type)] = Archetype(new_type)

    fn _create_archetype(inout self, new_type: EntityType) raises:
        # add new archetype to archetype_index
        self.archetype_index[hash(new_type)] = Archetype(new_type)

    fn _create_archetype(inout self, new_component: Component, new_type: EntityType) raises:
        # add new archetype to archetype_index
        self.archetype_index[hash(new_type)] = Archetype(new_type)
        # create archetype_map for new_component


    fn _move_entity_add[T: CollectionElement](inout self, src_archetype: UnsafePointer[Archetype], dst_archetype: UnsafePointer[Archetype], row: Int) raises -> Int:
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


    fn add_component_to_entity[T: CollectionElement](inout self, entity: Entity, new_component: Component) raises:
        # say we have an entity with archetype [Position, Velocity], and we want to add Health to it.
        var record = self.entity_index[entity]
        var src_archetype = record.archetype
        var dst_archetype: UnsafePointer[Archetype]

        # check if new_component has an existing edge
        # NOTE: if dst_archetype exists, we dont need to create new_type, because it already has that type
        if new_component in src_archetype[].edges:
            dst_archetype = src_archetype[].edges[new_component].add
        else:
            # find (or create) archetype [Position, Velocity, Health].
            var new_type = src_archetype[].type
            new_type.add(new_component)

            # if dst_archetype doesn't exist create it
            if hash(new_type) not in self.archetype_index:
                self._create_archetype(new_type)

            # get dst_archetype
            dst_archetype = UnsafePointer[Archetype].address_of(self.archetype_index[hash(new_type)])
            # create new edge for src_archetype going to dst_archetype
            src_archetype[].edges[new_component] = ArchetypeEdge(add=dst_archetype)

        # if new_component edge doesnt exists in dst_archetype
        if new_component not in dst_archetype[].edges:
            # create new edge for dst_archetype going to src_archetype
            dst_archetype[].edges[new_component] = ArchetypeEdge(remove=src_archetype)
        else: 
            # update edge for new_component in dst_archetype
            dst_archetype[].edges[new_component].remove_component(src_archetype)

        # move entity from src to dst, and return entities new row in dst_archetype
        var row = self._move_entity_add[T](src_archetype, dst_archetype, record.row)
        # update entities record
        self.entity_index[entity] = EntityRecord(dst_archetype, row)

        # get the column for new_component in dst_archetype
        var column = dst_archetype[].type.get_index(new_component)
        # Store column in new_component's Archetype map
        self.component_index[new_component][dst_archetype[].id] = ArchetypeRecord(column)

    fn _move_entity_remove[T: CollectionElement](inout self, src_archetype: UnsafePointer[Archetype], dst_archetype: UnsafePointer[Archetype], row: Int, del_component: Component) raises -> Int:
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


    fn remove_component_from_entity[T: CollectionElement](inout self, entity: Entity, del_component: Component) raises:
        # say we have an entity with archetype [Position, Velocity], and we want to add Health to it.
        var record = self.entity_index[entity]
        var src_archetype = record.archetype
        var dst_archetype: UnsafePointer[Archetype]

        # check if new_component has an existing edge
        # NOTE: if dst_archetype exists, we dont need to create new_type, because it already has that type
        if del_component in src_archetype[].edges:
            dst_archetype = src_archetype[].edges[del_component].remove
        else:
            # find (or create) archetype [Position, Velocity, Health].
            var new_type = src_archetype[].type
            _ = new_type.pop(del_component)

            # if dst_archetype doesn't exist create it
            if hash(new_type) not in self.archetype_index:
                self._create_archetype(new_type)

            # get dst_archetype
            dst_archetype = UnsafePointer[Archetype].address_of(self.archetype_index[hash(new_type)])
            # create new edge for src_archetype going to dst_archetype
            src_archetype[].edges[del_component] = ArchetypeEdge(remove=dst_archetype)

        # if new_component edge doesnt exists in dst_archetype
        if del_component not in dst_archetype[].edges:
            # create new edge for dst_archetype going to src_archetype
            dst_archetype[].edges[del_component] = ArchetypeEdge(add=src_archetype)
        else: 
            # update edge for new_component in dst_archetype
            dst_archetype[].edges[del_component].add_component(src_archetype)

        # move entity from src to dst, and return entities new row in dst_archetype
        var row = self._move_entity_remove[T](src_archetype, dst_archetype, record.row, del_component)
        # update entities record
        self.entity_index[entity] = EntityRecord(dst_archetype, row)

        # # remove the ArchetypeRecord (column) for dst_arch in del_component's Archetype map
        # _ = self.component_index[del_component].pop(dst_archetype[].id)


    fn create_component_id[T: CollectionElement](inout self) -> Entity:
        var id = self._generate_entity_id()
        var component = Entity()
        if self.component_manager.init_component[T](id):
            component.set_id(id)

        return component


    fn add_entity[*Ts: CollectionElement](inout self, *components: *Ts) raises -> Entity:
        # Create an id for the entity
        var id = self._generate_entity_id()
        var entity = Entity()
        entity.set_id(id)

        # update the default archetype containing the new entity and return the entities row
        var row = 0
        var tmp3 = self.archetype_index[hash(EntityType.default())]

        var tmp1 = UnsafePointer.address_of(self.archetype_index[hash(EntityType.default())])
        var tmp2 = EntityRecord(tmp1, row)

        self.entity_index[entity] = tmp2

        # add the entity to the entity index
        # self.entity_index[entity] = EntityRecord(UnsafePointer[Archetype].address_of(self.archetype_index[default_type_hash]), row)

        # add each component to the entity
        @parameter
        for i in range(len(VariadicList(Ts))):
            var component = Component(self.component_manager.get_id[Ts[i]]())
            if component == Component():
                component = self.create_component_id[Ts[i]]()

            self.add_component_to_entity[Ts[i]](entity, component)
            self.set_component(entity, component, components[i])

        # Need to create a type ereased type for components, does not solve problem
        # of, "How do you associate component id's with the type of that component?"

        # return the entity
        return entity

    fn world_init(inout self):
        ...

    fn get_component_id[T: CollectionElement](self) -> Component:
        return self.component_manager.get_id[T]()




    # fn create_component(inout self, *elems: object):
    #     var column = Column()
    #     var component_id = self._generate_component_id()

    #     for i in range(len(elems)):
    #         _ = column.append(elems[i])

    #     self.component_index[component_id] = ArchetypeMap()


    # fn create_entity(inout self):
    #     var entity_id = self._generate_entity_id()
    #     var arch = Archetype()

    #     # self.entity_index[entity_id] = Record()
        


"""
Archetype:
    id: Int = 543423
    type: SmallSIMDVec = [43234, 35449, 54532] or [position, velocity, health]
    components: List[Column] = [
            [(7,4), (0,11), 70],
            [(0,1), (0,0), 100],
            [(9,1), (-1,0), 80],
            [(3,3), (0,0), 100]
        ]

record.row returns an entities components

arch_record.column returns a components value from within a row

archetype.components[record.row][arch_record.col]

archetype.components[2] -> {row : [(9,1), (-1,0), 80]}

archetype.components[0][2] -> {health : 70}

"""

"""

|Row:          |col_1=position |column_2=velocity | col_3=health |
|--------------|---------------|------------------|--------------|
|row_1=entity1 | (0,1)         | (0,0)            | 100          |
|row_2=entity2 | (0,1)         | (0,0)            | 100          |
|row_3=entity3 | (0,1)         | (0,0)            | 100          |
|row_4=entity4 | (0,1)         | (0,0)            | 100          |

"""
    