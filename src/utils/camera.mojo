@value
struct Camera:
    var target: Texture
    var frame_count: Int
    var viewport: DRect[DType.float32]
    var is_main_camera: Bool

    fn __init__(
        out self, renderer: Renderer, viewport: DRect) raises:
        var size = renderer.get_output_size()
        self.target = Texture(renderer, sdl.TexturePixelFormat.RGBA8888, sdl.TextureAccess.TARGET, int(size[0] * viewport.w), int(size[1] * viewport.h))
        self.frame_count = 0
        self.viewport = viewport.cast[DType.float32]()
        self.is_main_camera = False

    fn get_target(self) -> Texture:
        return self.target

    fn get_viewport(self, size: Tuple[Int, Int]) raises -> DRect[DType.int32]:
        return DRect[DType.int32](self.viewport.x * size[0], self.viewport.y * size[1], self.viewport.w * size[0], self.viewport.h * size[1])

