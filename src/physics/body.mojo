
from math import isinf

alias INF = Float32.MAX

@value
struct Body(CollectionElement):
    var rotation: Float32
    var position: Vector2
    var velocity: Vector2
    var angular_velocity: Float32
    var force: Vector2
    var torque: Float32
    var friction: Float32
    
    var width: Vector2
    var mass: Float32
    var inv_mass: Float32
    var I: Float32
    var inv_i: Float32

    fn __init__(out self, width: Vector2, mass: Float32, *, position: Vector2= Vector2(0, 0), rotate: Float32= 0, rotation: Bool= True):
        self.rotation = 0.0 if rotate == 0 else rotate
        self.velocity = Vector2(0, 0) 
        self.angular_velocity = 0.0
        self.force = Vector2(0, 0)
        self.torque = 0.0
        self.friction = 0.2
        self.position = Vector2(0, 0) if position == Vector2(0, 0) else position
        self.width = Vector2(1.0, 1.0)
        self.mass = INF
        self.inv_mass = 0.0
        self.I = INF
        self.inv_i = 0.0

        self.set(width, mass, rotation=rotation)
        
    @always_inline
    fn add_force(mut self, force: Vector2):
        self.force += force

    fn set(mut self, width: Vector2, mass: Float32, *, rotation: Bool=True):
        self.width = width
        self.mass = mass

        if not isinf(mass) and rotation:  # Checking if mass is not infinity
            self.inv_mass = 1.0 / mass
            self.I = mass * (width.x * width.x + width.y * width.y) / 12.0
            self.inv_i = 1.0 / self.I
        elif not isinf(mass) and not rotation:
            self.inv_mass = 1.0 / mass
            self.I = INF
            self.inv_i = 0.0
        else:
            self.inv_mass = 0.0
            self.I = INF
            self.inv_i = 0.0
