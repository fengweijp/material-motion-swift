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

import Foundation

public class Rotatable: ViewInteraction {

  public lazy var gestureRecognizer = UIRotationGestureRecognizer()

  public func add(to reactiveView: ReactiveUIView, withRuntime runtime: MotionRuntime) {
    let rotation = reactiveView.reactiveLayer.rotation
    runtime.add(runtime.get(gestureRecognizer).rotated(from: rotation), to: rotation)
  }
}
