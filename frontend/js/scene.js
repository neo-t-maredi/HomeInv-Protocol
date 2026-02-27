// ── Three.js 3D House Scene ──────────────────────────────────────
// Attaches to window — loaded before app.js

function initScene() {
    var container = document.getElementById('canvas-container');
    if (!container) return;

    var scene = new THREE.Scene();

    var camera = new THREE.PerspectiveCamera(45, container.clientWidth / container.clientHeight, 0.1, 1000);
    camera.position.set(0, 2, 8);
    camera.lookAt(0, 0, 0);

    var renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    container.appendChild(renderer.domElement);

    // Lighting
    var ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);

    var directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(5, 10, 7);
    directionalLight.castShadow = true;
    directionalLight.shadow.mapSize.width = 2048;
    directionalLight.shadow.mapSize.height = 2048;
    scene.add(directionalLight);

    var pointLight = new THREE.PointLight(0x6366f1, 0.5);
    pointLight.position.set(-5, 5, -5);
    scene.add(pointLight);

    var houseGroup = new THREE.Group();

    // Materials
    var wallMat     = new THREE.MeshStandardMaterial({ color: 0xf5f5f5, roughness: 0.8, metalness: 0.1 });
    var roofMat     = new THREE.MeshStandardMaterial({ color: 0x6366f1, roughness: 0.6, metalness: 0.2 });
    var woodMat     = new THREE.MeshStandardMaterial({ color: 0x8b5cf6, roughness: 0.9 });
    var glassMat    = new THREE.MeshStandardMaterial({ color: 0x87ceeb, roughness: 0.1, metalness: 0.9, transparent: true, opacity: 0.7 });
    var chimneyMat  = new THREE.MeshStandardMaterial({ color: 0x4a5568 });
    var platformMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.8 });

    // Base
    var base = new THREE.Mesh(new THREE.BoxGeometry(3, 2, 3), wallMat);
    base.position.y = 1;
    base.castShadow = true;
    base.receiveShadow = true;
    houseGroup.add(base);

    // Roof
    var roof = new THREE.Mesh(new THREE.ConeGeometry(2.5, 1.5, 4), roofMat);
    roof.position.y = 2.75;
    roof.rotation.y = Math.PI / 4;
    roof.castShadow = true;
    houseGroup.add(roof);

    // Door
    var door = new THREE.Mesh(new THREE.BoxGeometry(0.8, 1.5, 0.1), woodMat);
    door.position.set(0, 0.75, 1.51);
    houseGroup.add(door);

    // Windows
    var winGeo = new THREE.BoxGeometry(0.8, 0.8, 0.1);
    var w1 = new THREE.Mesh(winGeo, glassMat); w1.position.set(-1, 1.2, 1.51); houseGroup.add(w1);
    var w2 = new THREE.Mesh(winGeo, glassMat); w2.position.set( 1, 1.2, 1.51); houseGroup.add(w2);
    var w3 = new THREE.Mesh(winGeo, glassMat); w3.position.set( 1.51, 1.2, 0); w3.rotation.y = Math.PI/2; houseGroup.add(w3);
    var w4 = new THREE.Mesh(winGeo, glassMat); w4.position.set(-1.51, 1.2, 0); w4.rotation.y = Math.PI/2; houseGroup.add(w4);

    // Chimney
    var chimney = new THREE.Mesh(new THREE.BoxGeometry(0.4, 1, 0.4), chimneyMat);
    chimney.position.set(0.8, 3, -0.8);
    houseGroup.add(chimney);

    // Smoke
    var smokeParticles = [];
    var smokeGeo = new THREE.SphereGeometry(0.1, 8, 8);
    for (var i = 0; i < 5; i++) {
        var smokeMat = new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.3 });
        var smoke = new THREE.Mesh(smokeGeo, smokeMat);
        smoke.position.set(0.8, 3.5 + i * 0.3, -0.8);
        smoke.scale.set(1 + i * 0.3, 1 + i * 0.3, 1 + i * 0.3);
        houseGroup.add(smoke);
        smokeParticles.push({ mesh: smoke, offset: i * 0.5 });
    }

    // Platform
    var platform = new THREE.Mesh(new THREE.CylinderGeometry(4, 4, 0.2, 32), platformMat);
    platform.position.y = -0.1;
    platform.receiveShadow = true;
    houseGroup.add(platform);

    // Trees
    function createTree(x, z) {
        var tg = new THREE.Group();
        var trunk = new THREE.Mesh(
            new THREE.CylinderGeometry(0.1, 0.15, 0.8),
            new THREE.MeshStandardMaterial({ color: 0x5d4037 })
        );
        trunk.position.y = 0.4;
        var leaves = new THREE.Mesh(
            new THREE.ConeGeometry(0.5, 1.2, 8),
            new THREE.MeshStandardMaterial({ color: 0x10b981 })
        );
        leaves.position.y = 1.2;
        tg.add(trunk);
        tg.add(leaves);
        tg.position.set(x, 0, z);
        return tg;
    }

    houseGroup.add(createTree(-2.5, -2));
    houseGroup.add(createTree( 2.5, -2));
    houseGroup.add(createTree(-2.5,  2));
    houseGroup.add(createTree( 2.5,  2));

    scene.add(houseGroup);

    // Mouse
    var mouseX = 0, mouseY = 0;
    document.addEventListener('mousemove', function(e) {
        mouseX = (e.clientX / window.innerWidth)  * 2 - 1;
        mouseY = -(e.clientY / window.innerHeight) * 2 + 1;
    });

    // Animate
    var clock = new THREE.Clock();
    function animate() {
        requestAnimationFrame(animate);
        var time = clock.getElapsedTime();

        houseGroup.rotation.y  = Math.sin(time * 0.2) * 0.3;
        houseGroup.rotation.x += (mouseY * 0.2  - houseGroup.rotation.x) * 0.05;
        houseGroup.rotation.z += (-mouseX * 0.2 - houseGroup.rotation.z) * 0.05;
        houseGroup.position.y  = Math.sin(time) * 0.1;

        smokeParticles.forEach(function(p) {
            var t = (time + p.offset) % 2;
            p.mesh.position.y         = 3.5 + t * 0.5;
            p.mesh.material.opacity   = 0.3 - t * 0.15;
            p.mesh.scale.setScalar(1 + t * 0.5);
        });

        renderer.render(scene, camera);
    }
    animate();

    window.addEventListener('resize', function() {
        camera.aspect = container.clientWidth / container.clientHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(container.clientWidth, container.clientHeight);
    });
}
