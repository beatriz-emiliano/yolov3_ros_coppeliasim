// run `git config --local core.hooksPath .githooks/`
// to automatically bump this after each commit:
const __REV__ = 227;

const rad = Math.PI / 180;
const deg = 180 / Math.PI;

$('#about').text(`r${__REV__}`);

function mixin(target, source) {
    // ignore the Function-properties
    const {name, length, prototype, ...statics} = Object.getOwnPropertyDescriptors(source);
    Object.defineProperties(target, statics);

    // ignore the constructor
    const {constructor, ...proto} = Object.getOwnPropertyDescriptors(source.prototype);
    Object.defineProperties(target.prototype, proto);

    return target;
}

class EventSourceMixin {
    addEventListener(eventName, listener) {
        if(!this._eventListeners)
            this._eventListeners = {};
        if(!this._eventListeners[eventName])
            this._eventListeners[eventName] = [];
        this._eventListeners[eventName].push(listener);
    }

    removeEventListener(eventName, listener) {
        let listeners = this._eventListeners?.[eventName];
        if(!listeners) return;
        for(let i = 0; i < listeners.length; i++) {
            if(listeners[i] === listener) {
                listeners.splice(i--, 1);
            }
        }
    }

    dispatchEvent(eventName, ...args) {
        var count = 0;
        if(this._eventListeners?.[eventName]) {
            for(var listener of this._eventListeners[eventName]) {
                listener.apply(this, args);
                count++;
            }
        }
        return count;
    }
}

class Settings {
    constructor(disableAutoWrite) {
        this.selection = {
            style: {
                boundingBox: true,
                boundingBoxSolidOpacity: 0.0,
                boundingBoxSolidSide: THREE.BackSide,
                boundingBoxOnTop: false,
                boundingBoxLocal: false,
                boundingBoxModelDashed: false,
                boundingBoxModelSolidOpacity: 0.15,
                boundingBoxModelSolidSide: THREE.FrontSide,
                boundingBoxBlinkInterval: 0,
                outline: false,
                edges: true,
                edgesColor: [1, 1, 1, 0.5],
            },
        };
        this.transformControls = {
            size: 1,
            sendRate: 0,
        };
        this.dummy = {
            style: 1,
        };
        this.octree = {
            maxVoxelCount: 1000000,
        };
        this.events = {
            logging: false,
            discardOutOfSequence: true,
            warnOutOfSequence: true,
        };
        this.shadows = {
            enabled: false,
        };
        if(!disableAutoWrite) {
            this.read();
            setInterval(() => this.write(), 1000);
        }
    }

    read() {
        var data = localStorage.getItem('settings') || '{}';
        localStorage.setItem('settings', data);
        data = JSON.parse(data);
        Settings.setObject(this, data);
    }

    write() {
        var oldData = localStorage.getItem('settings');
        if(oldData === null)
            return; // settings were removed, don't write anything
        var newSettings = new Settings(true);
        Settings.setObject(newSettings, this);
        Settings.setObject(this, newSettings, true);
        var newData = JSON.stringify(newSettings);
        if(oldData !== newData) {
            localStorage.setItem('settings', newData);
            console.log('Wrote settings to local storage');
        }
    }

    static setObject(dest, src, createNewKeys) {
        for(var k in src) {
            if(!createNewKeys && dest[k] === undefined) continue;
            if(typeof dest[k] === 'function') continue;
            if(typeof dest[k] === 'object') {
                if(dest[k] === undefined) dest[k] = {};
                Settings.setObject(dest[k], src[k]);
            } else {
                dest[k] = src[k];
            }
        }
    }
}

const settings = new Settings();

class VisualizationStreamClient {
    constructor(host = 'localhost', port = 23020, codec = 'cbor') {
        this.host = host;
        this.port = port;
        this.codec = codec;
        this.websocket = new ReconnectingWebSocket(`ws://${this.host}:${this.port}`);
        this.sessionId = '???';
        this.seq = -1;
        if(codec == 'cbor') {
            this.websocket.binaryType = 'arraybuffer';
            this.websocket.onmessage = async (event) => this.handleEvents(CBOR.decode(await event.data.arrayBuffer()));
        } else if(codec == 'json') {
            this.websocket.onmessage = (event) => this.handleEvents(JSON.parse(event.data));
        }
    }

    handleEvents(eventsData) {
        if(eventsData.length !== undefined)
            for(var eventData of eventsData)
                this.handleEvent(eventData);
        else if(eventsData.event !== undefined)
            this.handleEvent(eventsData);
    }

    handleEvent(eventData) {
        if(eventData.event === 'appSession' && eventData.data.sessionId) {
            if(this.sessionId !== eventData.data.sessionId) {
                this.seq = -1;
                this.sessionId = eventData.data.sessionId;
            }
            return;
        }

        if(eventData.seq !== undefined && eventData.seq <= this.seq && settings.events.discardOutOfSequence && settings.events.warnOutOfSequence) {
            console.warn(`Discarded event with seq=${eventData.seq} (mine is ${this.seq})`);
        }

        if(settings.events.logging) {
            const eventInfo = (eventData) => {
                return eventData.event;
            }

            const uidInfo = (eventData) => {
                var info = `${eventData.uid}`;
                if(eventData.data.alias)
                    info += ` (${eventData.data.alias})`;
                var obj = sceneWrapper.getObjectByUid(eventData.uid);
                if(obj !== undefined)
                    info += ` (${obj.name})`;
                return info;
            }

            var li = document.createElement('li');
            if(eventData.seq !== undefined && eventData.seq <= this.seq)
                li.classList.add('rejected');
            var hdr = document.createElement('span');
            hdr.classList.add('event-header');
            var txt = document.createTextNode(`${eventData.seq}\t${eventInfo(eventData)}\t${uidInfo(eventData)} `);
            hdr.appendChild(txt);
            li.appendChild(hdr);
            li.appendChild(renderjson(eventData));
            document.getElementById('log').appendChild(li);
        }

        if(eventData.seq !== undefined && eventData.seq <= this.seq && settings.events.discardOutOfSequence) {
            return;
        }

        if(this.dispatchEvent(eventData.event, eventData) == 0) {
            console.warn(`No listeners for event "${eventData.event}"`, eventData);
        }

        this.seq = eventData.seq;
    }
}

mixin(VisualizationStreamClient, EventSourceMixin);

class BaseObject extends THREE.Group {
    static objectsByUid = {};

    static getObjectByUid(uid) {
        return this.objectsByUid[uid];
    }

    constructor(sceneWrapper) {
        super();
        this.sceneWrapper = sceneWrapper;
        this.userData.type = 'unknown';
    }

    init() {
        // this should be called after object creation only if object is not cloned
        // to initialize any children (e.g. visuals, frames, ...) that are part of
        // the object
    }

    clone(recursive) {
        var obj = new this.constructor(this.sceneWrapper).copy(this, recursive);
        return obj;
    }

    get parentObject() {
        return BaseObject.getObjectByUid(this.userData.parentUid);
    }

    get nameWithOrder() {
        return this.name + (this.userData.childOrder === -1 ? '' : `[${this.userData.childOrder}]`);
    }

    get path() {
        return (this.parentObject ? `${this.parentObject.path}/` : '/') + this.nameWithOrder;
    }

    get childObjects() {
        var objs = [];
        for(var o of this.children) {
            if(o instanceof DrawingObject) continue;
            if(o.userData.parentUid === this.userData.uid)
                objs.push(o);
        }
        return objs;
    }

    get ancestorObjects() {
        var objs = [];
        var o = this;
        while(o.parentObject) {
            o = o.parentObject;
            objs.push(o);
        }
        return objs;
    }

    update(eventData) {
        if(eventData.uid !== undefined)
            this.setUid(eventData.uid);
        if(eventData.handle !== undefined)
            this.setHandle(eventData.handle);
        if(eventData.data.alias !== undefined)
            this.setAlias(eventData.data.alias);
        if(eventData.data.childOrder !== undefined)
            this.setChildOrder(eventData.data.childOrder);
        if(eventData.data.parentUid !== undefined)
            this.setParent(eventData.data.parentUid);
        if(eventData.data.pose !== undefined)
            this.setPose(eventData.data.pose);
        if(eventData.data.layer !== undefined)
            this.setLayer(eventData.data.layer);
        if(eventData.data.objectProperty !== undefined)
            this.setObjectProperty(eventData.data.objectProperty);
        if(eventData.data.modelProperty !== undefined)
            this.setModelProperty(eventData.data.modelProperty);
        if(eventData.data.modelBase !== undefined)
            this.setModelBase(eventData.data.modelBase);
        if(eventData.data.modelInvisible !== undefined)
            this.setModelInvisible(eventData.data.modelInvisible);
        if(eventData.data.movementOptions !== undefined)
            this.setMovementOptions(eventData.data.movementOptions);
        if(eventData.data.movementPreferredAxes !== undefined)
            this.setMovementPreferredAxes(eventData.data.movementPreferredAxes);
        if(eventData.data.movementRelativity !== undefined)
            this.setMovementRelativity(eventData.data.movementRelativity);
        if(eventData.data.movementStepSize !== undefined)
            this.setMovementStepSize(eventData.data.movementStepSize);
        if(eventData.data.boundingBox !== undefined)
            this.setBoundingBox(eventData.data.boundingBox);
        if(eventData.data.customData !== undefined)
            this.setCustomData(eventData.data.customData);
    }

    setUid(uid) {
        if(this.userData.uid !== undefined) {
            if(BaseObject.objectsByUid[this.userData.uid] !== undefined) {
                delete BaseObject.objectsByUid[this.userData.uid];
            }
        }
        this.userData.uid = uid;
        BaseObject.objectsByUid[uid] = this;
    }

    setHandle(handle) {
        this.userData.handle = handle;
    }

    setAlias(alias) {
        this.name = alias;
    }

    setChildOrder(childOrder) {
        this.userData.childOrder = childOrder;
    }

    setParent(parentUid) {
        this.userData.parentUid = parentUid
        var parentObj = BaseObject.getObjectByUid(parentUid);
        if(parentObj !== undefined) {
            var p = this.position.clone();
            var q = this.quaternion.clone();
            parentObj.attach(this);
            this.position.copy(p);
            this.quaternion.copy(q);
        } else /*if(parentUid === -1)*/ {
            if(parentUid !== -1)
                console.error(`Parent with uid=${parentUid} is not known`);
            this.sceneWrapper.scene.attach(this);
        }
    }

    getPose() {
        return [
            ...this.position.toArray(),
            ...this.quaternion.toArray(),
        ];
    }

    setPose(pose) {
        this.position.set(pose[0], pose[1], pose[2]);
        this.quaternion.set(pose[3], pose[4], pose[5], pose[6]);
    }

    getAbsolutePose() {
        this.updateMatrixWorld();
        var position = new THREE.Vector3();
        position.setFromMatrixPosition(this.matrixWorld);
        var quaternion = new THREE.Quaternion();
        quaternion.setFromRotationMatrix(this.matrixWorld);
        return [
            ...position.toArray(),
            ...quaternion.toArray(),
        ];
    }

    setLayer(layer) {
        this.userData.layer = layer;
    }

    setObjectProperty(objectProperty) {
        this.userData.objectProperty = objectProperty;
        this.setSelectable((objectProperty & 0x20) > 0);
        this.setSelectModelBase((objectProperty & 0x80) > 0);
        this.setExcludeFromBBoxComputation((objectProperty & 0x100) > 0);
        this.setClickInvisible((objectProperty & 0x800) > 0);
    }

    setSelectable(selectable) {
        this.userData.selectable = selectable;
    }

    setSelectModelBase(selectModelBase) {
        this.userData.selectModelBase = selectModelBase;
    }

    setExcludeFromBBoxComputation(exclude) {
        this.userData.excludeFromBBoxComputation = exclude;
    }

    setClickInvisible(clickInvisible) {
        this.userData.clickInvisible = clickInvisible;
    }

    setModelProperty(modelProperty) {
        this.userData.modelProperty = modelProperty;
        this.setExcludeModelFromBBoxComputation((modelProperty & 0x400) > 0);
    }

    setExcludeModelFromBBoxComputation(exclude) {
        this.userData.excludeModelFromBBoxComputation = exclude;
    }

    setModelBase(modelBase) {
        this.userData.modelBase = modelBase;
    }

    setModelInvisible(modelInvisible) {
        this.userData.modelInvisible = modelInvisible;
        // trigger `layer` update:
        this.setLayer(this.userData.layer);
    }

    computedLayer() {
        if(this.userData.modelInvisible)
            return 0;
        return this.userData.layer;
    }

    setMovementOptions(movementOptions) {
        this.userData.movementOptions = movementOptions;
        this.userData.canTranslateOutsideSimulation = !(movementOptions & 0x1);
        this.userData.canTranslateDuringSimulation = !(movementOptions & 0x2);
        this.userData.canRotateOutsideSimulation = !(movementOptions & 0x4);
        this.userData.canRotateDuringSimulation = !(movementOptions & 0x8);
        this.userData.hasTranslationalConstraints = !!(movementOptions & 0x10);
        this.userData.hasRotationalConstraints = !!(movementOptions & 0x20);
    }

    setMovementPreferredAxes(movementPreferredAxes) {
        this.userData.movementPreferredAxes = {
            translation: {
                x: !!(movementPreferredAxes & 0x1),
                y: !!(movementPreferredAxes & 0x2),
                z: !!(movementPreferredAxes & 0x4),
            },
            rotation: {
                x: !!(movementPreferredAxes & 0x8),
                y: !!(movementPreferredAxes & 0x10),
                z: !!(movementPreferredAxes & 0x20),
            },
        };
    }

