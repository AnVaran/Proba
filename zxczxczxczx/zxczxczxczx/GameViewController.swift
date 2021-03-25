//
//  GameViewController.swift
//  zxczxczxczx
//
//  Created by Eugene Smolyakov on 03.03.2021.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        let scnView = self.view as! SCNView
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.backgroundColor = UIColor.black
        
        //1
        let cub1 = scene.rootNode.childNode(withName: "box1", recursively: true)!
        let vertices1 = cub1.geometry!.vertices()!
        var subnodes = [SCNNode]()
        for vv in vertices1 {
            let n = SCNNode()
            n.position = vv
            cub1.addChildNode(n)
            subnodes.append(n)
        }
        for vv in subnodes {
            let geo = SCNSphere(radius: 0.05)
            geo.firstMaterial?.diffuse.contents = UIColor.green
            let nn = SCNNode(geometry: geo)
            nn.position = vv.worldPosition
            scene.rootNode.addChildNode(nn)
        }
        subnodes.forEach { $0.removeFromParentNode()}
        subnodes.removeAll()
        
        //2
        let cub2 = scene.rootNode.childNode(withName: "box2", recursively: true)!
        let vertice2 = cub2.geometry!.vertices()!
        for vv in vertice2 {
            let geo = SCNSphere(radius: 0.05)
            geo.firstMaterial?.diffuse.contents = UIColor.green
            let nn = SCNNode(geometry: geo)
            nn.position = vv
            cub2.addChildNode(nn)
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
