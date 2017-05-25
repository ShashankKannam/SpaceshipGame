//
//  AsteroidBehavior.swift
//  SpaceshipGame
//
//  Created by shashank kannam on 5/25/17.
//  Copyright © 2017 developer. All rights reserved.
//

import UIKit

class AsteroidBehavior: UIDynamicBehavior, UICollisionBehaviorDelegate {
    
    var asteriods = [AsteroidView]()
    
    private lazy var collider: UICollisionBehavior = {
        let behavior = UICollisionBehavior()
        behavior.collisionMode = .everything
        behavior.translatesReferenceBoundsIntoBoundary = true
        behavior.collisionDelegate = self
        return behavior
    }()
    
    private lazy var physicsBehavior: UIDynamicItemBehavior = {
        let behavior = UIDynamicItemBehavior()
        behavior.elasticity = 1.0
        behavior.allowsRotation = true
        behavior.resistance = 0.0
        behavior.friction = 0.0
        return behavior
    }()
    
    lazy var acceleration: UIGravityBehavior = {
        let behavior = UIGravityBehavior()
        behavior.magnitude = 0.0
        return behavior
    }()
    
    var speedLimit: CGFloat = 0.0
    
    override init() {
        super.init()
        addChildBehavior(collider)
        addChildBehavior(physicsBehavior)
        addChildBehavior(acceleration)
        
        physicsBehavior.action = { [weak self] in
            for asteroid in self?.asteriods ?? [] {
                let velocity = self!.physicsBehavior.linearVelocity(for: asteroid)
                let excessHorizontalVelocity = min(self!.speedLimit - velocity.x, 0)
                let excessVerticalVelocity = min(self!.speedLimit - velocity.y, 0)
                self!.physicsBehavior.addLinearVelocity(CGPoint(x: excessHorizontalVelocity, y: excessVerticalVelocity), for: asteroid)
            }
        }

    }
    
    private var collisionHandlers = [String:() -> ()]()
    
    func addBoundary(_ path: UIBezierPath?, named name: String, handler: (() -> ())?){
        collider.removeBoundary(withIdentifier: name as NSString)
        collisionHandlers.removeValue(forKey: name)
        if let path1 = path {
            collider.addBoundary(withIdentifier: name as NSString, for: path1)
            collisionHandlers[name] = handler
        }
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        if let name = identifier as? String, let handle = collisionHandlers[name] {
            handle()
        }
    }
    
    func pushAllAsteriods(by magnitude: Range<CGFloat> = 0..<0.5) {
        for asteriod in asteriods {
            let pusher = UIPushBehavior(items: [asteriod], mode: .instantaneous)
            pusher.magnitude = CGFloat.random(in: magnitude)
            pusher.angle = CGFloat.random(in: 0..<CGFloat.pi*2)
            addChildBehavior(pusher)
        }
    }
    
    func addAsteroid(_ asteriod: AsteroidView) {
        asteriods.append(asteriod)
        collider.addItem(asteriod)
        physicsBehavior.addItem(asteriod)
        acceleration.addItem(asteriod)
        startRecapturingWaywardAsteroids()
    }
    
    func removeAsteroid(_ asteriod: AsteroidView) {
        if let index = asteriods.index(of: asteriod) {
            asteriods.remove(at: index)
            collider.removeItem(asteriod)
            physicsBehavior.removeItem(asteriod)
            acceleration.removeItem(asteriod)
        }
        if asteriods.isEmpty {
            stopRecapturingWaywardAsteroids()
        }
    }
    
    // inherited from UIDynamicBehavior
    // let's us know when our UIDynamicAnimator changes
    // we need to know so we can stop/start our wayward asteroid recapture
    override func willMove(to dynamicAnimator: UIDynamicAnimator?) {
        super.willMove(to: dynamicAnimator)
        if dynamicAnimator == nil {
            stopRecapturingWaywardAsteroids()
        } else if !asteriods.isEmpty {
            startRecapturingWaywardAsteroids()
        }
    }


    // MARK: Recapturing Wayward Asteroids
    
    // every 0.5s
    // we look around for asteroids that are
    // outside an asteroid's superview
    // we wrap it around to the other side
    // we take care to notify the animator that we've moved the item
    // using updateItem(usingCurrentState:)
    
    var recaptureCount = 0
    private weak var recaptureTimer: Timer?
    
    private func startRecapturingWaywardAsteroids() {
        if recaptureTimer == nil {
            recaptureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
                for asteroid in self?.asteriods ?? [] {
                    if let asteroidFieldBounds = asteroid.superview?.bounds, !asteroidFieldBounds.contains(asteroid.center) {
                        asteroid.center.x = asteroid.center.x.truncatingRemainder(dividingBy: asteroidFieldBounds.width)
                        if asteroid.center.x < 0 { asteroid.center.x += asteroidFieldBounds.width }
                        asteroid.center.y = asteroid.center.y.truncatingRemainder(dividingBy: asteroidFieldBounds.height)
                        if asteroid.center.y < 0 { asteroid.center.y += asteroidFieldBounds.height }
                        self?.dynamicAnimator?.updateItem(usingCurrentState: asteroid)
                        self?.recaptureCount += 1
                    }
                }
            }
        }
    }
    
    private func stopRecapturingWaywardAsteroids() {
        recaptureTimer?.invalidate()
    }
    
}
