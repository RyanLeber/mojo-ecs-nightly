
from collections import InlineArray

struct ComponentManager[*component_types: CollectionElement, count: Int = len(VariadicList(component_types))]:
    var type_mask: InlineArray[Bool, count]
    var type_ids: InlineArray[UInt32, count] 

    fn __init__(out self):
        self.type_mask = InlineArray[Bool, count](False)
        self.type_ids = InlineArray[UInt32, count](0)

    fn register_component[type: CollectionElement](mut self, id: UInt32) -> Bool:
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
        