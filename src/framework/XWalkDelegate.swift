// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

@objc public protocol XWalkDelegate {
    optional func didEstablishChannel(channel: XWalkChannel)
    optional func didGenerateStub(stub: String) -> String
    optional func didBindExtension(namespace: String)
}
