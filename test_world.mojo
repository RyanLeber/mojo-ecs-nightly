from src import *

from memory import UnsafePointer

from collections import Set, Dict

# MARK: Constants
alias background_clear = Color(12, 8, 6, 0)

alias scale = 1
alias screen_width = 1600
alias screen_height = 1000
alias view_width = screen_width // scale
alias view_height = screen_height // scale

fn main() raises:

    var world = World[view_width, view_height, Position, Velocity, Width, Int]()
    # var type_hash = hash(EntityType.default())
    # var arch = world.archetype_index[type_hash]

    # print(arch.type.data)

    var box1 = world.add_entity(Position(100, 200), Width(50,50))

    # var default_hash = hash(EntityType.default())
    # print(default_hash)
    # print(hash(default_hash))
    # print(len(world.archetype_index))

    # var arch = world.archetype_index[default_hash]

    # print(arch.id)
    # print(arch.type.data)

    # var dict = Dict[Int, Set[Int]]


# 1694999876


    # _ = box1
    # var box2 = world.add_entity(Position(500, 200), Width(50,50))

    # _ = world^

    # var type = EntityType.default()
    # print(hash(type))
    # # # var type = TypeVector.default[16]()
    # # # var type = TypeVector[16](int(UInt32.MAX))
    # # print(type.data)

    # var arch = Archetype(type)
    # _ = arch

    # var arch_index = Dict[UInt, EntityRecord]()

    # arch_index[hash(type)] = EntityRecord(UnsafePointer.address_of(arch), 0)

    # var ptr = arch_index[hash(type)].archetype

    # print(ptr)

    # print(ptr[].type.data)



