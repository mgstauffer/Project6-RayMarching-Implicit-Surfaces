const THREE = require('three');
const EffectComposer = require('three-effectcomposer')(THREE)

import {PROXY_BUFFER_SIZE} from './proxy_geometry'

export default function RayMarcher(renderer, scene, camera) {
    var composer = new EffectComposer(renderer);
    var shaderPass = new EffectComposer.ShaderPass({
        uniforms: {
            u_buffer: {
                type: '4fv',
                value: undefined
            },
            u_count: {
                type: 'i',
                value: 0
            },
            u_unProjectTxfm: {
                type: 'm4',
                value: new THREE.Matrix4()
            },
            u_farPlane: {
                type: 'f',
                value: 2000
            },
            u_cameraPosition: {
                type: 'v3',
                value: undefined
            },
            u_lightPos: {
                type: 'v3',
                value: new THREE.Vector3(30, 50, 40)
            },
            
        },
        vertexShader: require('./glsl/pass-vert.glsl'),
        fragmentShader: require('./glsl/rayMarch-frag.glsl')
    });
    shaderPass.renderToScreen = true;
    composer.addPass(shaderPass);

    //stauffer add to renderer
    renderer.stauffShaderPass = shaderPass;

    return {
        render: function(buffer) {
            shaderPass.material.uniforms.u_buffer.value = buffer;
            shaderPass.material.uniforms.u_count.value = buffer.length / PROXY_BUFFER_SIZE;

            //Get the transforms used to unproject.
            //Just the view and proj matrices. Not the model matrix since we want point
            // in world space.
            //I believe camera.matrixWorldInverse is the view matrix on its own (i.e. w/out model).
            var worldInv = new THREE.Matrix4().getInverse( camera.matrixWorldInverse, true );
            var PrjInv = new THREE.Matrix4().getInverse( camera.projectionMatrix, true );
            shaderPass.material.uniforms.u_unProjectTxfm.value.multiplyMatrices( worldInv, PrjInv);
            //far clip plane
            shaderPass.material.uniforms.u_farPlane.value = camera.far;
            shaderPass.material.uniforms.u_cameraPosition.value = camera.position;

            //debug
            //Convert uv to world coords
            //start with a test NDC position
            /*
            var vec = new THREE.Vector3( 0.0,0.0, 1.0); //+z -> +1 == greater depth, after projection
            //scale up by arbitrary z (far place)
            console.log(' vec', vec );
            console.log('camera.far ', camera.far);
            vec.multiplyScalar( camera.far );
            //untransform
            console.log( 'worldInv', worldInv );
            console.log( 'PrjInv', PrjInv );
            console.log(' vec', vec );
            console.log( 'shaderPass.material.uniforms.u_unProjectTxfm', shaderPass.material.uniforms.u_unProjectTxfm.value );
            //console.log( shaderPass.material.uniforms.u_unProjectTxfm.value * new THREE.Vector4( vec, 0.0) );
            console.log( new THREE.Vector4( vec.x, vec.y, vec.z, 1.0 ) );
            console.log( new THREE.Vector4( vec.x, vec.y, vec.z, 1.0 ).applyMatrix4( shaderPass.material.uniforms.u_unProjectTxfm.value ) );
            */

            composer.render();
        }
    }
}