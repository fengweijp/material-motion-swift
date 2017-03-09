/*
 Copyright 2016-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit
import MaterialMotionStreams

enum TossDirection {
  case none
  case left
  case right
}

class TossableStackedCard: Interaction {
  public let tossDirection = createProperty("tossDirection", withInitialValue: TossDirection.none)

  init(relativeView: UIView, previousCard: TossableStackedCard? = nil, rotation: CGFloat) {
    self.relativeView = relativeView
    self.previousCard = previousCard
    self.rotation = rotation

    self.dragGesture = UIPanGestureRecognizer()
  }

  func add(to view: UIView, withRuntime runtime: MotionRuntime, constraints: Void?) {
    let reactiveView = runtime.get(view)
    let position = reactiveView.centerX
    self.position = position

    view.addGestureRecognizer(dragGesture)

    let destination = createProperty("destination", withInitialValue: relativeView.bounds.midX)

    let drag = runtime.get(dragGesture)
    runtime.connect(
      drag
        .onRecognitionState(.ended)
        .velocity(in: relativeView)
        .x()
        .thresholdRange(min: -500, max: 500)
        .rewrite([.whenBelow: .left, .whenWithin: .none, .whenAbove: .right]),
      to: tossDirection)

    let destinationStream =
      tossDirection
        .rewrite([
          .none: relativeView.bounds.midX,
          .left: -view.bounds.width,
          .right: relativeView.bounds.width + view.bounds.width
          ])
    runtime.connect(destinationStream, to: destination)

    let gestureEnabledStream = tossDirection.rewrite([
      .none: true,
      .left: false,
      .right: false
      ]
    )
    runtime.connect(gestureEnabledStream, to: drag.isEnabled)
    runtime.connect(gestureEnabledStream, to: reactiveView.isUserInteractionEnabled)

    let attachment = Spring<CGFloat>(threshold: 1, system: pop)
    runtime.connect(drag.velocityOnReleaseStream(in: view).x(), to: attachment.initialVelocity)
    runtime.connect(destination, to: attachment.destination)

    let draggable = drag.translated(from: reactiveView.center, in: relativeView).x()
    runtime.connect(draggable, to: reactiveView.centerX)
    runtime.connect(drag.atRest(), to: attachment.enabled)
    runtime.add(attachment, to: reactiveView.centerX)

    let radians = CGFloat(Double.pi / 180.0 * 15.0)
    let rotationStream =
      reactiveView.centerX
        .offset(by: -relativeView.bounds.width / 2)
        .normalized(by: relativeView.bounds.width / 2)
        .scaled(by: radians)

    let reactiveLayer = reactiveView.reactiveLayer

    // Previous card
    if let previousCard = previousCard {
      dragGesture.require(toFail: previousCard.dragGesture)
      let nextRotationStream =
        previousCard.position!
          .distance(from: relativeView.bounds.width / 2)
          .normalized(by: relativeView.bounds.width / 2)
          .upperBound(1)
          .subtracted(from: 1)
          .scaled(by: rotation)
      runtime.connect(nextRotationStream.valve(openWhenTrue: drag.atRest()), to: reactiveLayer.rotation)
      runtime.connect(rotationStream.valve(openWhenTrue: drag.active()), to: reactiveLayer.rotation)
    } else {
      runtime.connect(rotationStream, to: reactiveLayer.rotation)
    }
  }

  private let relativeView: UIView
  private let dragGesture: UIPanGestureRecognizer
  private let previousCard: TossableStackedCard?
  private var position: ReactiveProperty<CGFloat>?
  private let rotation: CGFloat
}

public class SwipeExampleViewController: UIViewController {

  var runtime: MotionRuntime!
  var views: [UIView] = []
  var queue: [TossableStackedCard] = []
  public override func viewDidLoad() {
    super.viewDidLoad()

    runtime = MotionRuntime(containerView: view)

    view.backgroundColor = .white

    (0 ..< 10).forEach { _ in
      dequeueCard()
    }
  }

  var lastRotation: CGFloat = CGFloat(Double.pi / 180.0 * 2)
  func dequeueCard() {
    let rotation = -lastRotation

    let card = UIView(frame: .init(x: 16, y: 16 + 64,
                                    width: view.bounds.size.width - 32,
                                    height: view.bounds.size.height - 32 - 64))
    card.layer.borderWidth = 0.5
    card.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
    card.backgroundColor = UIColor(hue: CGFloat(arc4random_uniform(256)) / 256.0,
                                   saturation: 1,
                                   brightness: 1,
                                   alpha: 1)

    let interaction = TossableStackedCard(relativeView: view, previousCard: queue.last, rotation: rotation)
    runtime.add(interaction, to: card)

    lastRotation = rotation

    if let last = views.last {
      view.insertSubview(card, belowSubview: last)
    } else {
      view.addSubview(card)
    }
    queue.append(interaction)
    views.append(card)
  }
}
