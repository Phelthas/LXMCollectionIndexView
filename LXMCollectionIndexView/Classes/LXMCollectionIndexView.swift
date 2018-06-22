//
//  LXMCollectionIndexView.swift
//  LXMCollectionIndexView
//
//  Created by luxiaoming on 2018/6/11.
//

import UIKit

private let kLXMCollectionIndexViewAnimationDuration: Double = 0.25
private var kLXMCollectionIndexViewContent: CChar = 0
private let kLXMCollectionIndexViewContentOffsetKeyPath = #keyPath(UICollectionView.contentOffset)

open class LXMCollectionIndexView: UIView {

    public var dataSource = [String]() {
        didSet {
            if dataSource != oldValue {
                clearTextLayers()
            }
        }
    }
    
    public var config: LXMCollectionIndexViewConfiguration {
        didSet {
            if config != oldValue {
                clearTextLayers()
            }
        }
    }
    
    fileprivate weak var collectionView: UICollectionView?
    
    fileprivate var textLayerArray = [LXMTextLayer]()
    
    fileprivate lazy var indicator: UIView = {
        let indicatorRadius = config.indicatorRadius
        let indicator = UIView()
        indicator.frame = CGRect(x: 0, y: 0, width: indicatorRadius * 3, height: indicatorRadius * 2)
        indicator.backgroundColor = config.indicatorBackgroundColor
        indicator.alpha = 0
        indicator.addSubview(bigTextLabel)
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = indicator.frame
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 2.414 * indicatorRadius, y: indicatorRadius))
        path.addLine(to: CGPoint(x: 1.707 * indicatorRadius, y: 1.707 * indicatorRadius))
        // 注意，这个画线的方法与数学中的坐标系不一样，0在3点钟方向，pi/2在6点钟方向，pi在9点钟方向。。。具体可以看文档
        // 这里是以圆的0.25pi处和1.75pi处的切线的交点为箭头位置
        path.addArc(withCenter: CGPoint(x: indicatorRadius, y: indicatorRadius), radius: indicatorRadius, startAngle: 0.25 * CGFloat.pi, endAngle: 1.75 * CGFloat.pi, clockwise: true)
        path.close()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.red.cgColor
        maskLayer.backgroundColor = UIColor.clear.cgColor
        indicator.layer.mask = maskLayer
        return indicator
    }()
    
    /// CATextLayer的内容默认是上对齐的，不如用label方便
    fileprivate lazy var bigTextLabel: UILabel = {
        let indicatorRadius = config.indicatorRadius
        let label = UILabel()
        label.frame = CGRect(x: 0, y: 0, width: indicatorRadius * 2, height: indicatorRadius * 2)
        label.backgroundColor = config.indicatorBackgroundColor
        label.font = UIFont.systemFont(ofSize: ceil(indicatorRadius * 1.414))
        label.textAlignment = .center
        label.layer.cornerRadius = indicatorRadius
        label.layer.masksToBounds = true
        label.textColor = config.indicatorTextColor
        return label
    }()
    
    fileprivate var layerTopSpacing: CGFloat {
        let count = CGFloat(dataSource.count)
        return floor(self.bounds.height - count * config.itemSize.height - config.itemSpacing * (count - 1)) / 2
    }
    
    fileprivate var isTouched: Bool = false
    
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
    
    public init(collectionView: UICollectionView, config: LXMCollectionIndexViewConfiguration = LXMCollectionIndexViewConfiguration()) {
        self.collectionView = collectionView
        self.config = config
        super.init(frame: collectionView.frame)
        self.backgroundColor = UIColor.clear
        collectionView.addObserver(self, forKeyPath: kLXMCollectionIndexViewContentOffsetKeyPath, options: .new, context: &kLXMCollectionIndexViewContent)
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.collectionView?.removeObserver(self, forKeyPath: kLXMCollectionIndexViewContentOffsetKeyPath)
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
            textLayer.cornerRadius = config.itemSize.width / 2
            textLayer.masksToBounds = true
            self.layer.addSublayer(textLayer)
            layerArray.append(textLayer)
        }
        textLayerArray = layerArray
        updateTextLayers(forSelectedIndex: 0)
        
        self.addSubview(indicator)
    }
    
    func frame(forTextLayer textLayer: LXMTextLayer) -> CGRect {
        let width = config.itemSize.width
        let height = config.itemSize.height
        return CGRect(x: self.bounds.width - width,
                      y: layerTopSpacing + CGFloat(textLayer.index) * height + config.itemSpacing * CGFloat(textLayer.index),
                      width: width,
                      height: height)
    }
    
    func showIndicator(forTextLayer textLayer: LXMTextLayer) {
        //直接修改calayer属性是有默认的隐式动画的，可以用CATransaction关闭隐式动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        indicator.center = CGPoint(x: self.bounds.width - indicator.bounds.width / 2 - config.itemSize.width, y: textLayer.position.y)
        bigTextLabel.text = textLayer.string as? String
        indicator.alpha = 1
        CATransaction.commit()
    }
    
    func hideIndicator() {
        indicator.alpha = 0
    }
    
    func scrollCollectionView(toTextLayer textLayer: LXMTextLayer, animated: Bool) {
        guard let collectionView = collectionView else { return }
        let indexPath = IndexPath(item: 0, section: textLayer.index)
        if let attributes = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionElementKindSectionHeader, at: indexPath),
            let cellAttributes = collectionView.layoutAttributesForItem(at: indexPath) {
            var targetPoint = cellAttributes.frame.origin
            targetPoint.y = targetPoint.y - attributes.frame.size.height
            // 用这种计算方法可以不考虑layout的sectionHeadersPinToVisibleBounds属性
            // 如果直接用attributes的frame需要考虑sectionHeadersPinToVisibleBounds
            collectionView.setContentOffset(targetPoint, animated: animated)
        } else {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
        }
        
    }
    
    func updateTextLayers(forSelectedIndex index: Int) {
        for textLayer in textLayerArray {
            if textLayer.index == index {
                textLayer.backgroundColor = config.itemSelectedBackgroundColor.cgColor
                textLayer.foregroundColor = config.itemSelectedTextColor.cgColor
            } else {
                textLayer.backgroundColor = config.itemBackgroundColor.cgColor
                textLayer.foregroundColor = config.itemTextColor.cgColor
            }
        }
    }
    
    func clearTextLayers() {
        if let sublayers = self.layer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
        }
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
    
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let context = context, context == &kLXMCollectionIndexViewContent,
            let keyPath = keyPath, keyPath == kLXMCollectionIndexViewContentOffsetKeyPath {
            guard isTouched == false else { return }
            if let indexPathArray = self.collectionView?.indexPathsForVisibleItems {
                let minIndexPath = indexPathArray.min { (one, two) -> Bool in
                    return one.section <= two.section
                }
                if let temp = minIndexPath?.section {
                    updateTextLayers(forSelectedIndex: temp)
                }
            }
            
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
}


