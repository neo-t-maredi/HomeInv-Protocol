export function initScene() {
    const container = document.getElementById('canvas-container');
    if (!container) return;

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(45, container.clientWidth / container.clientHeight, 0.1, 1000);
    camera.position.set(0, 2, 8);
    camera.lookAt(0, 0, 0);

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    container.appendChild(renderer.domElement);

    // Lighting
    scene.add(new THREE.AmbientLight(0xffffff, 0.6));
    const dirLight = new THREE.DirectionalLight(0xffffff, 0.8);
    dirLight.position.set(5, 10, 7);
    dirLight.castShadow = true;
    scene.add(dirLight);
    const pointLight = new THREE.PointLight(0x6366f1, 0.5);
    pointLight.position.set(-5, 5, -5);
    scene.add(pointLight);

    // Materials
    const mat = {
        wall:     new THREE.MeshStandardMaterial({ color: 0xf5f5f5, roughness: 0.8, metalness: 0.1 }),
        roof:     new THREE.MeshStandardMaterial({ color: 0x6366f1, roughness: 0.6, metalness: 0.2 }),
        wood:     new THREE.MeshStandardMaterial({ color: 0x8b5cf6, roughness: 0.9 }),
        glass:    new THREE.MeshStandardMaterial({ color: 0x87ceeb, roughness: 0.1, metalness: 0.9, transparent: true, opacity: 0.7 }),
        chimney:  new THREE.MeshStandardMaterial({ color: 0x4a5568 }),
        platform: new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.8 }),
        smoke:    new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.3 }),
        trunk:    new THREE.MeshStandardMaterial({ color: 0x5d4037 }),
        leaves:   new THREE.MeshStandardMaterial({ color: 0x10b981 }),
    };

    const houseGroup = new THREE.Group();

    // Base
    const base = new THREE.Mesh(new THREE.BoxGeometry(3, 2, 3), mat.wall);
    base.position.y = 1; base.castShadow = true; base.receiveShadow = true;
    houseGroup.add(base);

    // Roof
    const roof = new THREE.Mesh(new THREE.ConeGeometry(2.5, 1.5, 4), mat.roof);
    roof.position.y = 2.75; roof.rotation.y = Math.PI / 4; roof.castShadow = true;
    houseGroup.add(roof);

    // Door
    const door = new THREE.Mesh(new THREE.BoxGeometry(0.8, 1.5, 0.1), mat.wood);
    door.position.set(0, 0.75, 1.51);
    houseGroup.add(door);

    // Windows
    const winGeo = new THREE.BoxGeometry(0.8, 0.8, 0.1);
    [[- 1, 1.2, 1.51, 0], [1, 1.2, 1.51, 0], [1.51, 1.2, 0, Math.PI / 2], [-1.51, 1.2, 0, Math.PI / 2]].forEach(([x, y, z, ry]) => {
        const w = new THREE.Mesh(winGeo, mat.glass);
        w.position.set(x, y, z); w.rotation.y = ry;
        houseGroup.add(w);
    });

    // Chimney
    const chimney = new THREE.Mesh(new THREE.BoxGeometry(0.4, 1, 0.4), mat.chimney);
    chimney.position.set(0.8, 3, -0.8);
    houseGroup.add(chimney);

    // Smoke
    const smokeParticles = [];
    for (let i = 0; i < 5; i++) {
        const smoke = new THREE.Mesh(new THREE.SphereGeometry(0.1, 8, 8), mat.smoke.clone());
        smoke.position.set(0.8, 3.5 + i * 0.3, -0.8);
        smoke.scale.setScalar(1 + i * 0.3);
        houseGroup.add(smoke);
        smokeParticles.push({ mesh: smoke, offset: i * 0.5 });
    }

    // Platform
    const platform = new THREE.Mesh(new THREE.CylinderGeometry(4, 4, 0.2, 32), mat.platform);
    platform.position.y = -0.1; platform.receiveShadow = true;
    houseGroup.add(platform);

    // Trees
    const createTree = (x, z) => {
        const g = new THREE.Group();
        const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.1, 0.15, 0.8), mat.trunk);
        trunk.position.y = 0.4;
        const leaves = new THREE.Mesh(new THREE.ConeGeometry(0.5, 1.2, 8), mat.leaves);
        leaves.position.y = 1.2;
        g.add(trunk, leaves);
        g.position.set(x, 0, z);
        return g;
    };
    [[-2.5,-2],[2.5,-2],[-2.5,2],[2.5,2]].forEach(([x,z]) => houseGroup.add(createTree(x,z)));
    scene.add(houseGroup);

    // Mouse
    let mouseX = 0, mouseY = 0;
    document.addEventListener('mousemove', e => {
        mouseX = (e.clientX / window.innerWidth) * 2 - 1;
        mouseY = -(e.clientY / window.innerHeight) * 2 + 1;
    });

    // Animate
    const clock = new THREE.Clock();
    (function animate() {
        requestAnimationFrame(animate);
        const time = clock.getElapsedTime();
        houseGroup.rotation.y = Math.sin(time * 0.2) * 0.3;
        houseGroup.rotation.x += (mouseY * 0.2 - houseGroup.rotation.x) * 0.05;
        houseGroup.rotation.z += (-mouseX * 0.2 - houseGroup.rotation.z) * 0.05;
        houseGroup.position.y = Math.sin(time) * 0.1;
        smokeParticles.forEach(p => {
            p.mesh.position.y = 3.5 + ((time + p.offset) % 2) * 0.5;
            p.mesh.material.opacity = 0.3 - ((time + p.offset) % 2) * 0.15;
            p.mesh.scale.setScalar(1 + ((time + p.offset) % 2) * 0.5);
        });
        renderer.render(scene, camera);
    })();

    window.addEventListener('resize', () => {
        camera.aspect = container.clientWidth / container.clientHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(container.clientWidth, container.clientHeight);
    });
}
