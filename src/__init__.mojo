
from collections import Dict, InlineArray, Set

from .ecs_utils import *
from .physics import *
from .world import ECS, Position, Width, Velocity, ecs_physics, ecs_physics_render

from sdl import Renderer, Texture, Color, DPoint, DRect, Keyboard, KeyCode

from infrared.hard import g2