require('file-loader?name=[name].[ext]!../index.html');

const THREE = require('three');
const OrbitControls = require('three-orbit-controls')(THREE)

import DAT from 'dat-gui'
import Stats from 'stats-js'
import ProxyGeometry, {ProxyMaterial} from './proxy_geometry'
import RayMarcher from './rayMarching'

var BoxGeometry = new THREE.BoxGeometry(1, 1, 1);
var SphereGeometry = new THREE.SphereGeometry(1, 32, 32);
var ConeGeometry = new THREE.ConeGeometry(1, 1);
var CylinderGeometry = new THREE.CylinderGeometry(0.5, 1, 2 );
var BoxGeometry = new THREE.BoxGeometry(1, 1, 1);
var TorusGeometry = new THREE.TorusGeometry(1.5,0.3);
var SphereGeometry2 = new THREE.SphereGeometry(1, 32, 32);
var SphereGeometry3 = new THREE.SphereGeometry(1, 32, 32);
var CylinderGeometry2 = new THREE.CylinderGeometry(0.75, 0.75, 2 );
var BoxGeometry2 = new THREE.BoxGeometry(1, 1, 1);

window.addEventListener('load', function() {
    var stats = new Stats();
    stats.setMode(1);
    stats.domElement.style.position = 'absolute';
    stats.domElement.style.left = '0px';
    stats.domElement.style.top = '0px';
    document.body.appendChild(stats.domElement);

    var scene = new THREE.Scene();
    var camera = new THREE.PerspectiveCamera( 75, window.innerWidth/window.innerHeight, 0.1, 1000 );
    var renderer = new THREE.WebGLRenderer( { antialias: true } );
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setClearColor(0x999999, 1.0);
    document.body.appendChild(renderer.domElement);

    var controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.enableZoom = true;
    controls.rotateSpeed = 0.3;
    controls.zoomSpeed = 1.0;
    controls.panSpeed = 2.0;

    window.addEventListener('resize', function() {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
    });

    var gui = new DAT.GUI();

    var options = {
        strategy: 'Proxy Geometry'
    }

    gui.add(options, 'strategy', ['Proxy Geometry', 'Ray Marching']);

    scene.add(new THREE.AxisHelper(20));
    scene.add(new THREE.DirectionalLight(0xffffff, 1)); //position is (always?) (0,1,0) - directional

    var proxyGeometry = new ProxyGeometry();

    var boxMesh = new THREE.Mesh(BoxGeometry, ProxyMaterial);
    var sphereMesh = new THREE.Mesh(SphereGeometry, ProxyMaterial);
    var cylinderMesh = new THREE.Mesh(CylinderGeometry, ProxyMaterial);
    var coneMesh = new THREE.Mesh(ConeGeometry, ProxyMaterial);
    var torusMesh = new THREE.Mesh(TorusGeometry, ProxyMaterial);
    var sphereMesh2 = new THREE.Mesh(SphereGeometry2, ProxyMaterial);
    var sphereMesh3 = new THREE.Mesh(SphereGeometry3, ProxyMaterial);
    var boxMesh2 = new THREE.Mesh(BoxGeometry2, ProxyMaterial);
    var cylinderMesh2 = new THREE.Mesh(CylinderGeometry2, ProxyMaterial);
        
    //sphereMesh.position.set(0,8,-2);
    boxMesh.position.set(-3, 0, 0);
    coneMesh.position.set(3, 0, 0);
    cylinderMesh.position.set(9, 0, 0);
    torusMesh.position.set(6,0,0);
    sphereMesh2.position.set(0,3.6,0);
    sphereMesh3.position.set(0,3,0);
    boxMesh2.position.set( -3,4,0);
    cylinderMesh2.position.set( -3,4,0);

    proxyGeometry.add(boxMesh);
    proxyGeometry.add(sphereMesh);
    proxyGeometry.add(coneMesh);
    proxyGeometry.add(cylinderMesh);
    proxyGeometry.add(torusMesh);

    proxyGeometry.add(sphereMesh2);
    proxyGeometry.add(sphereMesh3);
    proxyGeometry.add(boxMesh2);
    proxyGeometry.add(cylinderMesh2);

    scene.add(proxyGeometry.group);

    //camera.position.set(5, 10, 15);
    camera.position.set(0, 10, 13);
    camera.lookAt(new THREE.Vector3(0,0,0));
    controls.target.set(0,0,0);
    
    var rayMarcher = new RayMarcher(renderer, scene, camera);

    (function tick() {
        controls.update();
        stats.begin();
        proxyGeometry.update();
        
        if (options.strategy === 'Proxy Geometry') {
            renderer.render(scene, camera);
        } else if (options.strategy === 'Ray Marching') {
            renderer.stauffShaderPass.material.uniforms.u_cameraPosition.value = camera.position
            rayMarcher.render(proxyGeometry.buffer);
        }
        stats.end();
        requestAnimationFrame(tick);
    })();
});