    setMovementRelativity(movementRelativity) {
        this.userData.movementRelativity = movementRelativity;
        this.userData.translationSpace = movementRelativity[0] === 0 ? 'world' : 'local';
        this.userData.rotationSpace = movementRelativity[1] === 0 ? 'world' : 'local';
    }

    setMovementStepSize(movementStepSize) {
        this.userData.movementStepSize = movementStepSize;
        this.userData.translationStepSize = movementStepSize[0] > 0 ? movementStepSize[0] : null;
        this.userData.rotationStepSize = movementStepSize[1] > 0 ? movementStepSize[1] : null;
    }

    setBoundingBox(boundingBox) {
        this.userData.boundingBox = boundingBox;
    }

    get boundingBoxObjects() {
        var objects = [];
        if(this.userData.modelBase) {
            var queue = [];
            queue.push(this);
            while(queue.length > 0) {
                var o = queue.shift();
                if(!(o.userData.excludeFromBBoxComputation === true))
                    objects.push(o);
                if(o === this || !(o.userData.excludeModelFromBBoxComputation === true))
                    for(var c of o.childObjects)
                        queue.push(c);
            }
        } else {
            objects.push(this);
        }
        return objects;
    }

    setCustomData(customData) {
        this.userData.customData = customData;
    }
}

class Shape extends BaseObject {
    constructor(sceneWrapper) {
        super(sceneWrapper);
        this.userData.type = 'shape';
        this.userData.count = 0;
    }

    update(eventData) {
        super.update(eventData);
        if(eventData.data.shape !== undefined)
            this.setShape(eventData.data.shape);
    }

    setLayer(layer) {
        super.setLayer(layer);
        for(var submesh of this.children) {
            if(submesh.userData.type !== 'submesh') continue;
            for(var c of submesh.children) {
                c.layers.mask = this.computedLayer();
            }
        }
    }

    setShape(shape) {
        if(shape.meshes !== undefined)
            this.setShapeMeshes(shape.meshes);
        if(shape.color !== undefined)
            this.setShapeColor(shape.color);
    }

    setShapeMeshes(meshes) {
        for(var submesh of this.children) {
            if(submesh.userData.type !== 'submesh') continue;
            this.remove(submesh);
        }
        this.userData.count = meshes.length;
        for(var i = 0; i < meshes.length; i++) {
            var g = new THREE.Group();
            g.userData.type = 'submesh';
            g.userData.index = i;

            var mesh = Shape.createMesh(meshes[i]);
            mesh.name = `Mesh ${i}`;
            mesh.userData.type = 'mesh';
            mesh.userData.pickThisIdInstead = this.id;
            mesh.userData.showEdges = !!meshes[i].showEdges;
            mesh.userData.shadingAngle = meshes[i].shadingAngle;
            mesh.castShadow = settings.shadows.enabled;
            mesh.receiveShadow = settings.shadows.enabled;

            const edgeMesh = new THREE.LineSegments(
                meshes[i].shadingAngle < 1e-4
                    ? new THREE.WireframeGeometry(mesh.geometry)
                    : new THREE.EdgesGeometry(mesh.geometry, meshes[i].shadingAngle * 180 / Math.PI),
                new THREE.LineBasicMaterial({color: 0x000000})
            );
            edgeMesh.name = `Edges ${i}`;
            edgeMesh.visible = !!meshes[i].showEdges;
            edgeMesh.userData.type = 'edges';
            edgeMesh.userData.pickThisIdInstead = this.id;

            g.add(mesh);
            g.add(edgeMesh);
            this.add(g);
        }

        // submeshes have changed -> set layer
        this.setLayer(this.userData.layer);
    }

    getSubMeshGroup(index) {
        for(var c of this.children) {
            if(c.userData.type === 'submesh' && c.userData.index === index)
                return c;
        }
    }

    getSubMesh(index) {
        var g = this.getSubMeshGroup(index);
        for(var c of g.children) {
            if(c.userData.type === 'mesh')
                return c;
        }
    }

    getSubMeshEdges(index) {
        var g = this.getSubMeshGroup(index);
        for(var c of g.children) {
            if(c.userData.type === 'edges')
                return c;
        }
    }

    setShapeColor(color) {
        const i = color.index || 0;
        const mesh = this.getSubMesh(i);
        if(color.color !== undefined) {
            const c = color.color;
            mesh.material.color.setRGB(c[0], c[1], c[2]);
            mesh.material.specular.setRGB(c[3], c[4], c[5]);
            mesh.material.emissive.setRGB(c[6], c[7], c[8]);
        }
        if(color.transparency !== undefined) {
            mesh.material.transparent = color.transparency > 1e-4;
            mesh.material.opacity = 1 - color.transparency;
        }
        if(color.showEdges !== undefined) {
            const edges = this.getSubMeshEdges(i);
            edges.visible = color.showEdges;
        }
    }

    setEdgesColor(c) {
        for(var i = 0; i < this.userData.count; i++) {
            const edges = this.getSubMeshEdges(i);
            if(c === null) {
                edges.material.color.setRGB(0, 0, 0);
                edges.material.transparent = false;
                edges.material.opacity = 1.0;
                edges.visible = !!this.getSubMesh(i).userData.showEdges;
            } else {
                edges.material.color.setRGB(c[0], c[1], c[2]);
                edges.material.transparent = true;
                edges.material.opacity = c[3] || 1.0;
                edges.visible = true;
            }
        }
    }

    static createMesh(data) {
        const geometry = new THREE.BufferGeometry();
        // XXX: vertex attribute format handed by CoppeliaSim is not correct
        //      we expand all attributes and discard indices
        if(false) {
            geometry.setIndex(data.indices);
            geometry.setAttribute('position', new THREE.Float32BufferAttribute(data.vertices, 3));
            geometry.setAttribute('normal', new THREE.Float32BufferAttribute(data.normals, 3));
        } else {
            var ps = [];
            var ns = [];
            for(var i = 0; i < data.indices.length; i++) {
                var index = data.indices[i];
                var p = data.vertices.slice(3 * index, 3 * (index + 1));
                ps.push(p[0], p[1], p[2]);
                var n = data.normals.slice(3 * i, 3 * (i + 1));
                ns.push(n[0], n[1], n[2]);
            }
            geometry.setAttribute('position', new THREE.Float32BufferAttribute(ps, 3));
            geometry.setAttribute('normal', new THREE.Float32BufferAttribute(ns, 3));
        }
        geometry.computeBoundingBox();
        geometry.computeBoundingSphere();
        var texture = null;
        if(data.texture !== undefined) {
            texture = new THREE.DataTexture(data.texture.rawTexture, data.texture.resolution[0], data.texture.resolution[1], THREE.RGBAFormat);
            if((data.texture.options & 1) > 0)
                texture.wrapS = THREE.RepeatWrapping;
            if((data.texture.options & 2) > 0)
                texture.wrapT = THREE.RepeatWrapping;
            if((data.texture.options & 4) > 0)
                texture.magFilter = texture.minFilter = THREE.LinearFilter;
            else
                texture.magFilter = texture.minFilter = THREE.NearestFilter;

            if(false) { // XXX: see above
                geometry.setAttribute('uv', new THREE.Float32BufferAttribute(data.texture.coordinates, 2));
            } else {
                var uvs = [];
                for(var i = 0; i < data.indices.length; i++) {
                    var index = data.indices[i];
                    var uv = data.texture.coordinates.slice(2 * i, 2 * (i + 1));
                    uvs.push(uv[0], uv[1]);
                }
                geometry.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));
            }
        }
        const c = data.color;
        const material = new THREE.MeshPhongMaterial({
            side: data.culling ? THREE.FrontSide : THREE.DoubleSide,
            color:    new THREE.Color(c[0], c[1], c[2]),
            specular: new THREE.Color(c[3], c[4], c[5]),
            emissive: new THREE.Color(c[6], c[7], c[8]),
            map: texture,
            polygonOffset: true,
            polygonOffsetFactor: 0.5,
            polygonOffsetUnits: 0.0,
        });
        if((data.options & 2) > 0) {
            material.wireframe = true;
        }
        if(data.transparency !== undefined && data.transparency > 1e-4) {
            material.transparent = true;
            material.opacity = 1 - data.transparency;
        }
        return new THREE.Mesh(geometry, material);
    }
}

class BaseVisual extends THREE.Group {
    constructor(sceneWrapper, parentObject) {
        super();
        this.userData.type = 'baseVisual';
        this.sceneWrapper = sceneWrapper;
        this.parentObject = parentObject;
    }

    init() {
    }

    clone(recursive) {
        var obj = new this.constructor(this.sceneWrapper, this.parentObject).copy(this, true);
        return obj;
    }

    setLayer(layer) {
        this.userData.layer = layer;
    }
}

class JointVisual extends BaseVisual {
    constructor(sceneWrapper, parentObject) {
        super(sceneWrapper, parentObject);
        this.userData.type = 'jointVisual';
    }

    init() {
        super.init();
        this.fixedGeom;
        this.movingGeom;
    }

    static create(type, sceneWrapper, parentObject) {
        if(type == 'revolute')
            return new JointVisualRevolute(sceneWrapper, parentObject);
        if(type == 'prismatic')
            return new JointVisualPrismatic(sceneWrapper, parentObject);
        if(type == 'spherical')
            return new JointVisualSpherical(sceneWrapper, parentObject);
    }

    get fixedGeom() {
        for(var c of this.children) {
            if(c.userData.type === `${this.userData.type}.fixed`)
                return c;
        }

        var fixedGeom = this.createFixedPart();
        fixedGeom.name = 'Joint fixed part';
        fixedGeom.userData.type = `${this.userData.type}.fixed`;
        fixedGeom.userData.pickThisIdInstead = this.parentObject.id;
        fixedGeom.rotation.x = Math.PI / 2;
        this.add(fixedGeom);
        return fixedGeom;
    }

    get jointFrame() {
        for(var c of this.children) {
            if(c.userData.type === `${this.userData.type}.jointFrame`)
                return c;
        }

        var jointFrame = new THREE.Group();
        jointFrame.userData.type = `${this.userData.type}.jointFrame`;
        this.add(jointFrame);
        return jointFrame;
    }

    get movingGeom() {
        for(var c of this.jointFrame.children) {
            if(c.userData.type === `${this.userData.type}.moving`)
                return c;
        }

        var movingGeom = this.createMovingPart();
        movingGeom.name = 'Joint moving part';
        movingGeom.userData.type = `${this.userData.type}.moving`;
        movingGeom.userData.pickThisIdInstead = this.parentObject.id;
        movingGeom.rotation.x = Math.PI / 2;
        this.jointFrame.add(movingGeom);
        return movingGeom;
    }

    setIntrinsicPose(intrinsicPose) {
        this.jointFrame.position.set(intrinsicPose[0], intrinsicPose[1], intrinsicPose[2]);
        this.jointFrame.quaternion.set(intrinsicPose[3], intrinsicPose[4], intrinsicPose[5], intrinsicPose[6]);
    }

    setLayer(layer) {
        super.setLayer(layer);
        this.fixedGeom.layers.mask = this.parentObject.computedLayer();
        this.movingGeom.layers.mask = this.parentObject.computedLayer();
    }

    setColor(index, color) {
        if(!this.userData.colors)
            this.userData.colors = [[0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]];
        if(index < 0 || index >= this.userData.colors.length)
            return;
        this.userData.colors[index] = color;
        if(index === 0) {
            this.fixedGeom.material.color.setRGB(color[0], color[1], color[2]);
            this.fixedGeom.material.specular.setRGB(color[3], color[4], color[5]);
            this.fixedGeom.material.emissive.setRGB(color[6], color[7], color[8]);
        } else if(index === 1) {
            this.movingGeom.material.color.setRGB(color[0], color[1], color[2]);
            this.movingGeom.material.specular.setRGB(color[3], color[4], color[5]);
            this.movingGeom.material.emissive.setRGB(color[6], color[7], color[8]);
        }
    }

    setDiameter(diameter) {
        this.userData.diameter = diameter;
    }

    setLength(length) {
        this.userData.length = length;
    }
}

class JointVisualRevolute extends JointVisual {
    createFixedPart() {
        var fixedGeom = new THREE.Mesh(
            new THREE.CylinderGeometry(1, 1, 1, 8),
            new THREE.MeshPhongMaterial({}),
        );
        return fixedGeom;
    }

    createMovingPart() {
        var movingGeom = new THREE.Mesh(
            new THREE.CylinderGeometry(1, 1, 1, 8),
            new THREE.MeshPhongMaterial({}),
        );
        return movingGeom;
    }

    setDiameter(diameter) {
        super.setDiameter(diameter);
        const r1 = diameter / 2;
        const r2 = r1 / 2;
        this.fixedGeom.scale.x = r1;
        this.fixedGeom.scale.z = r1;
        this.movingGeom.scale.x = r2;
        this.movingGeom.scale.z = r2;
    }

    setLength(length) {
        super.setLength(length);
        const l1 = length * 1.001;
        const l2 = length * 1.201;
        this.fixedGeom.scale.y = l1;
        this.movingGeom.scale.y = l2;
    }
}

class JointVisualPrismatic extends JointVisual {
    createFixedPart() {
        var fixedGeom = new THREE.Mesh(
            new THREE.BoxGeometry(1, 1, 1),
            new THREE.MeshPhongMaterial({}),
        );
        return fixedGeom;
    }

    createMovingPart() {
        var movingGeom = new THREE.Mesh(
            new THREE.BoxGeometry(1, 1, 1),
            new THREE.MeshPhongMaterial({}),
        );
        return movingGeom;
    }

