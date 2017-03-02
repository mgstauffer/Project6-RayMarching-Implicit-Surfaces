# HW 6: Ray marching and SDFs

## Stauffer

Wow, this was a mess for me. I spun my wheels about the non-constant array indexing issue I posted about. I'm confused about what other students were doing, or whether the u_buffer method was tested before being used in our base code.

I got most of the basics implemented. Here's what you see in my scene:

- My perspective is messed up. Presumably I'm not doing the un-projecting from uv to world space correctly, but I didn't have time to sort it out.
- Each of the basic shapes: box, sphere, cone, torus, cylinder
- I implemented very simple specular highlighting in my shading, using the surface normals. I'm curious about why the shading is banded/not-fully-smooth.
- The 2nd box above the first shows simple subtraction of a cylinder. However the shading is inverted. I got the normal from the subratced surface, i.e. the cylinder when it's negated distance was greater than the distance of the box. However I figure the normal needs inversion since we're shading the inside, but my rushed code couldn't handle a flag for that. -- wait! I just hacked it in, looks better now.
- The clam-like shape above the lower sphere is an intersection of two spheres.
- That's all, folks!

## -----------------------------------------------------------------------------

## Goal
In this assignment, you will be implementing SDF operators on various primitives and use a ray marcher to render them. Ray marching is a technique for rendering implicit surfaces where the ray-primitive intersection equation cannot be solved analytically.

**Warning**: this assignment diverges significantly from marching cubes, so switching options midway can be costly for  your time and effort.

## Base code framework

We have provided a preview scene, and a toggle for the ray marcher rendering. When you correctly implement the ray marcher, the image should match the preview scene containing the simple geometry. Your ray marching calculation should be performed in the fragment shader.

### Ray Marcher (25 pts)

The ray marcher should generate a ray direction, and march through the scene using the distances computed from sphere tracing.

**Note**: Your scene won't be rendered until you have implemented the SDFs for primitives below. 

- Generate Rays (15 pts): for each fragment inside the fragment shader, compute a ray direction for the ray marcher
- Sphere Tracing (10 pts): compute the nearest distance from the scene SDFs and update the ray marching's step size.

### SDF (50 pts)
##### Implement primitive SDFs (15pts):
These are simple primitives with well-defined SDFs. We encourage trying other SDFs not listed here, they are interesting! 
  - Sphere (3pts)
  - Box (3pts)
  - Cone (3pts)
  - Torus (3pts)
  - Cylinder (3pts)

##### Useful Operators (15pts)
To create constructive geometry, and interesting shapes (such as holes, bumps, etc.), implement the following operators to combine your primitive SDFs.
  - Intersection (2pts)
  - Subtraction (3pts)
  - Union (2pts)
  - Transformation (8pts)
    - translation and scaling
##### Compute normals based on gradient (15 pts)

Compute the normals to use for shading your surface.
- Read Chapter 13 of [Morgan McGuire's notes](http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf) 
##### Material (5pts)
Implement a simple Lambert material. Additional materials can earn extra points.

### Custom Scene (25 pts)
##### Create a mechanical device or a scene of your choice using all operators 
  - intersection, subtraction, union, transformation (20pts)
##### Animate the scene (5pts)
Use time as an input to some of your functions to animate your scene!

## Extra credits (Up to 30 pts)
- Implement SDF for [Mandelbulb](https://www.shadertoy.com/view/XsXXWS) (10pts)
  - You need to implement naive raymarching (not sphere tracing) to get this to work 
- Lighting effects 
  - Soft shadowing using secondary rays (5pts)
  - Ambient occlusion (10pts)
- Additional materials besides Lambert. (5pts each)
- Additional SDFs besides the listed primitive. (5pts each)

## Resources
http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf

## Submission
- Update `README.md` to contain a solid description of your project
- Publish your project to gh-pages. `npm run deploy`. It should now be visible at http://username.github.io/repo-name
- Create a [pull request](https://help.github.com/articles/creating-a-pull-request/) to this repository, and in the comment, include a link to your published project.
- Submit the link to your pull request on Canvas.

## Deploy
- `npm run build`
- Add and commit all changes
- `npm run deploy`
- If you're having problems with assets not linking correctly, make sure you wrap you're filepaths in `require()`. This will make the bundler package and your static assets as well. So, instead of `loadTexture('./images/thing.bmp')`, do `loadTexture(require('./images/thing.bmp'))`.
