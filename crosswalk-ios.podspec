# Copyright (c) 2015 Intel Corporation. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

Pod::Spec.new do |s|
  s.name             = 'crosswalk-ios'
  s.version          = '1.2.0'
  s.summary          = 'Crosswalk Project for iOS provides a web runtime for sophisticated iOS native or hybrid applications.'
  s.homepage         = 'https://github.com/crosswalk-project/crosswalk-ios'
  s.license          = { :type => 'BSD', :file => "LICENSE" }
  s.author           = { 'Zhenyu Liang' => 'zhenyu.liang@intel.com', 'Jonathan Dong' => 'jonathan.dong@intel.com' }
  s.source           = { :git => 'https://github.com/crosswalk-project/crosswalk-ios.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/xwalk_project'

  s.platform = :ios, '8.1'
  s.ios.deployment_target = '8.1'
  s.requires_arc = true
  s.module_name = 'XWalkView'

  s.source_files = 'XWalkView/XWalkView/*.{h,m,swift}'
  s.resource = 'XWalkView/XWalkView/crosswalk.js'
  s.dependency 'GCDWebServer', '>= 3.2'

end

