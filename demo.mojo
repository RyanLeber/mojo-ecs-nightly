
from math import sin, cos

import sdl
import infrared 
from src import *


# MARK: Constants
alias background_clear = Color(12, 8, 6, 0)

alias iterations: Int = 10
alias GRAVITY = Vector2(0.0, -100.0)

alias K_PI: Float32 = 3.14159265358979323846264
alias INF = Float32.MAX

alias scale = 1
alias screen_width = 1600
alias screen_height = 1000
alias view_width = screen_width // scale
alias view_height = screen_height // scale

alias keys = sdl.Keys


def main():
    var mojo_sdl = sdl.SDL(video=True, timer=True, events=True)
    var window = sdl.Window(mojo_sdl, "Mojo ECS", screen_width, screen_height)
    var keyboard = sdl.Keyboard(mojo_sdl)
    var mouse = sdl.Mouse(mojo_sdl)
    var renderer = sdl.Renderer(window^, flags = sdl.RendererFlags.SDL_RENDERER_ACCELERATED)
    var clock = sdl.Clock(mojo_sdl, 1000)
    var running = True

    var delta_time: Float32 = 1.0 / 60.0
    var screen_dimensions = Vector2(screen_width, screen_height)


    var physics_engine = PhysicsEngine[GRAVITY, iterations]()


    var ecs = ECS[view_width, view_height, Position, Velocity, Width, Int, Body](renderer)

    var spawn = False

    var bodies = List[Entity]()
    bodies.append(ecs.add_entity(Body(Vector2(1000.0, 20.0), INF, position=Vector2(0, -200)), Width(0,0)))
    
    while running:
        for event in mojo_sdl.event_list():
            if event[].isa[sdl.events.QuitEvent]():
                running = False
            if event[].isa[sdl.events.MouseButtonEvent]():
                if event[].unsafe_get[sdl.events.MouseButtonEvent]().clicks == 1 and event[].unsafe_get[sdl.events.MouseButtonEvent]().state == 1:
                    var pos = mouse.get_position()
                    bodies.append(ecs.add_entity(Body(Vector2(50, 50), 200, position=Vector2(pos[0], pos[1]).screen_to_world(screen_dimensions)), Width(0, 0)))
                    spawn = True
                elif event[].unsafe_get[sdl.events.MouseButtonEvent]().state == 0:
                    spawn = False
            if event[].isa[sdl.events.KeyDownEvent]():
                if event[].unsafe_get[sdl.events.KeyDownEvent]().key == keys.n1:
                    pass
                    
        clock.tick()

        ecs_physics(ecs, physics_engine, bodies, delta_time)
        ecs_physics_render(ecs, renderer, bodies)

        renderer.present()

    _ = physics_engine
    _ = ecs^
    
        