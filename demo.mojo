
from math import sin, cos

import sdl
import infrared 
from src import *


# MARK: Constants
alias background_clear = Color(12, 8, 6, 0)

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

    # world.init_demo()
    var delta_time: Float32 = 1.0 / 60.0

    var spawn = False

    # var world = World[view_width, view_height, Position, Velocity, Width, Int](renderer)
    var world = World[view_width, view_height, Position, Velocity, Width, Int](renderer)
    var box1 = world.add_entity(Position(100, 200), Width(50,50))
    var box2 = world.add_entity(Position(500, 200), Width(50,50))

    var boxes = List[Entity]()
    
    while running:
        for event in mojo_sdl.event_list():
            if event[].isa[sdl.events.QuitEvent]():
                running = False
            if event[].isa[sdl.events.MouseButtonEvent]():
                if event[].unsafe_get[sdl.events.MouseButtonEvent]().clicks == 1 and event[].unsafe_get[sdl.events.MouseButtonEvent]().state == 1:
                    var pos = mouse.get_position()
                    boxes.append(world.add_entity(Position(pos[0], pos[1]), Width(50,50)))
                    spawn = True
                elif event[].unsafe_get[sdl.events.MouseButtonEvent]().state == 0:
                    spawn = False
            if event[].isa[sdl.events.KeyDownEvent]():
                if event[].unsafe_get[sdl.events.KeyDownEvent]().key == keys.n1:
                    pass
                    # world.init_demo()
                    
        clock.tick()

        world.update(delta_time, mojo_sdl)
        world.draw(renderer)

        renderer.present()

    _ = world^
        