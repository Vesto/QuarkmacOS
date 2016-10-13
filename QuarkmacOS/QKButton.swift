//
//  QKButton.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import QuarkExports

final class QKButton: NSButton, Button {
    convenience public init(title: String) {
        self.init(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        self.title = title
    }
}
