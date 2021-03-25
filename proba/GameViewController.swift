//
//  GameViewController.swift
//  proba
//
//  Created by Anton Varenik on 3/15/21.
//  Copyright © 2021 Anton Varenik. All rights reserved.
//

import UIKit
import Foundation
import QuartzCore
import SceneKit
import SwiftSplines

class GameViewController: UIViewController, SCNSceneRendererDelegate {

    var ground: SCNNode!
    var sphere: SCNNode!
    var yellow: SCNNode!
    var points = [Point]()
    var oldPosition: Point!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        let vertices:[SCNVector3] = [
                SCNVector3(x:0, y:0, z:2),
                SCNVector3(x:2, y:0, z:2),
                SCNVector3(x:3, y:0, z:-1),
                SCNVector3(x:-1, y:0, z:-1),
                SCNVector3(x:-1, y:0, z:1)
        ]
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 1, z: 7)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        //ground
        let groundGeometry = SCNBox(width: 5, height: 0, length: 5, chamferRadius: 0)
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = UIColor.blue
        groundGeometry.materials = [groundMaterial]
        let geo = polygonGeometry(vertices: vertices)
        geo.materials = [groundMaterial]
        ground = SCNNode(geometry: geo)
        scene.rootNode.addChildNode(ground)
        
        guard let vertices2 = ground.geometry?.vertices() else { return }
        
        for vv in vertices2 {
            let sphereGeometry = SCNSphere(radius: 0.05)
            let sphereMaterial = SCNMaterial()
            sphereMaterial.diffuse.contents = UIColor.green
            sphereGeometry.materials = [sphereMaterial]
            let vsphere = SCNNode(geometry: sphereGeometry)
            vsphere.position = vv
            ground.addChildNode(vsphere)
        }
        
        //sphere
        let sphereGeometry = SCNSphere(radius: 0.1)
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.green
        sphereGeometry.materials = [sphereMaterial]
        sphere = SCNNode(geometry: sphereGeometry)
        sphere.position = SCNVector3(0, sphereGeometry.radius, 0)
        
        let yellowGeometry = SCNSphere(radius: 0.1)
        let yellowMaterial = SCNMaterial()
        yellowMaterial.diffuse.contents = UIColor.yellow
        yellowGeometry.materials = [yellowMaterial]
        yellow = SCNNode(geometry: yellowGeometry)
        yellow.position = SCNVector3(0.1, 0, 0)
        
        
        
        sphere.addChildNode(yellow)
        ground.addChildNode(sphere)
        
        //yellowMove(object: sphere)
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        scnView.delegate = self
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
    
        scnView.backgroundColor = UIColor.white
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
    }
    
    func yellowMove(object obj: SCNNode)
    {
        var action = [SCNAction]()
        var chain = [CGPoint]()
        
        chain.append(CGPoint(x: CGFloat(obj.position.x), y: CGFloat(obj.position.z)))
       // генерируем 6 случайных точек.
        for _ in (1..<200) {
            chain.append(getRandPoint())
        }
        
        let spline = Spline(values: chain, boundaryCondition: .smooth)
        let resolution = 10 //Гладкость сплайна
        let length = chain.count
        let pointCG = (-resolution ..< length * resolution).map { (offset) -> CGPoint in
            let argument = CGFloat(offset)/CGFloat(resolution)
            return spline.f(t: argument)
        }
        
        for i in 0..<pointCG.count - resolution {
            points.append(Point(x: Float(pointCG[i].x), z: Float(pointCG[i].y)))
        }
        
        //Поворот к оси X
        if oldPosition != nil {
            let currentDirection = Point(x: obj.position.x - oldPosition.x, z: obj.position.z - oldPosition.z)
            let xAngel = findDirectionAngel(newVector: Point(x: 1, z: 0), oldVector: currentDirection)
            let xRotate = SCNAction.rotate(by: CGFloat(xAngel), around: SCNVector3(0, 1, 0), duration: 0.0001)
            obj.runAction(xRotate)
        }
        
        points.insert(Point(x: obj.position.x + 0.001, z: obj.position.z), at: 0)
        points.insert(Point(x: obj.position.x, z: obj.position.z), at: 0)
        action.append(SCNAction.move(to: SCNVector3(x: obj.position.x + 0.01, y: obj.position.y, z: obj.position.z), duration: 0.001))

        for i in 1..<points.count-1 {
            let newVect = Point(x: points[i+1].x - points[i].x, z: points[i+1].z - points[i].z)
            let oldVect = Point(x: points[i].x - points[i-1].x, z: points[i].z - points[i-1].z)

            let angel = findDirectionAngel(newVector: newVect, oldVector: oldVect)
            let rotate = SCNAction.rotate(by: CGFloat(angel), around: SCNVector3(0, 1, 0), duration: 0.0001)
            let move = SCNAction.move(to: SCNVector3(x: points[i+1].x, y: obj.position.y, z: points[i+1].z), duration: 0.1)
            action.append(rotate)
            action.append(move)

        }
        
        let anim = SCNAction.sequence(action)
        oldPosition = points[points.count-2]
        //anim.speed = 3
        
        obj.runAction(anim) {
            self.yellowMove(object: obj)
        }
    }
    
    func findDirectionAngel(newVector: Point, oldVector: Point) -> Float {
        var angel: Float = 0.0
        let xVector = Point(x: 1, z: 0)
        let newAngel = findAngelBetweenTwoVectors(firstVector: xVector, secondVector: newVector)
        let oldAngel = findAngelBetweenTwoVectors(firstVector: xVector, secondVector: oldVector)
        
        if newVector.z >= 0 && oldVector.z >= 0 {
            angel = oldAngel - newAngel
        } else if newVector.z <= 0 && oldVector.z <= 0 {
            angel = newAngel - oldAngel
        } else if newVector.z >= 0 && oldVector.z <= 0 {
            if oldAngel + newAngel < Float.pi {
                angel = -(oldAngel + newAngel)
            } else {
                angel = -(oldAngel + newAngel - 2 * Float.pi)
            }
        } else if oldVector.z >= 0 && newVector.z <= 0 {
            if oldAngel + newAngel < Float.pi {
                angel = oldAngel + newAngel
            } else {
                angel = oldAngel + newAngel - 2 * Float.pi
            }
        }
        
        return angel
    }
    
    func findAngelBetweenTwoVectors(firstVector: Point, secondVector: Point) -> Float {
        
        let up = firstVector.x * secondVector.x + firstVector.z * secondVector.z
        let down = sqrt(pow(firstVector.x, 2) + pow(firstVector.z, 2)) * sqrt(pow(secondVector.x, 2) + pow(secondVector.z, 2))
        
        var angel = acos(up / down)
        
        if angel.isNaN {
            if up/down > 1 {
                angel = 0.0
            } else if up/down < -1 {
                angel = Float.pi
            }
        }
        
        return angel
    }
    
    func getRandPoint() -> CGPoint {
        let x = Double(Int.random(in: -250...250)) / 100
        let z = Double(Int.random(in: -250...250)) / 100
        
        return CGPoint(x: x, y: z)
    }
    
    private func polygonGeometry (vertices: [SCNVector3]) -> SCNGeometry {
        var normals = [SCNVector3]()
        for _ in 0..<vertices.count {
            normals.append(SCNVector3(0, 1, 0))
        }
        let normalsSource = SCNGeometrySource(normals: normals)
        
        var indices: [Int32] = [Int32(vertices.count)]
        indices.append(contentsOf: generateIndices(max: vertices.count))
        let indexData = Data(bytes: indices,
                             count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .polygon,
                                         primitiveCount: 1,
                                         bytesPerIndex: MemoryLayout<Int32>.size)
        
        let vertexSource = SCNGeometrySource(vertices: vertices)
        
        let geometry = SCNGeometry(sources: [vertexSource, normalsSource], elements: [element])
        
        return geometry
    }
    
    private func generateIndices(max maxIndexValue: Int) -> [Int32]{
        var counter: Int = 0
        var output: [Int32] = []
        while counter < maxIndexValue {
            output.append(Int32(counter))
            counter += 1
        }
        return output
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

}

extension  SCNGeometry{
    func vertices() -> [SCNVector3]? {

        let sources = self.sources(for: .vertex)

        guard let source  = sources.first else{return nil}

        let stride = source.dataStride / source.bytesPerComponent
        let offset = source.dataOffset / source.bytesPerComponent
        let vectorCount = source.vectorCount

        return source.data.withUnsafeBytes { (buffer : UnsafePointer<Float>) -> [SCNVector3] in

            var result = Array<SCNVector3>()
            for i in 0...vectorCount - 1 {
                let start = i * stride + offset
                let x = buffer[start]
                let y = buffer[start + 1]
                let z = buffer[start + 2]
                result.append(SCNVector3(x, y, z))
            }
            return result
        }
    }
}

struct Point {
    let x: Float
    let z: Float
}