    setDiameter(diameter) {
        super.setDiameter(diameter);
        const r1 = diameter / 2;
        const r2 = r1 / 2;
        this.fixedGeom.scale.x = 2 * r1;
        this.fixedGeom.scale.z = 2 * r1;
        this.movingGeom.scale.x = 2 * r2;
        this.movingGeom.scale.z = 2 * r2;
    }

    setLength(length) {
        super.setLength(length);
        const l1 = length * 1.001;
        const l2 = length * 1.201;
        this.fixedGeom.scale.y = l1;
        this.movingGeom.scale.y = l2;
    }
}

class JointVisualSpherical extends JointVisual {
    createFixedPart() {
        var fixedGeom = new THREE.Mesh(
            new THREE.SphereGeometry(1, 16, 8),
            new THREE.MeshPhongMaterial({
                side: THREE.BackSide,
            })
        );
        return fixedGeom;
    }

    createMovingPart() {
        var movingGeom = new THREE.Mesh(
            new THREE.SphereGeometry(1, 16, 8),
            new THREE.MeshPhongMaterial({}),
        );
        return movingGeom;
    }

    setDiameter(diameter) {
        super.setDiameter(diameter);
        const r1 = diameter / 2;
        const r2 = r1 / 2;
        this.fixedGeom.scale.x = 2 * r1;
        this.fixedGeom.scale.y = 2 * r1;
        this.fixedGeom.scale.z = 2 * r1;
        this.movingGeom.scale.x = 2.5 * r2;
        this.movingGeom.scale.y = 2.5 * r2;
        this.movingGeom.scale.z = 2.5 * r2;
    }
}

class Joint extends BaseObject {
    constructor(sceneWrapper) {
        super(sceneWrapper);
        this.userData.type = 'joint';
    }

    init() {
        super.init();
        this.jointFrame;
        this.visual;
    }

    get jointFrame() {
        for(var c of this.children) {
            if(c.userData.type === 'jointFrame')
                return c;
        }

        var jointFrame = new THREE.Group();
        jointFrame.userData.type = 'jointFrame';
        this.add(jointFrame);
        return jointFrame;
    }

    get childObjects() {
        return [...this.jointFrame.children].filter((o) => o.userData.parentUid === this.userData.uid);
    }

    get visual() {
        for(var c of this.children) {
            if(c.userData.type === 'jointVisual')
                return c;
        }

        if(this.userData.joint?.type === undefined)
            return;

        var visual = JointVisual.create(this.userData.joint.type, this.sceneWrapper, this);
        visual.init();
        this.add(visual);

        // visuals have been added -> set layer
        this.setLayer(this.userData.layer);
    }

    attach(o) {
        this.jointFrame.attach(o);
    }

    update(eventData) {
        super.update(eventData);
        if(eventData.data.joint !== undefined)
            this.setJoint(eventData.data.joint);
    }

    setLayer(layer) {
        super.setLayer(layer);
        this.visual?.setLayer(layer);
    }

    setJoint(joint) {
        if(this.userData.joint === undefined)
            this.userData.joint = {};
        if(joint.type !== undefined)
            this.setJointType(joint.type);
        if(joint.position !== undefined)
            this.setJointPosition(joint.position);
        if(joint.cyclic !== undefined)
            this.setJointCyclic(joint.cyclic);
        if(joint.min !== undefined)
            this.setJointMin(joint.min);
        if(joint.range !== undefined)
            this.setJointRange(joint.range);
        if(joint.intrinsicPose !== undefined)
            this.setJointIntrinsicPose(joint.intrinsicPose);
        if(joint.color !== undefined)
            this.setJointColor(joint.color);
        if(joint.colors !== undefined)
            this.setJointColors(joint.colors);
        if(joint.diameter !== undefined)
            this.setJointDiameter(joint.diameter);
        if(joint.length !== undefined)
            this.setJointLength(joint.length);
    }

    setJointType(type) {
        // `type` can only be set once
        if(this.userData.joint.type !== undefined)
            return;

        this.userData.joint.type = type;

        // invoke getter now:
        this.visual;
    }

    setJointPosition(position) {
        this.userData.joint.position = position;
    }

    setJointCyclic(cyclic) {
        this.userData.joint.cyclic = cyclic;
    }

    setJointMin(min) {
        this.userData.joint.min = min;
        this.userData.joint.max = this.userData.joint.min + this.userData.joint.range;
    }

    setJointRange(range) {
        this.userData.joint.range = range;
        this.userData.joint.max = this.userData.joint.min + this.userData.joint.range;
    }

    setJointIntrinsicPose(intrinsicPose) {
        this.jointFrame.position.set(intrinsicPose[0], intrinsicPose[1], intrinsicPose[2]);
        this.jointFrame.quaternion.set(intrinsicPose[3], intrinsicPose[4], intrinsicPose[5], intrinsicPose[6]);
        this.visual?.setIntrinsicPose(intrinsicPose);
    }

    setJointColor(color) {
        this.visual?.setColor(color.index, color.color);
    }

    setJointColors(colors) {
        for(var i = 0; i < colors.length; i++)
            this.visual?.setColor(i, colors[i]);
    }

    setJointDiameter(diameter) {
        this.userData.joint.diameter = diameter;
        this.visual?.setDiameter(diameter);
    }

    setJointLength(length) {
        this.userData.joint.length = length;
        this.visual?.setLength(length);
    }
}

class DummyVisual extends BaseVisual {
    constructor(sceneWrapper, parentObject) {
        super(sceneWrapper, parentObject);
        this.userData.type = 'dummyVisual';
    }

    init() {
        super.init();
        this.ballGeom;
        this.axesGeom;
    }

    createBall() {
        var ballGeom = new THREE.Mesh(
            new THREE.SphereGeometry(1, 8, 8),
            new THREE.MeshPhongMaterial({
            })
        );
        return ballGeom;
    }

    createAxes() {
        var axesGeom = new THREE.AxesHelper(4);
        return axesGeom;
    }

    get ballGeom() {
        for(var c of this.children) {
            if(c.userData.type === `${this.userData.type}.ball`)
                return c;
        }

        var ballGeom = this.createBall();
        ballGeom.name = 'Dummy ball';
        ballGeom.userData.type = `${this.userData.type}.ball`;
        ballGeom.userData.pickThisIdInstead = this.parentObject.id;
        this.add(ballGeom);
        return ballGeom;
    }

    get axesGeom() {
        for(var c of this.children) {
            if(c.userData.type === `${this.userData.type}.axes`)
                return c;
        }

        var axesGeom = this.createAxes();
        axesGeom.name = 'Dummy axes';
        axesGeom.userData.type = `${this.userData.type}.axes`;
        axesGeom.userData.pickThisIdInstead = this.parentObject.id;
        this.add(axesGeom);
        return axesGeom;
    }

    setLayer(layer) {
        this.ballGeom.layers.mask = this.parentObject.computedLayer();
        this.axesGeom.layers.mask = this.parentObject.computedLayer();
    }

    setSize(size) {
        const r1 = size / 2;
        this.scale.x = r1;
        this.scale.y = r1;
        this.scale.z = r1;
    }

    setColor(index, color) {
        if(index !== 0) return;
        this.ballGeom.material.color.setRGB(color[0], color[1], color[2]);
        this.ballGeom.material.specular.setRGB(color[3], color[4], color[5]);
        this.ballGeom.material.emissive.setRGB(color[6], color[7], color[8]);
    }
}

class DummyVisualAlt extends DummyVisual {
    constructor(sceneWrapper, parentObject) {
        super(sceneWrapper, parentObject);
    }

    createBall() {
        var ballGeom = new THREE.Group();
        this.sceneWrapper.cameraFacingObjects.push(ballGeom);
        ballGeom.materialBlack = new THREE.MeshPhongMaterial({color: 0x000000});
        ballGeom.material = new THREE.MeshPhongMaterial({color: 0xffff00});
        const I = 4, J = 2;
        for(let i = 0; i < I; i++) {
            for(let j = 0; j < J; j++) {
                let submesh = new THREE.Mesh(
                    new THREE.SphereGeometry(
                        0.9,
                        16, 8,
                        i * 2 * Math.PI / I,
                        2 * Math.PI / I,
                        j * Math.PI / J,
                        Math.PI / J
                    ),
                    (i + j) % 2 == 0 ? ballGeom.material : ballGeom.materialBlack
                );
                ballGeom.add(submesh);
            }
        }
        let submesh = new THREE.Mesh(
            new THREE.SphereGeometry(1, 32, 16),
            new THREE.MeshPhongMaterial({
                color: 0x000000,
                side: THREE.BackSide,
            })
        );
        ballGeom.add(submesh);
        return ballGeom;
    }

    setLayer(layer) {
        super.setLayer(layer);
        this.ballGeom.traverse((o) => {o.layers.mask = this.parentObject.computedLayer()});
    }
}

class Dummy extends BaseObject {
    constructor(sceneWrapper) {
        super(sceneWrapper);
        this.userData.type = 'dummy';
    }

    init() {
        super.init();
        this.visual;
    }

    get visual() {
        for(var c of this.children) {
            if(c.userData.type === 'dummyVisual')
                return c;
        }

        if(settings.dummy.style == 2) {
            var visual = new DummyVisualAlt(sceneWrapper, this);
        } else {
            var visual = new DummyVisual(sceneWrapper, this);
        }
        visual.init();
        visual.setSize(0.01);
        this.add(visual);
        return visual;
    }

    update(eventData) {
        super.update(eventData);
        if(eventData.data.dummy !== undefined)
            this.setDummy(eventData.data.dummy);
    }

    setLayer(layer) {
        super.setLayer(layer);
        this.visual.setLayer(layer);
    }

    setDummy(dummy) {
        if(dummy.size !== undefined)
            this.setDummySize(dummy.size);
        if(dummy.color !== undefined)
            this.setDummyColor(dummy.color);
        if(dummy.colors !== undefined)
            this.setDummyColors(dummy.colors);
    }

    setDummySize(size) {
        this.visual.setSize(size);
    }

    setDummyColor(color) {
        this.visual.setColor(color.index, color.color);
    }

    setDummyColors(colors) {
        for(var i = 0; i < colors.length; i++)
            this.visual.setColor(i, colors[i]);
    }
}

class CameraVisual extends BaseVisual {
    constructor(sceneWrapper, parentObject) {
        super(sceneWrapper, parentObject);
        this.userData.type = 'cameraVisual';
        this.add(
            new THREE.Mesh(
                new THREE.CylinderGeometry(0.025, 0.01, 0.05, 12, 1, true),
                new THREE.MeshPhongMaterial({color: 0x7f7f7f, side: THREE.DoubleSide})
            )
        );
        this.children[0].position.z = 0.025;
        this.children[0].rotation.x = Math.PI / 2;
        this.add(
            new THREE.Mesh(
                new THREE.CylinderGeometry(0.05, 0.05, 0.025, 20, 32),
                new THREE.MeshPhongMaterial({color: 0x7f7f7f})
            )
        );
        this.children[1].position.set(0, 0.065, -0.0125);
        this.children[1].rotation.z = Math.PI / 2;
        this.add(
            new THREE.Mesh(
                new THREE.CylinderGeometry(0.05, 0.05, 0.025, 20, 32),
                new THREE.MeshPhongMaterial({color: 0x7f7f7f})
            )
        );
        this.children[2].position.set(0, 0.065, -0.085);
        this.children[2].rotation.z = Math.PI / 2;
        this.add(
            new THREE.Mesh(
                new THREE.BoxGeometry(0.02, 0.05, 0.1),
                new THREE.MeshPhongMaterial({color: 0xd90000})
            )
        );
        this.children[3].position.z = -0.05;
        this.traverse(o => {o.userData.pickThisIdInstead = this.id});
    }

    clone(recursive) {
        var obj = new this.constructor(this.sceneWrapper, this.parentObject).copy(this, false);
        return obj;
    }

    setLayer(layer) {
        this.traverse((o) => {o.layers.mask = this.parentObject.computedLayer()});
    }

    setColor(index, color) {
        const reverseColorMap = [[3], [0, 1, 2]];
        if(index < 0 || index >= reverseColorMap.length) return;
        for(var childIndex of reverseColorMap[index]) {
            this.children[childIndex].material.color.setRGB(color[0], color[1], color[2]);
            this.children[childIndex].material.specular.setRGB(color[3], color[4], color[5]);
            this.children[childIndex].material.emissive.setRGB(color[6], color[7], color[8]);
        }
    }
}

class Camera extends BaseObject {
    constructor(sceneWrapper) {
        super(sceneWrapper);
        this.userData.type = 'camera';
    }

    init() {
        super.init();
        this.visual;
        this.frustumSegments;
    }

    get visual() {
        for(var c of this.children) {
            if(c.userData.type === 'cameraVisual')
                return c;
        }

        var visual = new CameraVisual(sceneWrapper, this);
        visual.init();
        this.add(visual);
        return visual;
    }

    get frustumSegments() {
        for(var c of this.children) {
            if(c.userData.type === 'frustumSegments')
                return c;
        }

        var frustumSegments = new THREE.LineSegments(
            new THREE.BufferGeometry(),
            new THREE.LineBasicMaterial({color: 0xffffff}),
        );
        frustumSegments.geometry.setAttribute('position', new THREE.BufferAttribute(
            new Float32Array(3 * 4 * 6), 3
        ));
        frustumSegments.userData.type = 'frustumSegments';
        this.add(frustumSegments);
        return frustumSegments;
    }

    update(eventData) {
        super.update(eventData);
        if(eventData.data.camera !== undefined)
            this.setCamera(eventData.data.camera);
    }

