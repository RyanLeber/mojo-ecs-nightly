

alias Rect = DRect[DType.float32]

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
