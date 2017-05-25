//
//  AsteroidBehavior.swift
//  SpaceshipGame
//
//  Created by shashank kannam on 5/25/17.
//  Copyright © 2017 developer. All rights reserved.
//

import UIKit

class AsteroidBehavior: UIDynamicBehavior {
    
    var asteriods = [AsteroidView]()
    
    private lazy var collider: UICollisionBehavior = {
        let behavior = UICollisionBehavior()
        behavior.collisionMode = .everything
        behavior.translatesReferenceBoundsIntoBoundary = true
        return behavior
    }()
    
    override init() {
        super.init()
        addChildBehavior(collider)
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
    }
    
    func removeAsteroid(_ asteriod: AsteroidView) {
        if let index = asteriods.index(of: asteriod) {
            asteriods.remove(at: index)
            collider.removeItem(asteriod)
        }
    }

    
}
