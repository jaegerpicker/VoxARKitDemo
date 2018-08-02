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

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    let nodeName = "MacBook"
    var nodeModel:SCNNode!
    var planeFound = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.antialiasingMode = .multisampling4X
        
        
        
        // Set the scene to the view
        //guard let currentTransform = sceneView.session.currentFrame?.camera.transform else { return }
        //var translation = matrix_identity_float4x4
        
        //Change The X Value
        //translation.columns.3.x = 0
        
        //Change The Y Value
        //translation.columns.3.y = 0
        
        //Change The Z Value
        //translation.columns.3.z = 1
        
        let modelScene = SCNScene(named:
           "art.scnassets/macbookpro2017.dae")!
        //sceneView.scene = modelScene
        self.nodeModel =  modelScene.rootNode.childNode(
            withName: nodeName, recursively: true)
        self.nodeModel.boundingBox = (min: SCNVector3(x: -2, y:-2, z:-2), max: SCNVector3(x: 0, y: 0, z: 0))
        //let modelClone = self.nodeModel.clone()
        //self.nodeModel.rotation = SCNVector4Make(1, 0, 0, (Float(Double.pi/2 * 3)))
        let action = SCNAction.scale(by: 0.33, duration: 1.0)
        self.nodeModel.runAction(action)
        //self.nodeModel.simdTransform = matrix_multiply(currentTransform, translation)
        //sceneView.scene.rootNode.addChildNode(self.nodeModel)
        //addBox()
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        planeFound = false
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
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let plane = Plane(anchor: planeAnchor, in: sceneView)
        let modelClone = self.nodeModel.clone()
        modelClone.position = SCNVector3Zero
        let pov = sceneView.pointOfView
        let position = pov?.position
        modelClone.position.x = (position?.x)! * 0.75
        modelClone.position.y = (position?.y)! * 0.75
        modelClone.position.z = (position?.z)! * 0.75
        node.addChildNode(modelClone)
        node.addChildNode(plane)
        planeFound = true
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
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }
    
    // MARK: - Private methods
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal and vertical surfaces."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
    
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let plane = node.childNodes.first as? Plane
            else { return }
        
        // Update ARSCNPlaneGeometry to the anchor's new estimated shape.
        if let planeGeometry = plane.meshNode.geometry as? ARSCNPlaneGeometry {
            planeGeometry.update(from: planeAnchor.geometry)
        }
        
        // Update extent visualization to the anchor's new bounding rectangle.
        if let extentGeometry = plane.extentNode.geometry as? SCNPlane {
            extentGeometry.width = CGFloat(planeAnchor.extent.x)
            extentGeometry.height = CGFloat(planeAnchor.extent.z)
            plane.extentNode.simdPosition = planeAnchor.center
        }
    }
}