// MARK: - touch事件
extension LXMCollectionIndexView {
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        if view == self {
            let rect = CGRect(x: self.bounds.width - config.itemSize.width, y: layerTopSpacing, width: config.itemSize.width, height: self.bounds.height - layerTopSpacing * 2)
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
        isTouched = true
        showChanges(forTouches: touches)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        hideIndicator()
        isTouched = false
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouched = true
        showChanges(forTouches: touches)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        hideIndicator()
        isTouched = false
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
        if touchedIndex == touchedLayer.index { return }
        updateTextLayers(forSelectedIndex: touchedLayer.index)
        touchedIndex = touchedLayer.index
        showIndicator(forTextLayer: touchedLayer)
        scrollCollectionView(toTextLayer: touchedLayer, animated: false)
        
    }
    
}






public class LXMTextLayer: CATextLayer {
    var index: Int = 0
}

public class LXMCollectionIndexViewConfiguration: NSObject {
    var itemSize: CGSize = CGSize(width: 15, height: 15)
    var itemSpacing: CGFloat = 0
    var itemBackgroundColor: UIColor = UIColor.clear
    var itemTextColor: UIColor = UIColor.darkText
    var itemSelectedBackgroundColor: UIColor = UIColor.lightGray
    var itemSelectedTextColor: UIColor = UIColor.white
    var indicatorRadius: CGFloat = 30 //根据这个数值来绘制displayLayer，
    var indicatorBackgroundColor: UIColor = UIColor.lightGray
    var indicatorTextColor: UIColor = UIColor.white
    
}
