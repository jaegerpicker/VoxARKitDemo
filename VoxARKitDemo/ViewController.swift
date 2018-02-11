//
//  ViewController.swift
//  VoxARKitDemo
//
//  Created by Shawn Campbell on 2/11/18.
//  Copyright © 2018 Shawn Campbell. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    let nodeName = "phone"
    var nodeModel:SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.antialiasingMode = .multisampling4X
        
        let scene = SCNScene()
        
        // Set the scene to the view
        
        
        let modelScene = SCNScene(named:
            "art.scnassets/iPhone 6.scn")!
        sceneView.scene = scene
        self.nodeModel =  modelScene.rootNode.childNode(
            withName: nodeName, recursively: true)
        self.nodeModel.boundingBox = (min: SCNVector3(x: -1, y:-1, z:-1), max: SCNVector3(x: 0, y: 0, z: 0))
        let modelClone = self.nodeModel.clone()
        let headBox = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        let boxNode = SCNNode(geometry: headBox)
        boxNode.position = modelClone.position
        boxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: boxNode, options: nil))
        boxNode.physicsBody?.isAffectedByGravity = false
        boxNode.opacity = 0.01
        modelClone.rotation = SCNVector4Make(1, 0, 0, (Float(.pi/2 * 3)))
        sceneView.scene.rootNode.addChildNode(modelClone)
        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: sceneView)
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        let hitResults: [SCNHitTestResult]  =
            sceneView.hitTest(location, options: hitTestOptions)
        if let hit = hitResults.first {
            if let node = getParent(hit.node) {
                node.removeFromParentNode()
                return
            }
        }
        let hitResultsFeaturePoints: [ARHitTestResult] =
            sceneView.hitTest(location, types: .featurePoint)
        if let hit = hitResultsFeaturePoints.first {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            DispatchQueue.main.async {
                //let modelClone = self.nodeModel.clone()
                //modelClone.position = SCNVector3Zero
                
                // Add model as a child of the node
                //node.addChildNode(modelClone)
            }
        }
    }
    
    func getParent(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == nodeName {
                return node
            } else if let parent = node.parent {
                return getParent(parent)
            }
        }
        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
