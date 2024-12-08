
from math import sin, cos

import sdl
from src import *


# MARK: Constants
alias background_clear = Color(12, 8, 6, 0)

alias iterations: Int = 10
alias GRAVITY = Vector2(0.0, -100.0)

alias INF = Float32.MAX
alias K_PI: Float32 = 3.14159265358979323846264
alias delta_time: Float32 = 1.0 / 60.0


alias screen_width = 1600
alias screen_height = 1000

alias keys = sdl.Keys

def main():
    var mojo_sdl = sdl.SDL(video=True, timer=True, events=True)
    var window = sdl.Window(mojo_sdl, "Mojo ECS", screen_width, screen_height)
    var mouse = sdl.Mouse(mojo_sdl)
    var renderer = sdl.Renderer(window^, flags = sdl.RendererFlags.SDL_RENDERER_ACCELERATED)
    var running = True

    var screen_dimensions = Vector2(screen_width, screen_height)
    var physics_engine = PhysicsEngine[GRAVITY, iterations]()
    var ecs = ECS[Position, Velocity, Width, Int, Body](renderer)

    var bodies = List[Entity]()

    var y_offset = sin(K_PI/4) * 500
    # Set the floor
    var ground = ecs.add_entity(Body(Vector2(1000.0, 20.0), INF, position=Vector2(0, -y_offset)))
    bodies.append(ground)
    # Set the left wall
    bodies.append(ecs.add_entity(
            Body(Vector2(1000.0, 20.0), INF, position=Vector2(-500.0 + -y_offset, 0), rotate= (3 * K_PI / 4))
        ))
    # Set the right wall
    bodies.append(ecs.add_entity(
            Body(Vector2(1000.0, 20.0), INF, position=Vector2(500.0 + y_offset, 0), rotate= (K_PI / 4))
        ))

    var spawn = False
    while running:
        for event in mojo_sdl.event_list():
            if event[].isa[sdl.events.QuitEvent]():
                running = False
                break
            if event[].isa[sdl.events.MouseButtonEvent]():
                if event[].unsafe_get[sdl.events.MouseButtonEvent]().clicks == 1 and 
                event[].unsafe_get[sdl.events.MouseButtonEvent]().state == 1:
                    var pos = Vector2(mouse.get_position()).screen_to_world(screen_dimensions)
                    var body = ecs.add_entity(Body(Vector2(50, 50), 200, position= pos))
                    bodies.append(body)
                    spawn = True
                elif event[].unsafe_get[sdl.events.MouseButtonEvent]().state == 0:
                    spawn = False


        ecs_physics_step(ecs, physics_engine, bodies, delta_time)
        ecs_physics_draw(ecs, renderer, bodies)

        renderer.present()
        

    _ = ecs^
           