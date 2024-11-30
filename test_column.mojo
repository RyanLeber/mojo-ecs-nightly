

from src import Vector2, Column, Body

@value
@register_passable("trivial")
struct Vector3:
    var x: Int32
    var y: Int32
    var z: Int32


fn main() raises:

    var column1 = Column()

    column1.append(Vector2(0, 5))
    column1.append(Vector2(1, 5))
    column1.append(Vector2(2, 5))
    column1.append(Vector2(3, 5))
    column1.append(Vector2(4, 5))


    for i in range(len(column1)):
        print(column1.get[Vector2](i).data)

    print()


    var column2 = Column()

    column2.append(Vector3(0, 5, 9))
    column2.append(Vector3(1, 5, 7))
    column2.append(Vector3(2, 5, 6))
    column2.append(Vector3(3, 5, 5))
    column2.append(Vector3(4, 5, 4))


    for i in range(len(column2)):
        var vec = column2.get[Vector3](i)
        print("[", vec.x,",", vec.y, ",", vec.z,"]")

    print()

    var column3 = Column()

    for i in range(10):
        var b = Body()
        b.set(Vector2(10,10), (100 * (i + 1)))
        column3.append(b)

    for i in range(len(column3)):
        print("Body", i)
        print(column3.get[Body](i))
        print()
