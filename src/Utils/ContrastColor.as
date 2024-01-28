namespace ContrastColor
{
    vec3 Get(const vec3 &in c) 
    {
        return vec3(((0.299f * c.x) + (0.587f * c.y) + (0.114f * c.z)) < .5f ? 1 : 0);
    }
}