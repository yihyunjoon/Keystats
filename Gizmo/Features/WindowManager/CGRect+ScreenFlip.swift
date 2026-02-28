import AppKit

extension CGPoint {
  var screenFlipped: CGPoint {
    guard let referenceScreen = NSScreen.screens.first else { return self }
    return CGPoint(x: x, y: referenceScreen.frame.maxY - y)
  }
}

extension CGRect {
  var screenFlipped: CGRect {
    guard !isNull else { return self }
    guard let referenceScreen = NSScreen.screens.first else { return self }
    return CGRect(
      x: origin.x,
      y: referenceScreen.frame.maxY - maxY,
      width: width,
      height: height
    )
  }

  func intersectionRatio(with rect: CGRect) -> CGFloat {
    let intersection = self.intersection(rect)
    guard !intersection.isNull else { return 0 }

    let selfArea = width * height
    guard selfArea > 0 else { return 0 }

    return (intersection.width * intersection.height) / selfArea
  }
}