    setLayer(layer) {
        super.setLayer(layer);
        this.visual.setLayer(layer);
    }

    setCamera(camera) {
        var aspectRatio = window.innerWidth / window.innerHeight;
        this.userData.aspectRatio = aspectRatio;
        if(camera.perspectiveMode !== undefined)
            this.userData.perspective = camera.perspectiveMode;
        if(camera.viewAngle !== undefined)
            this.userData.fov = camera.viewAngle * 180 / Math.PI;
        if(camera.orthoSize !== undefined) {
            var width = camera.orthoSize;
            var height = camera.orthoSize / aspectRatio;
            this.userData.left = width / 2;
            this.userData.right = -width / 2;
            this.userData.top = height / 2;
            this.userData.bottom = -height / 2;
        }
        if(camera.nearClippingPlane !== undefined)
            this.userData.near = camera.nearClippingPlane;
        if(camera.farClippingPlane !== undefined)
            this.userData.far = camera.farClippingPlane;
        if(camera.color !== undefined)
            this.setCameraColor(camera.color);
        if(camera.colors !== undefined)
            this.setCameraColors(camera.colors);
        if(camera.frustumVectors !== undefined)
            this.setCameraFrustumVectors(camera.frustumVectors);
        if(camera.showFrustum !== undefined)
            this.setCameraFrustumVisibility(camera.showFrustum);
        if(camera.remoteCameraMode !== undefined)
            this.setCameraRemoteCameraMode(camera.remoteCameraMode);

        // XXX: deliver event to initially place the camera
        if(this.name == "DefaultCamera") {
            view.setCameraParams(this);
            view.setCameraPose(this.getAbsolutePose());
        }
    }

    setCameraColor(color) {
        this.visual.setColor(color.index, color.color);
    }

    setCameraColors(colors) {
        for(var i = 0; i < colors.length; i++)
            this.visual.setColor(i, colors[i]);
    }

    setCameraFrustumVectors(frustumVectors) {
        const near = new THREE.Vector3(...frustumVectors.near);
        const far = new THREE.Vector3(...frustumVectors.far);
        const pts = {
            near: [
                new THREE.Vector3(near.x, near.y, near.z),
                new THREE.Vector3(-near.x, near.y, near.z),
                new THREE.Vector3(-near.x, -near.y, near.z),
                new THREE.Vector3(near.x, -near.y, near.z),
            ],
            far: [
                new THREE.Vector3(far.x, far.y, far.z),
                new THREE.Vector3(-far.x, far.y, far.z),
                new THREE.Vector3(-far.x, -far.y, far.z),
                new THREE.Vector3(far.x, -far.y, far.z),
            ],
        };
        const points = [];
        for(var i = 0; i < 4; i++) {
            points.push(pts.near[i]);
            points.push(pts.near[(i + 1) % 4]);
            points.push(pts.far[i]);
            points.push(pts.far[(i + 1) % 4]);
            points.push(pts.near[i]);
            points.push(pts.far[i]);
        }
        for(var i = 0; i < points.length; i++) {
            this.frustumSegments.geometry.attributes.position.array[3 * i + 0] = points[i].x;
            this.frustumSegments.geometry.attributes.position.array[3 * i + 1] = points[i].y;
            this.frustumSegments.geometry.attributes.position.array[3 * i + 2] = points[i].z;
        }
        this.frustumSegments.geometry.attributes.position.needsUpdate = true;
        this.frustumSegments.geometry.computeBoundingBox();
        this.frustumSegments.geometry.computeBoundingSphere();
    }

    setCameraFrustumVisibility(show) {
        this.frustumSegments.visible = show;
    }

    setCameraRemoteCameraMode(mode) {
        // 0=free, 1=slave, 2=master
        this.userData.remoteCameraMode = mode;
    }
}

class Light extends BaseObject {
    constructor(sceneWrapper) {
        super(sceneWrapper);
        this.userData.type = 'light';
    }

    init() {
        super.init();
        this.light;
    }

    get light() {
        for(var c of this.children) {
            if(c.userData.type === 'pointLight')
                return c;
        }

        var light = new THREE.PointLight(0xffffff, 0.1);
        light.castShadow = settings.shadows.enabled;
        light.userData.type = 'pointLight';
        this.add(light);
        return light;
    }

    update(eventData) {
        super.update(eventData);
    }
}

class PointCloud extends BaseObject {
    constructor(sceneWrapper) {
        super(sceneWrapper);
        this.userData.type = 'pointCloud';
    }

    init() {
        super.init();
        this.points;
    }

    get points() {
        for(var c of this.children) {
            if(c.userData.type === 'points')
                return c;
        }

        var points = new THREE.Points(
            new THREE.BufferGeometry(),
            new THREE.PointsMaterial({sizeAttenuation: false, vertexColors: true})
        );
        points.userData.type = 'points';
        points.userData.pickThisIdInstead = this.id;
        this.add(points);
        return points;
    }

    update(eventData) {
        super.update(eventData);
        if(eventData.data.pointCloud !== undefined)
            this.setPointCloud(eventData.data.pointCloud);
    }

    setLayer(layer) {
        super.setLayer(layer);
        this.points.layers.mask = this.computedLayer();
    }

    setPointCloud(pointCloud) {
        if(pointCloud.points !== undefined)
            this.setPointCloudPoints(pointCloud.points);
        if(pointCloud.pointSize !== undefined)
            this.setPointCloudPointSize(pointCloud.pointSize);
    }

    setPointCloudPoints(points) {
        this.points.geometry.setAttribute('position', new THREE.Float32BufferAttribute(points.points, 3));
        this.points.geometry.setAttribute('color', new THREE.Uint8ClampedBufferAttribute(points.colors, 4, true));
        this.points.geometry.computeBoundingBox();
        this.points.geometry.computeBoundingSphere();
    }

    setPointCloudPointSize(pointSize) {
        this.points.material.size = pointSize;
    }
}

class Octree extends BaseObject {
    constructor(sceneWrapper) {
        super(sceneWrapper);
        this.userData.type = 'octree';
    }

    init() {
        super.init();
        this.mesh;
    }

    get mesh() {
        for(var c of this.children) {
            if(c.userData.type === 'octreeMesh')
                return c;
        }

        var mesh = new THREE.InstancedMesh(
            new THREE.BoxGeometry(1, 1, 1),
            new THREE.MeshPhongMaterial({
                color:    new THREE.Color(1, 1, 1),
                //color:    new THREE.Color(c[0], c[1], c[2]),
                //specular: new THREE.Color(c[3], c[4], c[5]),
                //emissive: new THREE.Color(c[6], c[7], c[8]),
            }),
            settings.octree.maxVoxelCount
        );
        mesh.userData.type = 'octreeMesh';
        mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
        mesh.count = 0;
        mesh.instanceColor = new THREE.InstancedBufferAttribute(new Float32Array(3 * settings.octree.maxVoxelCount), 3);
        this.add(mesh);
        return mesh;
    }

    update(eventData) {
        super.update(eventData);
        if(eventData.data.octree !== undefined)
            this.setOctree(eventData.data.octree);
    }

    setLayer(layer) {
        super.setLayer(layer);
        this.mesh.layers.mask = this.computedLayer();
    }

    setOctree(octree) {
        if(octree.voxelSize !== undefined)
            this.setOctreeVoxelSize(octree.voxelSize);
        if(octree.voxels !== undefined)
            this.setOctreeVoxels(octree.voxels);
    }

    setOctreeVoxelSize(voxelSize) {
        this.userData.voxelSize = voxelSize;
    }

    setOctreeVoxels(voxels) {
        const p = voxels.positions, c = voxels.colors, s = this.userData.voxelSize;
        var n = 0;
        for(var i = 0, pi = 0, ci = 0; pi < p.length && ci < c.length; i++, pi += 3, ci += 4) {
            this.mesh.setColorAt(i, new THREE.Color(c[ci] / 255, c[ci + 1] / 255, c[ci + 2] / 255));
            var m = new THREE.Matrix4();
            m.makeScale(s, s, s);
            m.setPosition(p[pi], p[pi + 1], p[pi + 2]);
            this.mesh.setMatrixAt(i, m);
            n++;
        }
        this.mesh.count = n;
        this.mesh.instanceMatrix.needsUpdate = true;
        this.mesh.instanceColor.needsUpdate = true;
    }
}

class ForceSensor extends BaseObject {
    constructor(sceneWrapper) {
        super(sceneWrapper);
        this.userData.type = 'forceSensor';
    }

    init() {
        super.init();
        this.sensorFrame;
    }

    get sensorFrame() {
        for(var c of this.children) {
            if(c.userData.type === 'sensorFrame')
                return c;
        }

        var sensorFrame = new THREE.Group();
        sensorFrame.userData.type = 'sensorFrame';
        this.add(sensorFrame);
        return sensorFrame;
    }

    get childObjects() {
        return [...this.sensorFrame.children].filter((o) => o.userData.parentUid === this.userData.uid);
    }

    attach(o) {
        this.sensorFrame.attach(o);
    }

    update(eventData) {
        super.update(eventData);
        if(eventData.data.forceSensor !== undefined)
            this.setForceSensor(eventData.data.forceSensor);
    }

    setForceSensor(forceSensor) {
        if(forceSensor.intrinsicPose !== undefined)
            this.setForceSensorIntrinsicPose(forceSensor.intrinsicPose);
    }

    setForceSensorIntrinsicPose(intrinsicPose) {
        this.sensorFrame.position.set(intrinsicPose[0], intrinsicPose[1], intrinsicPose[2]);
        this.sensorFrame.quaternion.set(intrinsicPose[3], intrinsicPose[4], intrinsicPose[5], intrinsicPose[6]);
    }
}

class UnknownObject extends BaseObject {
    constructor(sceneWrapper) {
        super(sceneWrapper);
        this.userData.type = 'unknownObject';
    }
}

class TriangleGeometry extends THREE.BufferGeometry {
	constructor(size = 1) {
		super();
		this.type = 'TriangleGeometry';

		this.parameters = {
			size: size,
		};

		const size_half = size / 2;

		const indices = [];
		const vertices = [];
		const normals = [];
		const uvs = [];

		for(let i = 0; i < 3; i++) {
			const w = i * Math.PI * 2 / 3;
            const x = size_half * Math.cos(w);
            const y = size_half * Math.sin(w);
            vertices.push(-x, y, 0);
            normals.push(0, 0, 1);
            uvs.push((x + size_half) / size);
            uvs.push((y + size_half) / size);
		}
        indices.push(0);

		//this.setIndex(indices);
		this.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));
		this.setAttribute('normal', new THREE.Float32BufferAttribute(normals, 3));
		//this.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));
	}

	static fromJSON(data) {
		return new TriangleGeometry(data.size);
	}
}

class DrawingObjectVisualBufferGeometryMixin {
    initGeometry() {
        this.geometry.setAttribute('position', new THREE.Float32BufferAttribute(this.userData.maxItemCount * 3 * this.userData.pointsPerItem, 3));
        this.geometry.setAttribute('color', new THREE.Float32BufferAttribute(this.userData.maxItemCount * 3 * this.userData.pointsPerItem, 3));
        this.clear();
    }

    clear() {
        this.geometry.setDrawRange(0, 0);
    }

    updateGeometry() {
        this.geometry.computeBoundingBox();
        this.geometry.computeBoundingSphere();
    }

    setPoint(index, point, color, quaternion) {
        if(index >= this.userData.maxItemCount) return;

        const ptsPerItem = this.userData.pointsPerItem;

        const positionAttr = this.geometry.getAttribute('position');
        const colorAttr = this.geometry.getAttribute('color');

        for(var i = 0; i < point.length; i++)
            positionAttr.array[ptsPerItem * 3 * index + i] = point[i];
        positionAttr.needsUpdate = true;

        for(var i = 0; i < color.length; i++)
            colorAttr.array[ptsPerItem * 3 * index + i] = color[i];
        colorAttr.needsUpdate = true;

        this.geometry.setDrawRange(0, Math.max(this.geometry.drawRange.count, ptsPerItem * (index + 1)));
    }
}

class DrawingObjectVisualPoint extends THREE.Points {
    constructor(maxItemCount, size) {
        super(
            new THREE.BufferGeometry(),
            new THREE.PointsMaterial({size: 0.01 * size, vertexColors: true})
        );
        this.userData.itemType = 'point';
        this.userData.maxItemCount = maxItemCount;
        this.userData.size = size;
        this.userData.pointsPerItem = 1;
        this.initGeometry();
    }

    setSize(size) {
        this.userData.size = size;
        this.material.size = 0.01 * size;
    }
}

mixin(DrawingObjectVisualPoint, DrawingObjectVisualBufferGeometryMixin);

class DrawingObjectVisualLine extends THREE.LineSegments {
    constructor(maxItemCount, size) {
        super(
            new THREE.BufferGeometry(),
            new THREE.LineBasicMaterial({linewidth: 10 * size, vertexColors: true})
        );
        this.userData.itemType = 'line';
        this.userData.maxItemCount = maxItemCount;
        this.userData.size = size;
        this.userData.pointsPerItem = 2;
        this.initGeometry();
    }

    setSize(size) {
        this.userData.size = size;
        this.material.linewidth = 10 * size;
    }
}

mixin(DrawingObjectVisualLine, DrawingObjectVisualBufferGeometryMixin);

class DrawingObjectVisualLineStrip extends THREE.Line {
    constructor(maxItemCount, size) {
        super(
            new THREE.BufferGeometry(),
            new THREE.LineBasicMaterial({linewidth: 10 * size, vertexColors: true})
        );
        this.userData.itemType = 'lineStrip';
        this.userData.maxItemCount = maxItemCount;
        this.userData.size = size;
        this.userData.pointsPerItem = 1;
        this.initGeometry();
    }

