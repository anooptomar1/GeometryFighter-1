//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by Macbook on 24/04/2016.
//  Copyright (c) 2016 Chappy-App. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {



    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var spawnTime: NSTimeInterval = 0
    var game = GameHelper.sharedInstance
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        setupHUD()
        setupSounds()
        
        
    }
    
    override func shouldAutorotate() -> Bool {
        return true
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
        
    }
    
    func setupView() {
        scnView = self.view as! SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.delegate = self
        scnView.playing = true
        
    }
    
    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png"
        
    }
    
    func setupCamera() {
    
        // 1
        cameraNode = SCNNode()
        //2
        cameraNode.camera = SCNCamera()
        //3
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        //4
        scnScene.rootNode.addChildNode(cameraNode)
        
    }
    
    func spawnShape() {
    
        var geometry: SCNGeometry
        
        switch ShapeType.random() {
            
            case .Box:
                geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
            case .Sphere:
                geometry = SCNSphere(radius: 0.5)
            case .Pyramid:
                geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
            case .Torus:
                geometry = SCNTorus(ringRadius: 0.5, pipeRadius: 0.25)
            case .Capsule:
                geometry = SCNCapsule(capRadius: 0.3, height: 2.5)
            case .Cylinder:
                geometry = SCNCylinder(radius: 0.3, height: 2.5)
            case .Cone:
                geometry = SCNCone(topRadius: 0.25, bottomRadius: 0.5, height: 1.0)
            case .Tube:
                geometry = SCNTube(innerRadius: 0.25, outerRadius: 0.5, height: 1.0)
            }
    
        let geometryNode = SCNNode(geometry: geometry)
        scnScene.rootNode.addChildNode(geometryNode)
        geometryNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        let force = SCNVector3(x: randomX, y: randomY, z: 0)
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        
        geometryNode.physicsBody?.applyForce(force, atPosition: position, impulse: true)
        let trailEmitter = creatTrail(color, geometry: geometry)
        geometryNode.addParticleSystem(trailEmitter)
        
        if color == UIColor.blackColor() {
            geometryNode.name = "BAD"
            
        } else {
            
            geometryNode.name = "GOOD"
        }
        
    }
    
    func cleanScene() {
        
        for node in scnScene.rootNode.childNodes {
            
            if node.presentationNode.position.y < -2 {
                node.removeFromParentNode()
            }
        }
        
    }
    
    func creatTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
    
        let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        trail.particleColor = color
        trail.emitterShape = geometry
        return trail
    }
    
    func setupHUD() {
        
        game.hudNode.position = SCNVector3(x: 0.0, y: 10.0, z: 0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
        
    }
    
    func handleTouchFor(node: SCNNode) {
        if node.name == "GOOD" {
        createExplosion(node.geometry!, position: node.presentationNode.position, rotation: node.presentationNode.rotation)
            game.score += 1
            node.removeFromParentNode()
        } else if node.name == "BAD" {
            createExplosion(node.geometry!, position: node.presentationNode.position, rotation:
            node.presentationNode.rotation)
            game.lives -= 1
            node.removeFromParentNode()
            
        }
    }
  
  func setupSounds() {
    game.loadSound("ExplodeGood",
                   fileNamed: "GeometryFighter.scnassets/Sounds/ExplodeGood.wav")
    game.loadSound("SpawnGood",
                   fileNamed: "GeometryFighter.scnassets/Sounds/SpawnGood.wav")
    game.loadSound("ExplodeBad",
                   fileNamed: "GeometryFighter.scnassets/Sounds/ExplodeBad.wav")
    game.loadSound("SpawnBad",
                   fileNamed: "GeometryFighter.scnassets/Sounds/SpawnBad.wav")
    game.loadSound("GameOver",
                   fileNamed: "GeometryFighter.scnassets/Sounds/GameOver.wav")
  }

    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        let location = touch.locationInView(scnView)
        let hitResults = scnView.hitTest(location, options: nil)
        if hitResults.count > 0 {
            
            let result = hitResults.first!
            handleTouchFor(result.node)
        }
    }
    
    func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
        explosion.emitterShape = geometry
        explosion.birthLocation = .Surface
        
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, withTransform: transformMatrix)
     
    }
}




extension GameViewController: SCNSceneRendererDelegate {
    
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        if time > spawnTime {
        
            spawnShape()
            
            spawnTime = time + NSTimeInterval(Float.random(min: 0.2, max: 1.5))
        }
        
        game.updateHUD()
        cleanScene()
        
        

    }
}




