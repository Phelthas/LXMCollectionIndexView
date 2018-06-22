//
//  TestSectionHeaderView.swift
//  LXMCollectionIndexView_Example
//
//  Created by luxiaoming on 2018/6/22.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit

class TestSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "TestSectionHeaderView"
    
    
    /// 注意titleLabel的约束，如果是相对于safeArea的，那当TestSectionHeaderView接近屏幕边缘的时候可能会有特殊情况出现
    @IBOutlet weak var titleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = UIColor.white
    }
    
}
