module graphite.types.point;

import graphite.math;


struct Point
{
    this(float x, float y, float z = 0)
    {
        vec = Vec3f([x, y, z]);
    }


    Vec3f vec;
    alias vec this;
}