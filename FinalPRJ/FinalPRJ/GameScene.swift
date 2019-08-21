//
//  GameScene.swift
//  FinalPRJ
//
//  Created by Steven Le on 2019-08-06.
//  Copyright © 2019 Steven Le. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreData

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Bitmask Init
    let characterCategory: UInt32 = 0x1 << 0 // 1
    let alienCategory: UInt32 = 0x1 << 1 // 2
    let powerUpCategory: UInt32 = 0x1 << 2 // 4
    let bulletCategory: UInt32 = 0x1 << 3 // 8
    
    //Init for getting Display Values
    let displaySize: CGRect = UIScreen.main.bounds
    
    //Init for Spawns
    var alien: SKSpriteNode!
    var powerUp: SKSpriteNode!
    
    var exitButton: SKSpriteNode?
    
    //Init for Labels, Values
    var scoreLabel: SKLabelNode!
    var score: Int = 0
    var powerUpLabel: SKLabelNode!
    var powerUpNo: Int = 0
    var highScoreLabel: SKLabelNode!
    var highScoreLabelData1: SKLabelNode!
    var highScoreLabelData2: SKLabelNode!
    var highScoreLabelData3: SKLabelNode!

    //Init for Gamestate
    var gameRunning:Bool = false
    var bulletSpeedPowerUp:Double = 1
    var bulletSpeed:Double = 5
    var gameOverLabel: SKLabelNode!
    var gameTime:Int = 60
    var currGameTime:Int = 0
    
    //Init for Spawn/Game Timers
    var alienSpawn: Timer?
    var powerUpSpawn: Timer?
    var gameTimer: Timer?
    
    //Init for Final Score List
    var finalScoreArray = [0, 0, 0]
    
    
    override func didMove(to view: SKView) {
        //(view) -> None
        //Function that Handles Application Start
        //Initializes Gestures, Labels (their positions & default value) and Timers
        
        //on gamestart implement gameovertimer
        
        self.physicsWorld.contactDelegate = self
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipeRight(sender:)))
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipeLeft(sender:)))
        swipeRight.direction = .right
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeRight)
        view.addGestureRecognizer(swipeLeft)
        gameOverLabel = childNode(withName: "gameOverLabel") as? SKLabelNode
        gameOverLabel.position = CGPoint(x: 0,y: 0);
        gameOverLabel.text = "Click to Start"
        
        scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode
        scoreLabel.position = CGPoint(x: -230,y: 485);
        scoreLabel.text = "Score: \(score)"
        
        highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode
        highScoreLabel.position = CGPoint(x: 0,y: 295);
        highScoreLabel.text = "HighScore:"
        highScoreLabelData1 = childNode(withName: "highScoreLabel1") as? SKLabelNode
        highScoreLabelData1.position = CGPoint(x: 0,y: 255);
        highScoreLabelData1.text = "0"
        highScoreLabelData2 = childNode(withName: "highScoreLabel2") as? SKLabelNode
        highScoreLabelData2.position = CGPoint(x: 0,y: 215);
        highScoreLabelData2.text = "0"
        highScoreLabelData3 = childNode(withName: "highScoreLabel3") as? SKLabelNode
        highScoreLabelData3.position = CGPoint(x: 0,y: 175);
        highScoreLabelData3.text = "0"
        
        
        powerUpLabel = childNode(withName: "powerUpLabel") as? SKLabelNode
        powerUpLabel.position = CGPoint(x: 210,y: 485);
        powerUpLabel.text = "PowerUps: \(powerUpNo)"
        
        exitButton = SKSpriteNode(imageNamed: "exitButton.png")
        exitButton?.position = CGPoint(x: 0, y: -320)
        exitButton?.size = CGSize(width: 300, height: 200)
        exitButton?.name = "exit"
        self.addChild(exitButton!)
        
        alienSpawn = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: {(timer) in self.spawnAlien()})
        powerUpSpawn = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: {(timer) in self.spawnPowerUp()})
    }
    
    @objc func sixtySecondGameTimer(){
        if (currGameTime < 60){
            currGameTime += 1
        }
        if (currGameTime == 60){
            endState()
        }
    }
    func endState(){
        //(None)->UI element toggle
        //Function that handles the main screen that lets u play again along with the scores
        highScoreLabel.text = "HighScore:"
        gameOverLabel.text = "Game Over!"
        gameTimer?.invalidate()
        currGameTime = 0
        finalScoreArray.append(score)
        finalScoreArray.sort(by: >)
        score = 0
        powerUpNo = 0
        scoreLabel.text = "Score: \(score)"
        powerUpLabel.text = "PowerUps: \(powerUpNo)"
        highScoreLabelData1.text = String(finalScoreArray[0])
        highScoreLabelData2.text = String(finalScoreArray[1])
        highScoreLabelData3.text = String(finalScoreArray[2])
        self.addChild(exitButton!)
    }
    
    func spawnBullet(xCoord: CGFloat, yCoord: CGFloat){
        //(xCoordinate, yCoordinate) -> Bullet instance
        //Function that handles initializing and movement of the bullet instance
        
        let bullet = SKSpriteNode(imageNamed: "bullet.png")
        
        //Bullet Properties
        bullet.size = CGSize(width: 25, height: 25)
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.isDynamic = true
        
        bullet.physicsBody?.categoryBitMask = bulletCategory
        bullet.physicsBody?.contactTestBitMask = alienCategory | powerUpCategory
        
        //Bullet Spawn/Movement - moves to clicked point
        self.addChild(bullet)
        let bounds = UIScreen.main.bounds
        let height = bounds.size.height
        bullet.position = CGPoint(x: 0, y: height * -1)
        
        let bulletTravel = SKAction.move(by: CGVector(dx: xCoord , dy: yCoord + height), duration: bulletSpeed)
        bullet.run(SKAction.sequence([bulletTravel, SKAction.removeFromParent()]))
    }
    
    func spawnAlien(){
        //(None) -> Alien instance
        //Function that handles initializing and movement of the alien instance
        
        alien = SKSpriteNode(imageNamed: "alien.png")
        
        //Alien Properties
        alien.size = CGSize(width: 75, height: 75)
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.affectedByGravity = false
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = bulletCategory
        alien.physicsBody?.collisionBitMask = 0
        
        //Alien Spawn/Movement - moves to the left from theright of the screen
        self.addChild(alien)
        let minY = -size.height/2 + alien.size.height
        let maxY = size.height/2 - alien.size.height
        let range = maxY - minY
        let alienY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        alien.position = CGPoint(x: size.width, y: alienY)
        let moveLeft = SKAction.moveBy(x: -1300, y: 0, duration: 3)
        alien.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
    }
    
    func spawnPowerUp(){
        //(None) -> Power Up instance
        //Function that handles initializing and movement of the power up instance
        
        powerUp = SKSpriteNode(imageNamed: "powerUp.png")
        
        //Power Up Properties
        powerUp.size = CGSize(width: 75, height: 75)
        powerUp.physicsBody = SKPhysicsBody(rectangleOf: powerUp.size)
        powerUp.physicsBody?.affectedByGravity = false
        powerUp.physicsBody?.isDynamic = true
        
        powerUp.physicsBody?.categoryBitMask = powerUpCategory
        powerUp.physicsBody?.contactTestBitMask = bulletCategory
        powerUp.physicsBody?.collisionBitMask = 0
        
        //Power Up Spawn/Movement - moves to the right from the left side of the screen
        self.addChild(powerUp)
        let minY = -size.height/2 + powerUp.size.height
        let maxY = size.height/2 - powerUp.size.height
        let range = maxY - minY
        let powerUpY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        powerUp.position = CGPoint(x: -size.width, y: powerUpY)
        let moveRight = SKAction.moveBy(x: 1300, y: 0, duration: 3)
        powerUp.run(SKAction.sequence([moveRight, SKAction.removeFromParent()]))
    }
    
    @objc func swipeRight(sender: UISwipeGestureRecognizer){
        //(UISwipeGestureRecognizer) -> Label/Variable update
        //Function that handles swiping to the right
        //print("swiped R!")
        
        if (gameRunning == true){
            //While gamestate is true, add to the bullet speed and update the powerups accordingly
            if (powerUpNo > 0){
                if (bulletSpeed > 0){
                    bulletSpeed -= bulletSpeedPowerUp
                    powerUpNo -= 1
                    powerUpLabel.text = "PowerUps: \(powerUpNo)"
                }
                else{
                    powerUpNo -= 1
                    bulletSpeed = 1
                    powerUpLabel.text = "PowerUps: \(powerUpNo)"
                }
                
            }
        }
    }
    @objc func swipeLeft(sender: UISwipeGestureRecognizer){
        //(UISwipeGestureRecognizer) -> Label/Variable update
        //Function that handles swiping to the left
        //print("swiped L!")
        if (gameRunning == true){
            //While gamestate is true, add to the bullet speed and update the powerups accordingly
            if (powerUpNo > 0){
                if (bulletSpeed > 0){
                    bulletSpeed -= bulletSpeedPowerUp
                    powerUpNo -= 1
                    powerUpLabel.text = "PowerUps: \(powerUpNo)"
                }
                else{
                    powerUpNo -= 1
                    bulletSpeed = 1
                    powerUpLabel.text = "PowerUps: \(powerUpNo)"
                }
                
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //(UITouch, UIEvent) -> Label Update, spawnBullet Instance
        //Function that handles gamestart
        if let touch = touches.first {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            if (touchedNode.name == "exit") {
                print("exit")
                exit(0)
            }
            else{
                gameOverLabel.text = ""
                highScoreLabel.text = ""
                highScoreLabelData1.text = ""
                highScoreLabelData2.text = ""
                highScoreLabelData3.text = ""
                let location = touch.location(in: self)
                spawnBullet(xCoord: location.x, yCoord: location.y)
                exitButton?.removeFromParent()
                
            }
            
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        //(SkPhysicsContact) -> Contact/Collision Delegation + Score/PowerUp Update
        //Function that handles Contact/Collision to update the score/powerup vars
        //Based on these bitmasks:
        //let characterCategory: UInt32 = 0x1 << 0 // 1
        //let alienCategory: UInt32 = 0x1 << 1 // 2
        //let powerUpCategory: UInt32 = 0x1 << 2 // 4
        //let bulletCategory: UInt32 = 0x1 << 3 // 8
        gameRunning = true
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(sixtySecondGameTimer), userInfo: nil, repeats: true)
        
        if ((contact.bodyA.categoryBitMask == 2 && contact.bodyB.categoryBitMask == 8) || contact.bodyA.categoryBitMask == 8 && contact.bodyB.categoryBitMask == 2){
            //alien = childNode(withName: "alien") as? SKSpriteNode
            //print("alien hit")
            alien?.removeFromParent()
            score += 1
            scoreLabel.text = "Score: \(score)"
        }
        if ((contact.bodyA.categoryBitMask == 4 && contact.bodyB.categoryBitMask == 8) || contact.bodyA.categoryBitMask == 8 && contact.bodyB.categoryBitMask == 4){
            powerUp?.removeFromParent()
            powerUpNo += 1
            powerUpLabel.text = "PowerUps: \(powerUpNo)"
        }
    }
}
