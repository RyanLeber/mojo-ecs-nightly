
alias background_clear = Color(12, 8, 6, 0)

fn ecs_physics_step(mut ecs: ECS, mut physics_engine: PhysicsEngine, body_entities: List[Entity], time_step: Float32) raises:
    var body_component: Component = ecs.get_component_id[Body]()
    # var joint_component: Component = ecs.get_component_id[Joint]()

    var bodies = List[UnsafePointer[Body]]()
    # var joints = List[UnsafePointer[Joint]]()

    for entity in body_entities:
        if not ecs.get_component[Body](entity[], body_component):
            return
        var body = UnsafePointer.address_of(ecs.get_component[Body](entity[], body_component).value()[])
        bodies.append(body)

    # for entity in joint_entities:
    #     var joint = UnsafePointer.address_of(ecs.get_component[Joint](entity[], joint_component))
    #     joints.append(joint)

    physics_engine.step(time_step, bodies)


fn ecs_physics_draw(mut ecs: ECS, renderer: Renderer, body_entities: List[Entity]) raises:
    var screen_dimensions = renderer.get_output_size()
    var body_component: Component = ecs.get_component_id[Body]()

    fn draw(b: Body) raises capturing:
        var color = Color(204, 204, 229)
        var R: Mat22 = Mat22(b.rotation)
        var x: Vector2 = b.position
        var h: Vector2 = b.width * 0.5

        # Calculate vertices
        var v1 = (x + R * Vector2(-h.x, -h.y)).world_to_screen(screen_dimensions)
        var v2 = (x + R * Vector2( h.x, -h.y)).world_to_screen(screen_dimensions)
        var v3 = (x + R * Vector2( h.x,  h.y)).world_to_screen(screen_dimensions)
        var v4 = (x + R * Vector2(-h.x,  h.y)).world_to_screen(screen_dimensions)

        renderer.set_color(color)

        renderer.draw_line(v2.x, v2.y, v1.x, v1.y)
        renderer.draw_line(v1.x, v1.y, v4.x, v4.y)
        renderer.draw_line(v2.x, v2.y, v3.x, v3.y)
        renderer.draw_line(v3.x, v3.y, v4.x, v4.y)

    renderer.set_color(background_clear)
    renderer.clear()

    for camera in ecs._cameras:
        renderer.set_target(camera[].get_target())
        renderer.set_color(background_clear)
        renderer.clear()

        for entity in body_entities:
            var body = ecs.get_component[Body](entity[], body_component)
            if not body:
                continue

            draw(body.value()[])

        renderer.reset_target()
        renderer.set_viewport(camera[].get_viewport(renderer.get_output_size()))
        renderer.copy(camera[].get_target(), None)

fn ecs_draw(mut ecs: ECS, renderer: Renderer, body_entities: List[Entity]) raises:
    var rect_component: Component = ecs.get_component_id[Rect]()

    renderer.set_color(background_clear)
    renderer.clear()

    for camera in ecs._cameras:
        renderer.set_target(camera[].get_target())
        renderer.set_color(background_clear)
        renderer.clear()
        for entity in body_entities:
            if not ecs.get_component[Rect](entity[], rect_component):
                return
            renderer.draw_rect(ecs.get_component[Rect](entity[], rect_component).value()[])

        renderer.reset_target()
        renderer.set_viewport(camera[].get_viewport(renderer.get_output_size()))
        renderer.copy(camera[].get_target(), None)


fn ecs_player_movement(mut ecs: ECS, entity: Entity, keyboard: sdl.Keyboard) raises:
    alias run = 30_000
    alias jump = 50_000
    var body_component: Component = ecs.get_component_id[Body]()
     
    if body_component == Component():
        raise Error("ecs_player_movement(), Entity must have Component: Body")

    if not ecs.get_component[Body](entity, body_component):
        return

    var body = ecs.get_component[Body](entity, body_component).value()

    if keyboard.get_key(sdl.KeyCode(sdl.KeyCode.A)):
        body[].add_force(Vector2(-run, 0))

    if keyboard.get_key(sdl.KeyCode(sdl.KeyCode.D)):
        body[].add_force(Vector2(run, 0))


fn ecs_player_jump(mut ecs: ECS, physics_engine: PhysicsEngine, player: Entity, ground: Entity, keyboard: sdl.Keyboard) raises:
    alias jump = 750_000
    var body_component: Component = ecs.get_component_id[Body]()
    if body_component == Component():
        raise Error("ecs_player_movement(), Entity must have Component: Body")

    if keyboard.get_key(sdl.KeyCode(sdl.KeyCode.SPACE)):
        if ecs_physics_contacting(ecs, physics_engine, player, ground):

            if not ecs.get_component[Body](player, body_component):
                return
            var body = ecs.get_component[Body](player, body_component).value()
            body[].add_force(Vector2(0, jump))


fn ecs_physics_contacting(ecs: ECS, physics_engine: PhysicsEngine, entity1: Entity, entity2: Entity) raises -> Bool:
    var body_component: Component = ecs.get_component_id[Body]()
    var b1 = int(UnsafePointer.address_of(ecs.get_component[Body](entity1, body_component).value()[]))
    var b2 = int(UnsafePointer.address_of(ecs.get_component[Body](entity2, body_component).value()[]))

    for key in physics_engine.arbiters.keys():
        if  key[].contacting(b1, b2): 
            return True
    return False