    setSize(size) {
        this.userData.size = size;
        this.material.linewidth = 10 * size;
    }
}

mixin(DrawingObjectVisualLineStrip, DrawingObjectVisualBufferGeometryMixin);

class DrawingObjectVisualInstancedMesh extends THREE.InstancedMesh {
    constructor(geometry, material, maxItemCount, size) {
        super(geometry, material, maxItemCount);
        this.userData.maxItemCount = maxItemCount;
        this.userData.size = size;
    }

    setSize(size) {
        this.userData.size = size;
        this.material.linewidth = 10 * size;
    }

    clear() {
        this.count = 0;
    }

    updateGeometry() {
        this.instanceMatrix.needsUpdate = true;
        if(this.instanceColor)
            this.instanceColor.needsUpdate = true;
    }

    setPoint(index, point, color, quaternion) {
        if(index >= this.userData.maxItemCount) return;

        var p = new THREE.Vector3(...point);
        var q = new THREE.Quaternion(...quaternion);
        var s = new THREE.Vector3(1, 1, 1);
        var m = new THREE.Matrix4();
        m.compose(p, q, s);
        this.setMatrixAt(index, m);
        this.instanceMatrix.needsUpdate = true;

        var c = new THREE.Color(...color);
        this.setColorAt(index, c);
        this.instanceColor.needsUpdate = true;

        if(this.count <= index)
            this.count = index + 1;
    }
}

class DrawingObjectVisualCubePoint extends DrawingObjectVisualInstancedMesh {
    constructor(maxItemCount, size) {
        super(
            new THREE.BoxGeometry(size, size, size),
            new THREE.MeshPhongMaterial({
                color: new THREE.Color(1, 1, 1),
            }),
            maxItemCount,
            size
        );
        this.userData.itemType = 'cubePoint';
    }
}

class DrawingObjectVisualDiscPoint extends DrawingObjectVisualInstancedMesh {
    constructor(maxItemCount, size) {
        super(
            new THREE.CircleGeometry(size, 16),
            new THREE.MeshPhongMaterial({
                color: new THREE.Color(1, 1, 1),
                side: THREE.DoubleSide,
            }),
            maxItemCount
        );
        this.userData.itemType = 'discPoint';
    }
}

class DrawingObjectVisualSpherePoint extends DrawingObjectVisualInstancedMesh {
    constructor(maxItemCount, size) {
        super(
            new THREE.SphereGeometry(size, 16, 8),
            new THREE.MeshPhongMaterial({
                color: new THREE.Color(1, 1, 1),
            }),
            maxItemCount
        );
        this.userData.itemType = 'spherePoint';
    }
}

class DrawingObjectVisualQuadPoint extends DrawingObjectVisualInstancedMesh {
    constructor(maxItemCount, size) {
        super(
            new THREE.PlaneGeometry(size, size),
            new THREE.MeshPhongMaterial({
                color: new THREE.Color(1, 1, 1),
                side: THREE.DoubleSide,
            }),
            maxItemCount
        );
        this.userData.itemType = 'quadPoint';
    }
}

class DrawingObjectVisualTrianglePoint extends DrawingObjectVisualInstancedMesh {
    constructor(maxItemCount, size) {
        super(
            new TriangleGeometry(size),
            new THREE.MeshPhongMaterial({
                color: new THREE.Color(1, 1, 1),
                side: THREE.DoubleSide,
            }),
            maxItemCount
        );
        this.userData.itemType = 'trianglePoint';
    }
}

class DrawingObjectVisualTriangle extends THREE.Mesh {
    constructor(maxItemCount, size) {
        super(
            new THREE.BufferGeometry(),
            new THREE.MeshPhongMaterial({
                side: THREE.DoubleSide,
                vertexColors: true,
            }),
        );
        this.userData.itemType = 'triangle';
        this.userData.maxItemCount = maxItemCount;
        this.userData.size = size;
        this.userData.pointsPerItem = 3;
        this.initGeometry();
    }
}

mixin(DrawingObjectVisualTriangle, DrawingObjectVisualBufferGeometryMixin);

class DrawingObject extends THREE.Group {
    static objectsByUid = {};

    static getObjectByUid(uid) {
        return this.objectsByUid[uid];
    }

    constructor(sceneWrapper) {
        super();
        this.name = 'drawingObject';
        this.sceneWrapper = sceneWrapper;
        this.userData.type = 'drawingObject';
    }

    get object() {
        for(var c of this.children) {
            if(c.userData.type === 'drawingObjectVisual')
                return c;
        }

        if(this.userData.itemType === undefined)
            return;

        if(this.userData.itemType == 'point') {
            var object = new DrawingObjectVisualPoint(this.userData.maxItemCount, this.userData.size);
        } else if(this.userData.itemType == 'line') {
            var object = new DrawingObjectVisualLine(this.userData.maxItemCount, this.userData.size);
        } else if(this.userData.itemType == 'lineStrip') {
            var object = new DrawingObjectVisualLineStrip(this.userData.maxItemCount, this.userData.size);
        } else if(this.userData.itemType == 'cubePoint') {
            var object = new DrawingObjectVisualCubePoint(this.userData.maxItemCount, this.userData.size);
        } else if(this.userData.itemType == 'discPoint') {
            var object = new DrawingObjectVisualDiscPoint(this.userData.maxItemCount, this.userData.size);
        } else if(this.userData.itemType == 'spherePoint') {
            var object = new DrawingObjectVisualSpherePoint(this.userData.maxItemCount, this.userData.size);
        } else if(this.userData.itemType == 'quadPoint') {
            var object = new DrawingObjectVisualQuadPoint(this.userData.maxItemCount, this.userData.size);
        } else if(this.userData.itemType == 'trianglePoint') {
            var object = new DrawingObjectVisualTrianglePoint(this.userData.maxItemCount, this.userData.size);
        } else if(this.userData.itemType == 'triangle') {
            var object = new DrawingObjectVisualTriangle(this.userData.maxItemCount, this.userData.size);
        } else {
            throw `Drawing object of type "${this.userData.itemType}" is not supported`;
        }
        object.name = 'drawingObjectVisual';
        object.userData.type = 'drawingObjectVisual';
        this.add(object);
        return object;
    }

    clone(recursive) {
        var obj = new this.constructor(this.sceneWrapper).copy(this, recursive);
        return obj;
    }

    update(eventData) {
        if(eventData.uid !== undefined)
            this.setUid(eventData.uid);
        if(eventData.data === undefined)
            return;
        if(eventData.data.maxCnt !== undefined)
            this.setMaxItemCount(eventData.data.maxCnt);
        if(eventData.data.size !== undefined)
            this.setSize(eventData.data.size);
        if(eventData.data.parentUid !== undefined)
            this.setParent(eventData.data.parentUid);
        if(eventData.data.color !== undefined)
            this.setColor(eventData.data.color);
        if(eventData.data.cyclic !== undefined)
            this.setCyclic(eventData.data.cyclic);
        if(eventData.data.type !== undefined)
            this.setItemType(eventData.data.type);
        if(eventData.data.points !== undefined || eventData.data.clearPoints === true)
            this.setPoints(
                eventData.data.points || [],
                eventData.data.colors || [],
                eventData.data.quaternions || [],
                !!eventData.data.clearPoints
            );
    }

    setItemType(itemType) {
        if(this.userData.itemType !== undefined)
            return;

        if(this.userData.maxItemCount === undefined)
            throw "maxItemCount must be set before calling setItemType()";

        if(this.userData.size === undefined)
            throw "size must be set before calling setItemType()";

        this.userData.itemType = itemType;

        // invoke getter now:
        this.object;
    }

    pointsPerItem() {
        if(this.userData.itemType == 'line')
            return 2;
        if(this.userData.itemType == 'triangle')
            return 3;
        return 1;
    }

    setUid(uid) {
        if(this.userData.uid !== undefined)
            return;
        this.userData.uid = uid;
        DrawingObject.objectsByUid[uid] = this;
    }

    setParent(parentUid) {
        this.userData.parentUid = parentUid;
        var parentObj = BaseObject.getObjectByUid(parentUid);
        if(parentObj !== undefined) {
            var p = this.position.clone();
            var q = this.quaternion.clone();
            parentObj.attach(this);
            this.position.copy(p);
            this.quaternion.copy(q);
        } else /*if(parentUid === -1)*/ {
            if(parentUid !== -1)
                console.error(`Parent with uid=${parentUid} is not known`);
            this.sceneWrapper.scene.attach(this);
        }
    }

    setColor(color) {
        this.userData.color = color;
    }

    setCyclic(cyclic) {
        this.userData.cyclic = cyclic;
    }

    setMaxItemCount(maxItemCount) {
        if(maxItemCount <= 0) {
            const defaultMaxItemCount = 10000;
            console.warn(`DrawingObject: maxItemCount=${maxItemCount} is not valid. Changing to ${defaultMaxItemCount}.`);
            maxItemCount = defaultMaxItemCount;
        }

        this.userData.maxItemCount = maxItemCount;
        this.userData.writeIndex = 0;
    }

    setSize(size) {
        this.userData.size = size;
    }

    setPoints(points, colors, quaternions, clear) {
        if(clear) {
            this.object.clear();
            this.userData.writeIndex = 0;
        }

        const itemLen = this.pointsPerItem() * 3;

        if(points.length % itemLen > 0)
            throw `Points data size is not a multiple of ${itemLen}`;

        const n = points.length / itemLen;

        if(colors.length != points.length)
            throw `Colors data size does not match points data siize`;

        for(var j = 0; j < n; j++) {
            this.object.setPoint(
                this.userData.writeIndex,
                points.slice(j * itemLen, (j + 1) * itemLen),
                colors.slice(j * itemLen, (j + 1) * itemLen),
                quaternions.slice(j * 4, (j + 1) * 4)
            );

            this.userData.writeIndex++;
            if(this.userData.cyclic)
                this.userData.writeIndex = this.userData.writeIndex % this.userData.maxItemCount;
            else
                this.userData.writeIndex = Math.min(this.userData.maxItemCount, this.userData.writeIndex);
        }

        this.object.updateGeometry();
    }
}

class BoxHelper extends THREE.LineSegments {
    constructor(color = 0xffffff) {
        const geometry = new THREE.BufferGeometry();
        geometry.setAttribute('position', new THREE.BufferAttribute(new Float32Array(24 * 3), 3));
        super(geometry, new THREE.LineDashedMaterial({
            color: color,
            toneMapped: false,
            dashSize: 0.005,
            gapSize: 0.005,
        }));
        this.type = 'BoxHelper';
        this.matrixAutoUpdate = false;
        this.box = new THREE.Mesh(
            new THREE.BoxGeometry(1, 1, 1),
            new THREE.MeshBasicMaterial({
                color: 0xffffff,
                transparent: true,
                opacity: 0.1,
                side: THREE.BackSide,
                depthWrite: false,
            }),
        );
        this.add(this.box);
        this.blinkInterval = null;
    }

    setFromObject(object) {
        if(this.blinkInterval !== null) {
            clearInterval(this.blinkInterval);
            this.blinkInterval = null;
        }
        if(object === null)
            return;
        var bb = [[Infinity, Infinity, Infinity], [-Infinity, -Infinity, -Infinity]];
        var modelBaseMatrixWorldInverse = new THREE.Matrix4(); // identity
        if(object && settings.selection.style.boundingBoxLocal) {
            object.updateMatrixWorld();
            modelBaseMatrixWorldInverse = object.matrixWorld.clone().invert();
        }
        for(var o of object.boundingBoxObjects) {
            if(o.userData.boundingBox === undefined)
                continue;
            o.updateMatrixWorld();
            const objBB = [o.userData.boundingBox.min, o.userData.boundingBox.max];
            for(var i = 0; i < 2; i++) {
                for(var j = 0; j < 2; j++) {
                    for(var k = 0; k < 2; k++) {
                        var v = new THREE.Vector3(objBB[i][0], objBB[j][1], objBB[k][2]);
                        v = o.localToWorld(v);
                        v.applyMatrix4(modelBaseMatrixWorldInverse);
                        var a = v.toArray();
                        for(var h = 0; h < 3; h++) {
                            bb[0][h] = Math.min(bb[0][h], a[h]);
                            bb[1][h] = Math.max(bb[1][h], a[h]);
                        }
                    }
                }
            }
        }

        // grow bbox for better visibility:
        const kGrow = 1.1;
        for(var i = 0; i < 3; i++) {
            var mean = (bb[1][i] + bb[0][i]) / 2;
            var halfRange = (bb[1][i] - bb[0][i]) / 2;
            bb[0][i] = mean - halfRange * kGrow;
            bb[1][i] = mean + halfRange * kGrow;
        }

        if(object.userData.modelBase) {
            this.box.visible = settings.selection.style.boundingBoxModelSolidOpacity > 0.01;
            this.box.material.opacity = settings.selection.style.boundingBoxModelSolidOpacity;
            this.box.material.side = settings.selection.style.boundingBoxModelSolidSide;
        } else {
            this.box.visible = settings.selection.style.boundingBoxSolidOpacity > 0.01;
            this.box.material.opacity = settings.selection.style.boundingBoxSolidOpacity;
            this.box.material.side = settings.selection.style.boundingBoxSolidSide;
        }
        const dash = settings.selection.style.boundingBoxModelDashed;
        this.material.dashSize = dash && object.userData.modelBase ? 0.005 : 1000;
        this.material.gapSize = dash && object.userData.modelBase ? 0.005 : 0;
        if(settings.selection.style.boundingBoxLocal)
            this.matrix.copy(object.matrixWorld);
        else
            this.matrix.copy(new THREE.Matrix4());
        const idxMinMax = [1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0];
        var p = [];
        for(var j = 0; j < idxMinMax.length; j++)
            p.push(bb[idxMinMax[j]][j % 3]);
        var k = 0;
        for(var idxPt of [0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7]) {
            for(var j = 0; j < 3; j++)
                this.geometry.attributes.position.array[k++] = p[idxPt * 3 + j];
        }
        this.geometry.attributes.position.needsUpdate = true;
        this.geometry.computeBoundingSphere();
        this.computeLineDistances();
        this.box.position.set(
            (bb[1][0] + bb[0][0]) / 2,
            (bb[1][1] + bb[0][1]) / 2,
            (bb[1][2] + bb[0][2]) / 2
        );
        this.box.scale.set(
            bb[1][0] - bb[0][0],
            bb[1][1] - bb[0][1],
            bb[1][2] - bb[0][2]
        );
        this.material.visible = true;
        if(settings.selection.style.boundingBoxBlinkInterval > 0) {
            setInterval(() => {
                this.material.visible = !this.material.visible;
                render();
            }, settings.selection.style.boundingBoxBlinkInterval);
        }
    }

