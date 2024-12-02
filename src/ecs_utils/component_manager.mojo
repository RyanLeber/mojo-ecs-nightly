
from collections import InlineArray, InlineList
from sys.intrinsics import _type_is_eq

struct ComponentManager[*component_types: CollectionElement, count: Int = len(VariadicList(component_types))]:
    var type_mask: InlineArray[Bool, count]
    var type_ids: InlineArray[UInt32, count] 

    fn __init__(inout self):
        self.type_mask = InlineArray[Bool, count](False)
        self.type_ids = InlineArray[UInt32, count](0)

    # @staticmethod
    # fn default():
    #     var res = ComponentManager[
    #         Bool, 
    #         Int, Int8, Int16, Int32, Int64, 
    #         UInt, UInt8, UInt16, UInt32, UInt64,
    #         Vector2, Vector3, Mat22, Body 
    #     ]()

    fn register_component[type: CollectionElement](inout self, id: UInt32) -> Bool:
        # if not self.contains_type[type]():
        #     return 0
        @parameter
        for i in range(len(VariadicList(component_types))):
            alias T = component_types[i]
            if _type_is_eq[type, T]():
                if self.type_mask[i] == False:
                    self.type_mask[i] = True
                    self.type_ids[i] = id
                    return True
        return False

    fn contains_type[type: CollectionElement](self) -> Bool:
        @parameter
        for i in range(len(VariadicList(component_types))):
            alias T = component_types[i]
            @parameter
            if _type_is_eq[type, T]():
                return True
        return False

    fn is_type_init[type: CollectionElement](self) -> Bool:
        @parameter
        for i in range(len(VariadicList(component_types))):
            alias T = component_types[i]
            if _type_is_eq[type, T]():
                return self.type_mask[i]
        return False

    fn get_id[type: CollectionElement](self) -> UInt32:
        @parameter
        for i in range(len(VariadicList(component_types))):
            alias T = component_types[i]
            if _type_is_eq[type, T]():
                if self.type_mask[i] == True:
                    return self.type_ids[i]
                return 0
        return 0

    # fn get_id(self, component: Entity) -> CollectionElement:
    #     var id = component.get_id()
    #     @parameter
    #     for i in range(len(VariadicList(component_types))):
    #         if id in self.type_ids[i]:
    #             alias tmp = component_types[i]
    #             return component_types[i]
    #         # alias T = component_types[i]
    #         # if _type_is_eq[type, T]():
    #         #     if self.type_mask[i] == True:
    #         #         return self.type_ids[i]
    #         #     return 0
    #     return Position


        