//
//  AsteroidsViewController.swift
//  SpaceshipGame
//
//  Created by shashank kannam on 5/25/17.
//  Copyright © 2017 developer. All rights reserved.
//

import UIKit

class AsteroidsViewController: UIViewController {
    
    private var asteriodField: AsteroidFieldView!
    private var spaceship: SpaceshipView!
    
    private var asteroidBehavior = AsteroidBehavior()
    
    private lazy var animator: UIDynamicAnimator = UIDynamicAnimator(referenceView:self.asteriodField)
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initializeIfNeeded()
        animator.addBehavior(asteroidBehavior)
        asteroidBehavior.pushAllAsteriods()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        animator.removeBehavior(asteroidBehavior)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        asteriodField?.center = view.bounds.mid
        repositionShip()
    }
    
    @IBAction func fire(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began,.changed:
            spaceship.direction = (sender.location(in: view) - spaceship.center).angle
            burn()
        case .ended: endBurn()
        default:
            break
        }
    }
    
    private func burn() {
        spaceship.enginesAreFiring = true
        asteroidBehavior.acceleration.angle = spaceship.direction - CGFloat.pi
        asteroidBehavior.acceleration.magnitude = Constants.burnAcceleration
    }
    
    private func endBurn() {
        spaceship.enginesAreFiring = false
        asteroidBehavior.acceleration.magnitude = 0.0
    }
    
    private func repositionShip() {
        if asteriodField != nil {
            spaceship.center = asteriodField.center
            asteroidBehavior.addBoundary(spaceship.shieldBoundary(in: asteriodField), named: Constants.shipBoundaryName){
                [weak self] in
                if let spaceship = self?.spaceship, !((self?.spaceship?.shieldIsActive)!) {
                    self?.spaceship.shieldIsActive = true
                    spaceship.shieldLevel -= Constants.Shield.activationCost
                    Timer.scheduledTimer(withTimeInterval: Constants.Shield.duration, repeats: false) { timer in
                        self?.spaceship.shieldIsActive = false
                        spaceship.shieldLevel = spaceship.shieldLevel == 0 ? 100 : spaceship.shieldLevel
                    }
                }
            }
        }
    }
    
    private func initializeIfNeeded() {
        if asteriodField == nil {
            asteriodField = AsteroidFieldView(frame: CGRect(center: view.bounds.mid, size: view.bounds.size * Constants.asteroidFieldMagnitude))
            view.addSubview(asteriodField)
            let shipSize = view.bounds.size.minEdge * Constants.shipSizeToMinBoundsEdgeRatio
            spaceship = SpaceshipView(frame: CGRect(squareCenteredAt: asteriodField.center, size: shipSize)) 
            view.addSubview(spaceship)
            repositionShip()
            asteriodField.addAsteroids(count: Constants.initialAsteroidCount, exclusionZone: spaceship.convert(spaceship.bounds, to: asteriodField))
            asteriodField.asteroidBehavior = asteroidBehavior
        }
    }
}

// MARK: Constants

private struct Constants {
    static let initialAsteroidCount = 20
    static let shipBoundaryName = "Ship"
    static let shipSizeToMinBoundsEdgeRatio: CGFloat = 1/5
    static let asteroidFieldMagnitude: CGFloat = 10             // as a multiple of view.bounds.size
    static let normalizedDistanceOfShipFromEdge: CGFloat = 0.2
    static let burnAcceleration: CGFloat = 0.07                 // points/s/s
    struct Shield {
        static let duration: TimeInterval = 1.0       // how long shield stays up
        static let updateInterval: TimeInterval = 0.2 // how often we update shield level
        static let regenerationRate: Double = 5       // per second
        static let activationCost: Double = 15        // per activation
        static var regenerationPerUpdate: Double
        { return Constants.Shield.regenerationRate * Constants.Shield.updateInterval }
        static var activationCostPerUpdate: Double
        { return Constants.Shield.activationCost / (Constants.Shield.duration/Constants.Shield.updateInterval) }
    }
    static let defaultShipDirection: [UIInterfaceOrientation:CGFloat] = [
        .portrait : CGFloat.up,
        .portraitUpsideDown : CGFloat.down,
        .landscapeLeft : CGFloat.right,
        .landscapeRight : CGFloat.left
    ]
    static let normalizedAsteroidFieldCenter: [UIInterfaceOrientation:CGPoint] = [
        .portrait : CGPoint(x: 0.5, y: 1.0-Constants.normalizedDistanceOfShipFromEdge),
        .portraitUpsideDown : CGPoint(x: 0.5, y: Constants.normalizedDistanceOfShipFromEdge),
        .landscapeLeft : CGPoint(x: Constants.normalizedDistanceOfShipFromEdge, y: 0.5),
        .landscapeRight : CGPoint(x: 1.0-Constants.normalizedDistanceOfShipFromEdge, y: 0.5),
        .unknown : CGPoint(x: 0.5, y: 0.5)
    ]
}