    copy(source) {
        LineSegments.prototype.copy.call( this, source );
        //this.object = source.object;
        return this;
    }
}

class SceneWrapper {
    constructor() {
        this.scene = new THREE.Scene();

        const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
        this.scene.add(ambientLight);

        this.raycaster = new THREE.Raycaster();

        this.cameraFacingObjects = [];
    }

    clear() {
        for(var uid in BaseObject.objectsByUid) {
            BaseObject.objectsByUid[uid].removeFromParent();
            delete BaseObject.objectsByUid[uid];
        }
        for(var uid in DrawingObject.objectsByUid) {
            DrawingObject.objectsByUid[uid].removeFromParent();
            delete DrawingObject.objectsByUid[uid];
        }
    }

    addObject(data) {
        var obj = null;
        if(data.data.shape !== undefined) {
            obj = new Shape(this);
        } else if(data.data.joint !== undefined) {
            obj = new Joint(this);
        } else if(data.data.dummy !== undefined) {
            obj = new Dummy(this);
        } else if(data.data.camera !== undefined) {
            obj = new Camera(this);
        } else if(data.data.light !== undefined) {
            obj = new Light(this);
        } else if(data.data.pointCloud !== undefined) {
            obj = new PointCloud(this);
        } else if(data.data.octree !== undefined) {
            obj = new Octree(this);
        } else if(data.data.forceSensor !== undefined) {
            obj = new ForceSensor(this);
        } else {
            obj = new UnknownObject(this);
        }
        obj.init();
        this.scene.add(obj);
        obj.update(data);
    }

    getObjectByUid(uid) {
        return BaseObject.getObjectByUid(uid);
    }

    removeObject(obj) {
        obj.removeFromParent();
        delete BaseObject.objectsByUid[obj.userData.uid];
    }

    addDrawingObject(data) {
        var obj = new DrawingObject(this);
        this.scene.add(obj);
        obj.update(data);
    }

    removeDrawingObject(obj) {
        obj.removeFromParent();
        delete DrawingObject.objectsByUid[obj.userData.uid];
    }

    setSceneData(eventData) {
        if(eventData.data.sceneUid !== undefined)
            this.setSceneUid(eventData.data.sceneUid);
        if(eventData.data.visibilityLayers !== undefined)
            this.setSceneVisibilityLayers(eventData.data.visibilityLayers);
    }

    setSceneUid(uid) {
        this.scene.userData.uid = uid;
        // change in scene uid means scene was switched -> clear
        this.clear();
    }

    setSceneVisibilityLayers(visibilityLayers) {
        this.scene.userData.visibilityLayers = visibilityLayers;
    }

    isObjectPickable(obj) {
        if(obj.visible === false)
            return null;
        if(obj.userData.clickInvisible === true)
            return null;
        if(obj.userData.pickThisIdInstead !== undefined) {
            var otherObj = this.scene.getObjectById(obj.userData.pickThisIdInstead);
            if(otherObj === undefined) {
                console.error(`Object uid=${obj.userData.uid}/id=${obj.id} has pickThisIdInstead=${obj.userData.pickThisIdInstead} which doesn't exist`);
                return null;
            }
            return this.isObjectPickable(otherObj);
        } else if(obj.userData.uid !== undefined) {
            return obj;
        }
        return null;
    }

    pickObject(camera, mousePos, cond) {
        if(mousePos.x < -1 || mousePos.x > 1 || mousePos.y < -1 || mousePos.y > 1) {
            throw 'SceneWrapper.pickObject: x and y must be in normalized device coordinates (-1...+1)';
        }
        this.raycaster.layers.mask = camera.layers.mask;
        this.raycaster.setFromCamera(mousePos, camera);
        const intersects = this.raycaster.intersectObjects(this.scene.children, true);
        for(let i = 0; i < intersects.length; i++) {
            var x = intersects[i];
            // XXX: discard some specific types:
            if(['Line', 'LineSegments', 'AxesHelper', 'BoxHelper'].includes(x.object.type))
                continue;
            if(x.object instanceof DrawingObject)
                continue;
            // XXX end
            var obj = this.isObjectPickable(x.object);
            if(obj !== null && (cond === undefined || cond(obj))) {
                return {
                    distance: x.distance,
                    point: x.point,
                    face: x.face,
                    faceIndex: x.faceIndex,
                    object: obj,
                    originalObject: x.object
                };
            }
        }
        return null;
    }

    findModelBase(obj, followSMBI) {
        if(obj === null) return null;
        if(obj.userData.modelBase) {
            if(obj.userData.selectModelBase) {
                var obj1 = this.findModelBase(obj.parent);
                if(obj1 !== null) return obj1;
            }
            return obj;
        } else {
            return this.findModelBase(obj.parent);
        }
    }
}

mixin(SceneWrapper, EventSourceMixin);

function qRot(q, axis, angle) {
    var m = new THREE.Matrix4();
    m.makeRotationAxis(new THREE.Vector3(...axis), angle);
    var qflip = new THREE.Quaternion();
    qflip.setFromRotationMatrix(m);
    var q_ = new THREE.Quaternion(...q);
    q_.multiply(qflip);
    return q_.toArray();
}

class View {
    constructor(viewCanvas, sceneWrapper) {
        this.viewCanvas = viewCanvas
        this.sceneWrapper = sceneWrapper;
        this.renderer = new THREE.WebGLRenderer({canvas: this.viewCanvas, alpha: true});
        this.renderer.shadowMap.enabled = settings.shadows.enabled;
        this.renderer.setPixelRatio(window.devicePixelRatio);
        this.renderer.setSize(window.innerWidth, window.innerHeight);

        this.renderRequested = false;

        this.perspectiveCamera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 1000);
        this.perspectiveCamera.name = 'User camera';
        this.perspectiveCamera.userData.type = 'camera';
        this.perspectiveCamera.position.set(1.12, -1.9, 1.08);
        this.perspectiveCamera.rotation.set(1.08, 0.64, 0.31);
        this.perspectiveCamera.layers.mask = 255;

        this.orthographicCamera = new THREE.OrthographicCamera(window.innerWidth / - 2, window.innerWidth / 2, window.innerHeight / 2, window.innerHeight / - 2, 1, 1000);
        this.orthographicCamera.name = 'User camera';
        this.orthographicCamera.userData.type = 'camera';
        this.orthographicCamera.position.set(1.12, -1.9, 1.08);
        this.orthographicCamera.rotation.set(1.08, 0.64, 0.31);
        this.orthographicCamera.layers.mask = 255;

        this.selectedCamera = this.perspectiveCamera;

        this.bboxNeedsUpdating = false;
        this.bboxHelper = new BoxHelper(0xffffff);
        this.bboxHelper.visible = false;
        this.sceneWrapper.scene.add(this.bboxHelper);

        this.selectedObject = null;

        this.mouse = {
            dragStart: {x: 0, y: 0},
            dragDistance: (event) => {
                return Math.hypot(
                    this.mouse.pos.x - this.mouse.dragStart.x,
                    this.mouse.pos.y - this.mouse.dragStart.y
                );
            },
            pos: {x: 0, y: 0},
            normPos: {x: 0, y: 0},
            clickDragTolerance: 1
        };

        this.viewCanvas.addEventListener('mousedown', (e) => {this.onMouseDown(e);}, false);
        this.viewCanvas.addEventListener('mouseup', (e) => {this.onMouseUp(e);}, false);
        this.viewCanvas.addEventListener('mousemove', (e) => {this.onMouseMove(e);}, false);

        this.composer = new THREE.EffectComposer(this.renderer);

        this.renderPass = new THREE.RenderPass(this.sceneWrapper.scene, this.selectedCamera);
        this.composer.addPass(this.renderPass);

        this.outlinePass = new THREE.OutlinePass(new THREE.Vector2(window.innerWidth, window.innerHeight), this.sceneWrapper.scene, this.selectedCamera);
        this.outlinePass.visibleEdgeColor.set(0x0000ff);
        this.outlinePass.hiddenEdgeColor.set(0x0000ff);
        this.outlinePass.edgeGlow = 0;
        this.outlinePass.edgeThickness = 1;
        this.outlinePass.edgeStrength = 5;
        this.outlinePass.pulsePeriod = 0;
        this.composer.addPass(this.outlinePass);

        window.addEventListener('resize', () => {
            for(var camera of [this.perspectiveCamera, this.orthographicCamera]) {
                camera.aspect = window.innerWidth / window.innerHeight;
                camera.updateProjectionMatrix();
            }
        });

