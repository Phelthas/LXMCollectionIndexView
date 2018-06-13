//
//  LXMCollectionIndexView.swift
//  LXMCollectionIndexView
//
//  Created by luxiaoming on 2018/6/11.
//

import UIKit

private let kLXMCollectionIndexViewAnimationDuration: Double = 0.25

open class LXMCollectionIndexView: UIView {

    public var dataSource = [String]()
    
    fileprivate weak var collectionView: UICollectionView?
    
    fileprivate var textLayerArray = [LXMTextLayer]()
    
    fileprivate lazy var displayLayer: CATextLayer = {
        let displayLayer = CATextLayer()
        displayLayer.bounds = CGRect(x: 0, y: 0, width: 60, height: 60)
        displayLayer.backgroundColor = UIColor.lightGray.cgColor
        displayLayer.fontSize = 30
        displayLayer.alignmentMode = kCAAlignmentCenter
        displayLayer.cornerRadius = 30
        displayLayer.masksToBounds = true
        displayLayer.opacity = 0
        
        return displayLayer
    }()
    
    
    
    fileprivate var textLayerSpacing: CGFloat {
        return floor(self.bounds.height - CGFloat(dataSource.count) * indexItemSize.height) / 2
    }
    
    fileprivate var touchedIndex: Int = 0 {
        didSet {
            if touchedIndex != oldValue {
                if #available(iOS 10.0, *) {
                    self.impactFeedbackGenerator.impactOccurred()
                }
            }
        }
    }
    
    private var _impactFeedbackGenerator: Any? = nil
    @available(iOS 10.0, *)
    fileprivate var impactFeedbackGenerator: UIImpactFeedbackGenerator {
        if _impactFeedbackGenerator == nil {
            _impactFeedbackGenerator = UIImpactFeedbackGenerator()
        }
        return _impactFeedbackGenerator as! UIImpactFeedbackGenerator
    }
    
    fileprivate var indexItemSize: CGSize = CGSize(width: 15, height: 15)
    
    public init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init(frame: collectionView.frame)
        self.backgroundColor = UIColor.clear

    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - PrivateMethod
private extension LXMCollectionIndexView {
    
    func setupUI() {
        
        var layerArray = [LXMTextLayer]()
        for i in 0 ..< dataSource.count {
            let title = dataSource[i]
            let textLayer = LXMTextLayer()
            textLayer.index = i
            textLayer.fontSize = 12
            textLayer.alignmentMode = kCAAlignmentCenter
            textLayer.string = title
            textLayer.frame = frame(forTextLayer: textLayer)
            textLayer.cornerRadius = indexItemSize.width / 2
            textLayer.masksToBounds = true
            textLayer.backgroundColor = UIColor.lightGray.cgColor
            self.layer.addSublayer(textLayer)
            layerArray.append(textLayer)
        }
        textLayerArray = layerArray
        
        self.layer.addSublayer(displayLayer)
    }
    
    func frame(forTextLayer textLayer: LXMTextLayer) -> CGRect {
        let width = indexItemSize.width
        let height = indexItemSize.height
        return CGRect(x: self.bounds.width - width,
                      y: textLayerSpacing + CGFloat(textLayer.index) * height,
                      width: width,
                      height: height)
    }
    
    func showDisplayLayer(forTextLayer textLayer: LXMTextLayer) {
        //直接修改calayer属性是有默认的隐式动画的，可以用CATransaction关闭隐式动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        displayLayer.position = CGPoint(x: self.bounds.width - indexItemSize.width - 20 - 30, y: textLayer.position.y)
        displayLayer.string = textLayer.string
        displayLayer.opacity = 1
        CATransaction.commit()
    }
    
    func hideDisplayLayer() {
        displayLayer.opacity = 0
    }
    
    func scrollCollectionView(toTextLayer textLayer: LXMTextLayer, animated: Bool) {
        let indexPath = IndexPath(item: 0, section: textLayer.index)
        collectionView?.scrollToItem(at: indexPath, at: .top, animated: animated)
    }
    
    
}

// MARK: - Lifecycle
extension LXMCollectionIndexView {
    
    open override func layoutSubviews() {
        guard let collectionView = collectionView else { return }
        self.frame = CGRect(origin: CGPoint.zero, size: collectionView.frame.size)
        
        if self.layer.sublayers != nil {
            for textLayer in textLayerArray {
                textLayer.frame = frame(forTextLayer: textLayer)
            }
        } else {
            setupUI()
        }
    }
    
    
    
    
}


// MARK: - touch事件
extension LXMCollectionIndexView {
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        if view == self {
            let rect = CGRect(x: self.bounds.width - indexItemSize.width, y: textLayerSpacing, width: indexItemSize.width, height: self.bounds.height - textLayerSpacing * 2)
            if rect.contains(point) {
                return self
            } else {
                return nil
            }
        } else {
            return view
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        showChanges(forTouches: touches)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        hideDisplayLayer()
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        showChanges(forTouches: touches)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        hideDisplayLayer()
    }
    
    func textLayer(forTouches touches: Set<UITouch>) -> LXMTextLayer? {
        guard let touch = touches.first else { return nil }
        let touchPoint = touch.location(in: self)
        
        /// 为了达到微信的效果，即开始后就算滑动到非索引区域也行，这里不能用frame的包含，用了一条横线是否与textLayer相交来判断
        let touchLine = CGRect(x: 0, y: touchPoint.y, width: self.bounds.width, height: 1)
        for textLayer in textLayerArray {
            if touchLine.intersects(textLayer.frame) {
                return textLayer
            }
        }
        return nil
    }
    
    func showChanges(forTouches touches: Set<UITouch>) {
        guard let touchedLayer = textLayer(forTouches: touches) else { return }
        touchedIndex = touchedLayer.index
        showDisplayLayer(forTextLayer: touchedLayer)
        scrollCollectionView(toTextLayer: touchedLayer, animated: false)
        
    }
    
}






class LXMTextLayer: CATextLayer {
    var index: Int = 0
}

