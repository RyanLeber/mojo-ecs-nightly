
from random import random_ui64, random_si64

alias background_clear = Color(12, 8, 6, 0)

# @value
struct World[screen_width: Int, screen_height: Int]:
    var _cameras: List[Camera]

    var archetype_ids: Set[Int]

    # Find an archetype by its list of component ids
    # A Key, Value pair containing a list of component ids and 
    var archetype_index: Dict[EntityType, Archetype]
    # var archetype_index: Dict[SmallSIMDVector[DType.int64, 32], Archetype]

    # Find the archetype for an entity
    # A Key, Value pair containing the entity_id and its archetype
    var entity_index: Dict[EntityId, EntityRecord]

    # Find the archetypes for a component
    # A Key, Value pair containing a component_id and a map containing all of the archetypes with that component
    var component_index: Dict[ComponentId, ArchetypeMap]

    fn __init__(inout self, renderer: Renderer) raises:
        self._cameras = List[Camera](capacity=1000)
        self._cameras.append(Camera(renderer, g2.Multivector(1, g2.Vector(800, 500)), g2.Vector(800, 500), DRect[DType.float32](0, 0, 1, 1)))

        self.archetype_ids = Set[Int]()

        self.archetype_index = Dict[EntityType, Archetype]()
        self.entity_index = Dict[Int, EntityRecord]()
        self.component_index = Dict[ComponentId, ArchetypeMap]()

"""
------------------------------------------------------------------------
Components:
------------------------------------------------------------------------

    position: Vec2(Int, Int)
    velocity: Vec2(Int, Int)
    health:   Int
    coins:    Int
    damage:   Int

------------------------------------------------------------------------
Entities:
------------------------------------------------------------------------

    entity_tile_1: [position]
    entity_tile_2: [position]
    entity_tile_3: [position]
    entity_tile_4: [position]

    entity_creature_1: [position, velocity]
    entity_creature_2: [position, velocity]

    entity_enemy_1: [position, velocity, health]
    entity_enemy_2: [position, velocity, health]
    entity_enemy_3: [position, velocity, health]

    entity_projectile: [position, velocity, damage]

    entity_player: [position, velocity, health, coins]

Note: these entity names represent their ids

------------------------------------------------------------------------
Archetypes:
------------------------------------------------------------------------

    archetype_1:
        id: Int = 1
        type: Entity_type = [position]
        components: List[Row] = 
        [
            [pos_1: Vec(0, 0), pos_2: Vec(0, 0), pos_3: Vec(0, 0), pos_4: Vec(0, 0)],
        ]
        edges: Dict[ComponentId, ArchetypeEdge] = 
        {
            
        }
    archetype_2:
        id: Int = 2
        type: Entity_type = [position, velocity]
        components: List[Row] = 
        [
            [pos_1: Vec(0, 0), pos_2: Vec(0, 0)],
            [vel_1: Vec(0, 0), vel_2: Vec(0, 0)],
        ]
        edges: Dict[ComponentId, ArchetypeEdge] = 
        {
            
        }

    archetype_3:
        id: Int = 3
        type: Entity_type = [position, velocity, health]
        components: List[Row] = 
        [
            [pos_1: Vec(0, 0), pos_2: Vec(0, 0), pos_3: Vec(0, 0)],
            [vel_1: Vec(0, 0), vel_2: Vec(0, 0), vel_3: Vec(0, 0)],
            [health_1: Int(100), health_2: Int(100), health_3: Int(100)]
        ]
        edges: Dict[ComponentId, ArchetypeEdge] = 
        {
            
        }

    archetype_4:
        id: Int = 4
        type: Entity_type = [position, velocity, damage]
        components: List[Row] = 
        [
            [pos_1: Vec(0, 0)],
            [vel_1: vec(0, 0)],
            [damage_1: Int(0)],
        ]
        edges: Dict[ComponentId, ArchetypeEdge] = 
        {
            
        }

    archetype_5:
        id: Int = 5
        type: Entity_type = [position, velocity, health, coins]
        components: List[Row] = 
        [
            [pos_1: Vec(0, 0)],
            [vel_1: vec(0, 0)],
            [health_1: Int(100)],
            [coins_1: Int(0)],
        ]
        edges: Dict[ComponentId, ArchetypeEdge] = 
        {
            
        }

------------------------------------------------------------------------

archetype_ids: Set[Int] = {archetype_1, archetype_2, archetype_3, archetype_4, archetype_5}


entity_index: Dict[EntityId: Int, Record: struct(archetype: pointer(archetype), row: Int)] =
    { EntityId : Record(pointer(archetype), Int) }
    { 
        entity_player : record(null, ?),
        entity_tile_1 : record(null, ?),
        entity_tile_2 : record(null, ?),
        entity_tile_3 : record(null, ?),
        entity_tile_4 : record(null, ?),
        entity_enemy_1 : record(null, ?),
        entity_enemy_2 : record(null, ?),
        entity_enemy_3 : record(null, ?),
        entity_projectile : record(null, ?),
        entity_creature_1 : record(null, ?),
        entity_creature_2 : record(null, ?),
    }

archetype_index: Dict[EntityType, Archetype]
    { EntiyType: [comp_id, comp_id] : Archetype }
    {
        [position]                          : archetype_1
        [position, velocity]                : archetype_2
        [position, velocity, health]        : archetype_3
        [position, velocity, damage]        : archetype_4
        [position, velocity, health, coins] : archetype_5
    }




component_index: Dict[ComponentId, ArchetypeMap]
    { Component_id: Int : {archetype_id: Int : archetype_record(column: Int)}}
    {
        position : {
                        archetype_1 : archetype_record(row= 1),
                        archetype_2 : archetype_record(row= 1),
                        archetype_3 : archetype_record(row= 1),
                        archetype_4 : archetype_record(row= 1),
                        archetype_5 : archetype_record(row= 1),
                    },
        velocity : {
                        archetype_2 : archetype_record(row= 2),
                        archetype_3 : archetype_record(row= 2),
                        archetype_4 : archetype_record(row= 2),
                        archetype_5 : archetype_record(row= 2),
                    },        
        health   : {
                        archetype_3 : archetype_record(row= 1),
                        archetype_5 : archetype_record(row= 1),
                    },
        damage   : {
                        archetype_4 : archetype_record(row= 1),
                    },
        coins    : {
                        archetype_5 : archetype_record(row= 1),
                    },
    }





"""




"""
Archetype:
    id: Int = 543423
    type: SmallSIMDVec = [43234, 35449, 54532] or [position, velocity, health]
    components: List[Row] = [
            [pos_1, pos_2, pos_3, pos_4],
            [vel_1, vel_2, vel_3, vel_4],
            [health_1, health_2, health_3, health_4],
        ]

archetype.components[arch_record.col][record.row]

archetype.components[col=1] -> [vel_1, vel_2, vel_3, vel_4]

archetype.components[row=2][col=3] -> health_3

|Row:           |col_0=entity_1 |col_1=entity_2 |col_1=entity_2 |col_1=entity_2 |
|---------------|---------------|---------------|---------------|---------------|
|row_0=position | (0,1)         | (0,0)         | (0,0)         | (0,0)         |
|row_1=velocity | (0,1)         | (0,0)         | (0,0)         | (0,0)         |
|row_2=health   | 100           | 100           | 100           | 100           |

"""

# alias ArchetypeRecord = Int
# """Index to a ComponentList (row) in an Archetypes component matrix"""
    