        window.addEventListener('resize', () => {
            var w = window.innerWidth;
            var h = window.innerHeight;
            this.renderer.setSize(w, h);
            this.composer.setSize(w, h);
            this.requestRender();
        });
    }

    setCameraParams(camera) {
        if(camera.userData.near !== undefined && camera.userData.far !== undefined) {
            this.orthographicCamera.near = camera.userData.near;
            this.orthographicCamera.far = camera.userData.far;
            this.orthographicCamera.needsProjectionMatrixUpdate = true;
            this.perspectiveCamera.near = camera.userData.near;
            this.perspectiveCamera.far = camera.userData.far;
            this.perspectiveCamera.needsProjectionMatrixUpdate = true;
        }
        if(camera.userData.left !== undefined && camera.userData.right !== undefined && camera.userData.top !== undefined && camera.userData.bottom !== undefined) {
            this.orthographicCamera.left = camera.userData.left;
            this.orthographicCamera.right = camera.userData.right;
            this.orthographicCamera.top = camera.userData.top;
            this.orthographicCamera.bottom = camera.userData.bottom;
            this.orthographicCamera.needsProjectionMatrixUpdate = true;
        }
        if(camera.userData.fov !== undefined && camera.userData.aspectRatio !== undefined) {
            this.perspectiveCamera.fov = camera.userData.fov;
            this.perspectiveCamera.aspect = camera.userData.aspectRatio;
            this.perspectiveCamera.needsProjectionMatrixUpdate = true;
        }
        this.selectedCamera = camera.userData.perspective ? this.perspectiveCamera : this.orthographicCamera;
        this.renderPass.camera = this.selectedCamera;
        this.outlinePass.renderCamera = this.selectedCamera;

        if(this.orthographicCamera.needsProjectionMatrixUpdate) {
            delete this.orthographicCamera.needsProjectionMatrixUpdate;
            this.orthographicCamera.updateProjectionMatrix();
        }
        if(this.perspectiveCamera.needsProjectionMatrixUpdate) {
            delete this.perspectiveCamera.needsProjectionMatrixUpdate;
            this.perspectiveCamera.updateProjectionMatrix();
        }

        this.dispatchEvent('selectedCameraChanged', {});
    }

    getCameraPose() {
        return [
            ...this.selectedCamera.position.toArray(),
            ...qRot(this.selectedCamera.quaternion.toArray(), [0, 1, 0], -Math.PI),
        ];
    }

    setCameraPose(pose) {
        this.dispatchEvent('cameraPoseChanging', {oldPose: this.getCameraPose(), newPose: pose});

        this.perspectiveCamera.position.set(pose[0], pose[1], pose[2]);
        //this.perspectiveCamera.quaternion.set(pose[3], pose[4], pose[5], pose[6]);
        // XXX: three.js's camera looks down its local negative-Z axis, which is opposite to coppeliaSim
        //      so we need to flip, by rotating 180 deg around Y
        this.perspectiveCamera.quaternion.set(...qRot([pose[3], pose[4], pose[5], pose[6]], [0, 1, 0], Math.PI));

        this.orthographicCamera.position.set(pose[0], pose[1], pose[2]);
        this.orthographicCamera.quaternion.set(pose[3], pose[4], pose[5], pose[6]);

        this.dispatchEvent('cameraPoseChanged', {});
    }

    fitCameraToSelection(selection, camera, controls, fitOffset = 1.2) {
        const box = new THREE.Box3();
        for(const object of selection) box.expandByObject(object);
        const size = box.getSize(new THREE.Vector3());
        const center = box.getCenter(new THREE.Vector3());
        const maxSize = Math.max(size.x, size.y, size.z);
        if(maxSize < 0.01) {
            window.alert('Nothing to show!');
            return;
        }
        const fitHeightDistance = maxSize / (2 * Math.atan(Math.PI * camera.fov / 360));
        const fitWidthDistance = fitHeightDistance / camera.aspect;
        const distance = fitOffset * Math.max(fitHeightDistance, fitWidthDistance);
        const direction = controls.target.clone()
            .sub(camera.position)
            .normalize()
            .multiplyScalar(distance);

        //controls.maxDistance = distance * 10;
        controls.target.copy(center);

        //camera.near = distance / 100;
        //camera.far = distance * 100;
        camera.updateProjectionMatrix();

        camera.position.copy(controls.target).sub(direction);

        controls.update();
    }

    setSelectedObject(obj, followSMBI) {
        if(obj === undefined) obj = null;

        var previous = this.selectedObject;

        if(previous !== null && settings.selection.style.edges) {
            for(var o of previous.boundingBoxObjects)
                if(o.userData.type == 'shape')
                    o.setEdgesColor(null);
        }

        if(obj == null) {
            this.bboxHelper.visible = false;
            this.selectedObject = null;
        } else if(obj.userData.selectable !== false) {
            if(followSMBI && obj.userData.selectModelBase) {
                var modelBase = sceneWrapper.findModelBase(obj);
                if(modelBase !== null)
                    obj = modelBase;
            }

            debug(`id=${obj.id}, uid=${obj.userData.uid}, path=${obj.path}`);
            this.selectedObject = obj;
            this.requestBoundingBoxUpdate();
            this.bboxHelper.visible = settings.selection.style.boundingBox;
            this.bboxHelper.renderOrder = settings.selection.style.boundingBoxOnTop ? 1000 : 0;
            this.bboxHelper.material.depthTest = !settings.selection.style.boundingBoxOnTop;
        }

        var current = this.selectedObject;
        this.dispatchEvent('selectedObjectChanged', {previous, current});

        if(settings.selection.style.outline)
            this.outlinePass.selectedObjects = this.selectedObject === null ? [] : [this.selectedObject];

        if(current !== null && settings.selection.style.edges) {
            for(var o of current.boundingBoxObjects)
                if(o.userData.type == 'shape')
                    o.setEdgesColor(settings.selection.style.edgesColor);
        }
    }

    isPartOfSelection(obj) {
        if(this.selectedObject === null) return false;
        if(this.selectedObject === obj) return true;
        return obj.parent === null ? false : this.isPartOfSelection(obj.parent);
    }

    requestBoundingBoxUpdate() {
        this.bboxNeedsUpdating = true;
        this.requestRender();
    }

    updateBoundingBoxIfNeeded() {
        if(this.bboxNeedsUpdating) {
            this.bboxNeedsUpdating = false;
            this.bboxHelper.setFromObject(this.selectedObject);
        }
    }

    readMousePos(event) {
        this.mouse.pos.x = event.clientX;
        this.mouse.pos.y = event.clientY;
        this.mouse.normPos.x = (event.clientX / window.innerWidth) * 2 - 1;
        this.mouse.normPos.y = -(event.clientY / window.innerHeight) * 2 + 1;
    }

    onMouseDown(event) {
        this.readMousePos(event);
        this.mouse.dragStart.x = event.clientX;
        this.mouse.dragStart.y = event.clientY;
    }

    onMouseUp(event) {
        this.readMousePos(event);
        if(this.mouse.dragDistance() <= this.mouse.clickDragTolerance)
            this.onClick(event);
    }

    onClick(event) {
        var pick = this.sceneWrapper.pickObject(this.selectedCamera, this.mouse.normPos, (o) => o.userData.selectable !== false);
        view.setSelectedObject(pick === null ? null : pick.object, true);
    }

    onMouseMove(event) {
        this.readMousePos(event);
    }

    requestRender() {
        this.renderRequested = true;
    }

    render() {
        if(!this.renderRequested) return;
        this.renderRequested = false;

        this.updateBoundingBoxIfNeeded();

        // orient camera-facing objects:
        for(var o of this.sceneWrapper.cameraFacingObjects)
            o.lookAt(this.selectedCamera.position);

        if(settings.selection.style.outline)
            this.composer.render();
        else
            this.renderer.render(this.sceneWrapper.scene, this.selectedCamera);
    }
}

mixin(View, EventSourceMixin);

class AxesView {
    constructor(axesCanvas, upVector) {
        this.axesScene = new THREE.Scene();
        this.axesHelper = new THREE.AxesHelper(20);
        this.axesScene.add(this.axesHelper);
        this.axesRenderer = new THREE.WebGLRenderer({canvas: axesCanvas, alpha: true});
        this.axesRenderer.setPixelRatio(window.devicePixelRatio);
        this.axesRenderer.setSize(80, 80);
        this.renderRequested = false;
        this.axesCamera = new THREE.PerspectiveCamera(40, axesCanvas.width / axesCanvas.height, 1, 1000);
        this.axesCamera.up = upVector;
        this.axesScene.add(this.axesCamera);
    }

    requestRender() {
        this.renderRequested = true;
    }

    render(cameraPosition, targetPosition) {
        if(!this.renderRequested) return;
        this.renderRequested = false;

        this.axesCamera.position.subVectors(cameraPosition, targetPosition);
        this.axesCamera.position.setLength(50);
        this.axesCamera.lookAt(this.axesScene.position);
        this.axesRenderer.render(this.axesScene, this.axesCamera);
    }
}

class OrbitControlsWrapper {
    constructor(camera, renderer) {
        this.orbitControls = new THREE.OrbitControls(camera, renderer.domElement);
    }
}

class TransformControlsWrapper {
    constructor(sceneWrapper, camera, renderer) {
        this.sceneWrapper = sceneWrapper;
        this.transformControls = new THREE.TransformControls(camera, renderer.domElement);
        this.transformControls.enabled = false;
        this.transformControls.addEventListener('dragging-changed', (event) => {
            if(event.value) this.onStartTransform();
            else this.onEndTransform();
        });
        this.sceneWrapper.scene.add(this.transformControls);

        this._sendTransformInterval = null;
    }

    enable() {
        this.transformControls.enabled = true;
    }

    disable() {
        this.transformControls.enabled = false;
    }

    setMode(mode) {
        this.transformControls.setMode(mode);
    }

    setSpace(space) {
        this.transformControls.setSpace(space);
    }

    setOpacityRecursive(obj, value) {
        obj.traverse((o) => {
            if(o.type == 'Mesh' && o.material !== undefined) {
                if(o.material.userData.cloned === undefined) {
                    o.material = o.material.clone();
                    o.material.userData.cloned = true;
                }
                o.renderOrder = 2000;
                o.material.depthTest = false;
                o.material.transparent = true;
                o.material.opacity = value;
                o.material.emissive.setRGB(1, 1, 0);
            }
        });
    }

    attach(obj) {
        this.transformControls.size = settings.transformControls.size;

        if(this.transformControls.object !== undefined) {
            if(this.transformControls.object === obj)
                return;
            this.detach();
        }
        if(obj === null || obj === undefined) return;

        var clone = obj.clone(true);
        this.setOpacityRecursive(clone, 0.0);

        delete clone.userData.uid;

        obj.parent.add(clone);
        clone.position.copy(obj.position);
        clone.quaternion.copy(obj.quaternion);

        obj.userData.clone = clone;
        clone.userData.original = obj;

        view.requestBoundingBoxUpdate();

        this.transformControls.attach(clone);

        if(obj.userData.canTranslateDuringSimulation === undefined)
            obj.userData.canTranslateDuringSimulation = true;
        if(obj.userData.canTranslateOutsideSimulation === undefined)
            obj.userData.canTranslateOutsideSimulation = true;
        if(obj.userData.canRotateDuringSimulation === undefined)
            obj.userData.canRotateDuringSimulation = true;
        if(obj.userData.canRotateOutsideSimulation === undefined)
            obj.userData.canRotateOutsideSimulation = true;
        if(this.transformControls.mode === 'translate') {
            this.transformControls.enabled = simulationRunning
                ? obj.userData.canTranslateDuringSimulation
                : obj.userData.canTranslateOutsideSimulation;
        } else if(this.transformControls.mode === 'rotate') {
            this.transformControls.enabled = simulationRunning
                ? obj.userData.canRotateDuringSimulation
                : obj.userData.canRotateOutsideSimulation;
        }
        this.transformControls.setTranslationSnap(
            obj.userData.translationStepSize !== null
                ? obj.userData.translationStepSize
                : this.transformControls.userData.defaultTranslationSnap
        );
        this.transformControls.setRotationSnap(
            obj.userData.rotationStepSize !== null
                ? obj.userData.rotationStepSize
                : this.transformControls.userData.defaultRotationSnap
        );

        this.transformControls.showX = true;
        this.transformControls.showY = true;
        this.transformControls.showZ = true;
        if(this.transformControls.mode === 'translate' && obj.userData.movementPreferredAxes?.translation && obj.userData.hasTranslationalConstraints) {
            this.transformControls.showX = obj.userData.movementPreferredAxes.translation.x !== false;
            this.transformControls.showY = obj.userData.movementPreferredAxes.translation.y !== false;
            this.transformControls.showZ = obj.userData.movementPreferredAxes.translation.z !== false;
            this.setSpace(obj.userData.translationSpace);
        } else if(this.transformControls.mode === 'rotate' && obj.userData.movementPreferredAxes?.rotation && obj.userData.hasRotationalConstraints) {
            this.transformControls.showX = obj.userData.movementPreferredAxes.rotation.x !== false;
            this.transformControls.showY = obj.userData.movementPreferredAxes.rotation.y !== false;
            this.transformControls.showZ = obj.userData.movementPreferredAxes.rotation.z !== false;
            this.setSpace(obj.userData.rotationSpace);
        }
    }

    updateTargetPosition() {
        var clone = this.transformControls.object;
        var obj = clone.userData.original;
        /* (original object will change as the result of synchronization)
        obj.position.copy(clone.position);
        obj.quaternion.copy(clone.quaternion);
        */
        var p = clone.position.toArray();
        var q = clone.quaternion.toArray();
        sim.setObjectPose(obj.userData.handle, sim.handle_parent, p.concat(q));
    }

    detach() {
        if(this.transformControls.object === undefined)
            return; // was not attached

        var clone = this.transformControls.object;
        var obj = clone.userData.original;

        clone.removeFromParent();

        delete clone.userData.original;
        delete obj.userData.clone;

        view.requestBoundingBoxUpdate();

        this.transformControls.detach();
    }

    reattach() {
        if(this.transformControls.object === undefined)
            return; // was not attached

        var clone = this.transformControls.object;
        var obj = clone.userData.original;
        this.detach();
        this.attach(obj);
    }

    onStartTransform() {
        var clone = this.transformControls.object;
        this.setOpacityRecursive(clone, 0.4);

        if(settings.transformControls.sendRate > 0) {
            this._sendTransformInterval = setInterval(() => this.updateTargetPosition(), Math.max(50, 1000 / settings.transformControls.sendRate), true);
        }
    }

    onEndTransform() {
        clearInterval(this._sendTransformInterval);
        this.updateTargetPosition();

        // clear ghost only when position is actually updated
        // (avoids the object briefly disappearing):
        var clone = this.transformControls.object;
        var obj = clone.userData.original;
        this.setOpacityRecursive(clone, 0.0);
    }
}

class ObjTree {
    constructor(sceneWrapper, domElement) {
        this.sceneWrapper = sceneWrapper;
        this.domElement = domElement
        if(this.domElement.jquery !== undefined)
            this.domElement = this.domElement.get()[0];
        this.faiconForType = {
            scene: 'globe',
            camera: 'video',
            shape: 'cubes',
            light: 'lightbulb',
            joint: 'cogs',
            dummy: 'bullseye',
            pointCloud: 'cloud',
            octree: 'border-all',
        }
        this.updateRequested = false;
        this._checkInterval = setInterval(() => {
            if(this.updateRequested && $(this.domElement).is(":visible")) {
                this.update();
                this.updateRequested = false;
            }
        }, 200);
    }

    update(obj = undefined) {
        if(obj === undefined) {
            while(this.domElement.firstChild)
                this.domElement.removeChild(this.domElement.lastChild);
            this.domElement.appendChild(this.update(this.sceneWrapper.scene));
        } else {
            var li = document.createElement('li');
            var item = document.createElement('span');
            item.classList.add('tree-item');
            var icon = document.createElement('i');
            icon.classList.add('tree-item-icon');
            icon.classList.add('fas');
            var type = obj.type == "Scene" ? 'scene' : obj.userData.type;
            var faicon = this.faiconForType[type];
            if(faicon === undefined) faicon = 'question';
            icon.classList.add(`fa-${faicon}`);
            var nameLabel = document.createElement('span');
            nameLabel.classList.add("tree-item-name");
            if(view.selectedObject === obj)
                nameLabel.classList.add("selected");
            nameLabel.appendChild(document.createTextNode(
                (obj === this.sceneWrapper.scene ? "(scene)" : obj.nameWithOrder)
            ));
            nameLabel.addEventListener('click', () => {
                this.dispatchEvent('itemClicked', obj.userData.uid);
            });
            obj.userData.treeElement = nameLabel;
            if(obj.userData.treeElementExpanded === undefined)
                obj.userData.treeElementExpanded = obj.userData.parentUid !== -1;
            const children = obj === this.sceneWrapper.scene
                ? [...obj.children].filter((o) => o.userData.uid !== undefined)
                : obj.childObjects;
            if(children.length > 0) {
                var toggler = document.createElement('span');
                toggler.classList.add('toggler');
                if(obj.userData.treeElementExpanded)
                    toggler.classList.add('toggler-open');
                else
                    toggler.classList.add('toggler-close');
                toggler.addEventListener('click', () => {
                    ul.classList.toggle('active');
                    toggler.classList.toggle('toggler-open');
                    toggler.classList.toggle('toggler-close');
                    obj.userData.treeElementExpanded = !obj.userData.treeElementExpanded;
                });
                item.appendChild(toggler);
            }
            item.appendChild(icon);
            item.appendChild(nameLabel);
            if(obj.type != "Scene") {
                var hideBtnIcon = document.createElement('i');
                hideBtnIcon.classList.add('fas');
                hideBtnIcon.classList.add('fa-eye');
                var hideBtn = document.createElement('a');
                hideBtn.href = '#';
                hideBtn.style.color = 'rgba(0,0,0,0.1)';
                hideBtn.style.marginLeft = '3px';
                hideBtn.classList.add('hide-btn');
                hideBtn.appendChild(hideBtnIcon);
                var showBtnIcon = document.createElement('i');
                showBtnIcon.classList.add('fas');
                showBtnIcon.classList.add('fa-eye-slash');
                var showBtn = document.createElement('a');
                showBtn.href = '#';
                showBtn.style.color = 'rgba(0,0,0,0.3)';
                showBtn.style.marginLeft = '3px';
                showBtn.classList.add('show-btn');
                showBtn.appendChild(showBtnIcon);
                hideBtn.addEventListener('click', () => {
                    hideBtn.style.display = 'none';
                    showBtn.style.display = 'inline';
                    obj.visible = false;
                    view.requestRender();
                });
                showBtn.addEventListener('click', () => {
                    hideBtn.style.display = 'inline';
                    showBtn.style.display = 'none';
                    obj.visible = true;
                    view.requestRender();
                });
                if(obj.visible) showBtn.style.display = 'none';
                else hideBtn.style.display = 'none';
                item.appendChild(hideBtn);
                item.appendChild(showBtn);
            }
            if(children.length > 0) {
                var ul = document.createElement('ul');
                if(obj.userData.treeElementExpanded)
                    ul.classList.add('active');
                for(var c of children)
                    ul.appendChild(this.update(c));
                item.appendChild(ul);
            }
            li.appendChild(item);
            return li;
        }
    }

    requestUpdate() {
        this.updateRequested = true;
    }
}

mixin(ObjTree, EventSourceMixin);

function info(text) {
    $('#info').text(text);
    if(!text) $('#info').hide();
    else $('#info').show();
}

function debug(text) {
    if(text !== undefined && $('#debug').is(":visible"))
        console.log(text);
    if(typeof text === 'string' || text instanceof String) {
        $('#debug').text(text);
    } else {
        debug(JSON.stringify(text, undefined, 2));
    }
}

THREE.Object3D.DefaultUp = new THREE.Vector3(0, 0, 1);

var simulationRunning = false;

var sceneWrapper = new SceneWrapper();

const visualizationStreamClient = new VisualizationStreamClient(window.location.hostname, wsPort, codec);
visualizationStreamClient.addEventListener('objectAdded', onObjectAdded);
visualizationStreamClient.addEventListener('objectChanged', onObjectChanged);
visualizationStreamClient.addEventListener('objectRemoved', onObjectRemoved);
visualizationStreamClient.addEventListener('drawingObjectAdded', onDrawingObjectAdded);
visualizationStreamClient.addEventListener('drawingObjectChanged', onDrawingObjectChanged);
visualizationStreamClient.addEventListener('drawingObjectRemoved', onDrawingObjectRemoved);
visualizationStreamClient.addEventListener('environmentChanged', onEnvironmentChanged);
visualizationStreamClient.addEventListener('appSettingsChanged', onAppSettingsChanged);
visualizationStreamClient.addEventListener('simulationChanged', onSimulationChanged);

var view = new View(document.querySelector('#view'), sceneWrapper);
view.addEventListener('selectedObjectChanged', (event) => {
    if(event.previous !== null && event.previous.userData.treeElement !== undefined)
        $(event.previous.userData.treeElement).removeClass('selected');
    if(event.current !== null && event.current.userData.treeElement !== undefined)
        $(event.current.userData.treeElement).addClass('selected');

    if(transformControlsWrapper.transformControls.object !== undefined)
        transformControlsWrapper.detach();
    if(event.current !== null && transformControlsWrapper.transformControls.enabled)
        transformControlsWrapper.attach(event.current);

    view.requestRender();
});

view.addEventListener('selectedCameraChanged', () => {
    if(view.selectedCamera.type == 'OrthographicCamera') {
        // XXX: make sure camera looks "straight"
        var v = view.selectedCamera.position.clone();
        v.sub(orbitControlsWrapper.orbitControls.target);
        v.x = Math.abs(v.x);
        v.y = Math.abs(v.y);
        v.z = Math.abs(v.z);
        if(v.x >= v.y && v.x >= v.z) {
            orbitControlsWrapper.orbitControls.target.y = view.selectedCamera.position.y;
            orbitControlsWrapper.orbitControls.target.z = view.selectedCamera.position.z;
        } else if(v.y >= v.x && v.y >= v.z) {
            orbitControlsWrapper.orbitControls.target.x = view.selectedCamera.position.x;
            orbitControlsWrapper.orbitControls.target.z = view.selectedCamera.position.z;
        } else if(v.z >= v.x && v.z >= v.y) {
            orbitControlsWrapper.orbitControls.target.x = view.selectedCamera.position.x;
            orbitControlsWrapper.orbitControls.target.y = view.selectedCamera.position.y;
        }

        // XXX: first time camera shows nothing, moving mouse wheel fixes that
        if(!orbitControlsWrapper.orbitControls.XXX) {
            orbitControlsWrapper.orbitControls.XXX = true;
            for(var i = 0; i < 2; i++) {
                setTimeout(() => {
                    var evt = document.createEvent('MouseEvents');
                    evt.initEvent('wheel', true, true);
                    evt.deltaY = (i - 0.5) * 240;
                    orbitControlsWrapper.orbitControls.domElement.dispatchEvent(evt);
                }, (i + 1) * 100);
            }
        }
    }
    orbitControlsWrapper.orbitControls.object = view.selectedCamera;
    orbitControlsWrapper.orbitControls.update();

    transformControlsWrapper.transformControls.camera = view.selectedCamera;
});
view.addEventListener('cameraPoseChanging', e => {
    // save orbitControl's target in camera coords *before* moving the camera
    view.selectedCamera.updateMatrixWorld();
    view.targetLocal = view.selectedCamera.worldToLocal(orbitControlsWrapper.orbitControls.target);
});
view.addEventListener('cameraPoseChanged', () => {
    // compute new global position of target
    view.selectedCamera.updateMatrixWorld();
    var t = view.selectedCamera.localToWorld(view.targetLocal);
    // move orbitControl's target
    orbitControlsWrapper.orbitControls.target.set(t.x, t.y, t.z);
    orbitControlsWrapper.orbitControls.update();
});

var axesView = new AxesView(document.querySelector('#axes'), view.selectedCamera.up);

var orbitControlsWrapper = new OrbitControlsWrapper(view.perspectiveCamera, view.renderer);
orbitControlsWrapper.orbitControls.addEventListener('change', (event) => {
    render();
});

var transformControlsWrapper = new TransformControlsWrapper(sceneWrapper, view.perspectiveCamera, view.renderer);
transformControlsWrapper.transformControls.addEventListener('dragging-changed', event => {
    // disable orbit controls while dragging:
    if(event.value) {
        // dragging has started: store enabled flag
        transformControlsWrapper.orbitControlsWasEnabled = orbitControlsWrapper.orbitControls.enabled;
        orbitControlsWrapper.orbitControls.enabled = false;
    } else {
        // dragging has ended: restore previous enabled flag
        orbitControlsWrapper.orbitControls.enabled = transformControlsWrapper.orbitControlsWasEnabled;
        transformControlsWrapper.orbitControlsWasEnabled = undefined;
    }
});
transformControlsWrapper.transformControls.addEventListener('change', (event) => {
    // make bbox follow
    view.requestBoundingBoxUpdate();

    view.requestRender();
});

var remoteApiClient = new RemoteAPIClient(window.location.hostname, 23050, 'cbor', {createWebSocket: url => new ReconnectingWebSocket(url)});
var sim = null;
remoteApiClient.websocket.onOpen.addListener(() => {
    remoteApiClient.getObject('sim').then((_sim) => {
        sim = _sim;
    });
});
remoteApiClient.websocket.open();

var objTree = new ObjTree(sceneWrapper, $('#objtree'));
objTree.addEventListener('itemClicked', onTreeItemSelected);

function render() {
    view.requestRender();
    axesView.requestRender();
}

function animate() {
    requestAnimationFrame(animate);
    //orbitControlsWrapper.orbitControls.update();
    view.render();
    axesView.render(view.selectedCamera.position, orbitControlsWrapper.orbitControls.target);
}
animate();

function onTreeItemSelected(uid) {
    var obj = sceneWrapper.getObjectByUid(uid);
    view.setSelectedObject(obj, false);
}

function onObjectAdded(eventData) {
    sceneWrapper.addObject(eventData);

    objTree.requestUpdate();

    render();
}

function onObjectChanged(eventData) {
    var obj = sceneWrapper.getObjectByUid(eventData.uid);
    if(obj === undefined) return;

    if(eventData.data.alias != obj.name
            || eventData.data.parentUid != obj.userData.parentUid
            || eventData.data.childOrder != obj.userData.childOrder)
        objTree.requestUpdate();

    obj.update(eventData);

    if(view.isPartOfSelection(obj) || view.selectedObject?.ancestorObjects?.includes(obj)) {
        view.requestRender(); view.render(); // XXX: without this, bbox would lag behind
        view.requestBoundingBoxUpdate();
    }

    render();
}

function onObjectRemoved(eventData) {
    var obj = sceneWrapper.getObjectByUid(eventData.uid);
    if(obj === undefined) return;
    if(obj === view.selectedObject)
        view.setSelectedObject(null, false);
    sceneWrapper.removeObject(obj);

    objTree.requestUpdate();

    render();
}

function onDrawingObjectAdded(eventData) {
    sceneWrapper.addDrawingObject(eventData);

    render();
}

function onDrawingObjectChanged(eventData) {
    var obj = DrawingObject.getObjectByUid(eventData.uid);
    if(obj === undefined) return;

    obj.update(eventData);

    render();
}

function onDrawingObjectRemoved(eventData) {
    var obj = DrawingObject.getObjectByUid(eventData.uid);
    if(obj === undefined) return;
    sceneWrapper.removeDrawingObject(obj);

    render();
}

function onEnvironmentChanged(eventData) {
    view.setSelectedObject(null, false);
    sceneWrapper.setSceneData(eventData);

    render();
}

function onAppSettingsChanged(eventData) {
    if(eventData.data.defaultRotationStepSize !== undefined) {
        transformControlsWrapper.transformControls.setRotationSnap(eventData.data.defaultRotationStepSize);
        transformControlsWrapper.transformControls.userData.defaultRotationSnap = eventData.data.defaultRotationStepSize;
    }
    if(eventData.data.defaultTranslationStepSize !== undefined) {
        transformControlsWrapper.transformControls.setTranslationSnap(eventData.data.defaultTranslationStepSize);
        transformControlsWrapper.transformControls.userData.defaultTranslationSnap = eventData.data.defaultTranslationStepSize;
    }

    render();
}

function onSimulationChanged(eventData) {
    if(eventData.data.state !== undefined) {
        simulationRunning = eventData.data.state != 0;
        transformControlsWrapper.reattach();
    }

    render();
}

function toggleObjTree() {
    $("#objtreeBG").toggle();
}

function toggleDebugInfo() {
    $("#debug").toggle();
}

function cancelCurrentMode() {
    transformControlsWrapper.disable();
    if(view.selectedObject !== null) {
        transformControlsWrapper.detach();
    }
}

function setTransformMode(mode, space) {
    transformControlsWrapper.enable();
    transformControlsWrapper.setMode(mode);
    transformControlsWrapper.setSpace(space);
    if(view.selectedObject !== null) {
        transformControlsWrapper.attach(view.selectedObject);
    }
}

function setTransformSnap(enabled) {
    if(enabled) {
        transformControlsWrapper.transformControls.setRotationSnap(
            transformControlsWrapper.transformControls.userData.previousRotationSnap
        );
        transformControlsWrapper.transformControls.setTranslationSnap(
            transformControlsWrapper.transformControls.userData.previousTransationSnap
        );
    } else {
        transformControlsWrapper.transformControls.userData.previousTranslationSnap = transformControlsWrapper.transformControls.translationSnap;
        transformControlsWrapper.transformControls.userData.previousRotationSnap = transformControlsWrapper.transformControls.rotationSnap;
        transformControlsWrapper.transformControls.setRotationSnap(null);
        transformControlsWrapper.transformControls.setTranslationSnap(null);
    }
}

function toggleLog() {
    $('#log').toggle();
}

const keyMappings = {
    KeyH_down:   e => toggleObjTree(),
    KeyD_down:   e => toggleDebugInfo(),
    Escape_down: e => cancelCurrentMode(),
    KeyT_down:   e => setTransformMode('translate', e.shiftKey ? 'local' : 'world'),
    KeyR_down:   e => setTransformMode('rotate', e.shiftKey ? 'local' : 'world'),
    ShiftLeft:   e => setTransformSnap(e.type === 'keyup'),
    ShiftRight:  e => setTransformSnap(e.type === 'keyup'),
    KeyL_down:   e => toggleLog(),
};

window.addEventListener('keydown', e => (keyMappings[e.code + '_down'] || keyMappings[e.code] || (e => {}))(e));
window.addEventListener('keyup',   e => (keyMappings[e.code + '_up']   || keyMappings[e.code] || (e => {}))(e));
