//
//  TYIndexView.swift
//  TYIndexView
//
//  Created by 王迪 on 2018/11/19.
//  Copyright © 2018年 王迪. All rights reserved.
//

import UIKit

@inline(__always) public func SCGetTextLayerCenterY(position: Float, margin: Float, space: Float) -> Float {
    return margin + (position + 1.0 / 2) * space;
}
@inline(__always) public func SCPositionOfTextLayerInY(y: Float, margin: Float, space: Float) -> Int {
    let position = (y - margin) / space - 1.0 / 2;
    if position <= 0 {return 0;}
    let bigger = ceil(position);
    let smaller = bigger - 1;
    let biggerCenterY = SCGetTextLayerCenterY(position: bigger, margin: margin, space: space);
    let smallerCenterY = SCGetTextLayerCenterY(position: smaller, margin: margin, space: space);
    return biggerCenterY + smallerCenterY > 2 * y ? Int(smaller) : Int(bigger);
}

class TYIndexView: UIControl {
    let key_frame = "frame";
    let key_contentOffset = "contentOffset";
    let key_center = "center";
    let tableView: UITableView;
    let config: TYIndexViewConfiguration;
    let kAnimationDuration = 0.25;
    var touchingIndexView: Bool = false;
    weak var delegate: TYIndexViewDelegate?;
    var subTextLayers = [CATextLayer]();
    var translucentForTableViewInNavigationBar: Bool = false;
    lazy var indicator: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0));
        label.layer.backgroundColor = config.indexItemBackgroundColor.cgColor;
        label.textColor = config.indicatorTextColor;
        label.font = config.indicatorTextFont;
        label.textAlignment = .center;
        label.isHidden = true;
        let radius = config.indicatorHeight / 2;
        let sinPI_4_Radius = sin(Double.pi / 4) * Double(radius);
        label.bounds = CGRect(x: 0.0, y: 0.0, width: 4 * sinPI_4_Radius, height: Double(2 * radius));
        
        let maskLayer = CAShapeLayer();
        maskLayer.path = drawIndicatorPath().cgPath;
        label.layer.mask = maskLayer;
        return label;
    }();
    var dataSource: [String]? {
        didSet {
            configSubLayersAndSubviews();
            configCurrentSection();
        }
    };
    var kSCIndexViewSpace: Float {
        get {
            return config.indexItemHeight + config.indexItemsSpace;
        }
    }
    var kSCIndexViewMargin: Float {
        get {
            return (Float(bounds.size.height) - kSCIndexViewSpace * Float((dataSource?.count)!)) / 2;
        }
    }
    var currentSection: Int = 0 {
        willSet {
            refreshTextLayer(selected: false);
        }
        didSet {
            refreshTextLayer(selected: true);
        }
    };
    init(frame: CGRect, tableView: UITableView, config: TYIndexViewConfiguration) {
        self.tableView = tableView;
        self.config = config;
        super.init(frame: frame);
        
        self.addSubview(indicator);
        
        tableView.addObserver(self, forKeyPath: key_frame, options: .new, context: UnsafeMutableRawPointer(bitPattern: 124));
        tableView.addObserver(self, forKeyPath: key_contentOffset, options: .new, context: UnsafeMutableRawPointer(bitPattern: 124));
        tableView.addObserver(self, forKeyPath: key_center, options: .new, context: UnsafeMutableRawPointer(bitPattern: 124));
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        tableView.removeObserver(self, forKeyPath: key_frame);
        tableView.removeObserver(self, forKeyPath: key_contentOffset);
        tableView.removeObserver(self, forKeyPath: key_center);
    }
    // MARK: - kvo
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context != UnsafeMutableRawPointer(bitPattern: 124) {
            return;
        }
        
        if keyPath == key_center || keyPath == key_frame {
            self.frame = self.tableView.frame;
            for (index, textLayer) in subTextLayers.enumerated() {
                textLayer.frame = CGRect(x: Double(Float(bounds.size.width) - config.indexItemRightMargin - config.indexItemHeight),
                                         y: Double(SCGetTextLayerCenterY(position: Float(index), margin: kSCIndexViewMargin, space: kSCIndexViewSpace) - config.indexItemHeight / 2),
                                         width: Double(config.indexItemHeight),
                                         height: Double(config.indexItemHeight));
            }
        } else if keyPath == key_contentOffset {
            onActionWithScroll();
        }
        
    }
    // MARK: - private
    private func drawIndicatorPath() -> UIBezierPath {
        let radius: Double = Double(config.indicatorHeight / 2);
        let sinPI_4_Radius = sin(Double.pi / 4) * radius;
        let margin = (sinPI_4_Radius * 2 - radius);
        
        
        let startPoint = CGPoint(x: margin + radius + sinPI_4_Radius, y: radius - sinPI_4_Radius);
        let trianglePoint = CGPoint(x: 4 * sinPI_4_Radius, y: radius);
        let centerPoint = CGPoint(x: margin + radius, y: radius);
        
        let bezierPath = UIBezierPath();
        bezierPath.move(to: startPoint);
        bezierPath.addArc(withCenter: centerPoint, radius: CGFloat(radius), startAngle: CGFloat(-Double.pi / 4), endAngle: CGFloat(Double.pi / 4), clockwise: false);
        bezierPath.addLine(to: trianglePoint);
        bezierPath.addLine(to: startPoint);
        bezierPath.close();
        return bezierPath;
    }
    
    private func configSubLayersAndSubviews() {
        let count = (dataSource?.count)! - subTextLayers.count;
        if count > 0 {
            for _ in 0..<count {
                let textLayer = CATextLayer();
                self.layer.addSublayer(textLayer);
                subTextLayers.append(textLayer);
            }
        } else {
            for _ in 0 ..< -count {
                subTextLayers.popLast()?.removeFromSuperlayer();
            }
        }
        
        CATransaction.begin();
        CATransaction.setDisableActions(true);
        
        for (index, textLayer) in subTextLayers.enumerated() {
            textLayer.frame = CGRect(x: Double(Float(bounds.size.width) - config.indexItemRightMargin - config.indexItemHeight),
                                     y: Double(SCGetTextLayerCenterY(position: Float(index), margin: kSCIndexViewMargin, space: kSCIndexViewSpace) - config.indexItemHeight / 2),
                                     width: Double(config.indexItemHeight),
                                     height: Double(config.indexItemHeight));
            textLayer.string = dataSource?[index];
            textLayer.fontSize = CGFloat(config.indexItemHeight * 0.8);
            textLayer.cornerRadius = CGFloat(config.indexItemHeight / 2);
            textLayer.alignmentMode = .center;
            textLayer.contentsScale = UIScreen.main.scale;
            textLayer.backgroundColor = config.indexItemBackgroundColor.cgColor;
            textLayer.foregroundColor = config.indicatorTextColor.cgColor;
        }
        
        CATransaction.commit();
    }
    
    private func hideIndicator(animated: Bool) {
        if indicator.isHidden {
            return;
        }
        if animated {
            indicator.alpha = 1;
            indicator.isHidden = false;
            UIView.animate(withDuration: kAnimationDuration, animations: {
                self.indicator.alpha = 0;
            }) { (Bool) in
                self.indicator.alpha = 1;
                self.indicator.isHidden = true;
            };
        } else {
            indicator.alpha = 1;
            indicator.isHidden = true;
        }
    }
    
    private func showIndicator(animated: Bool) {
        if !self.indicator.isHidden || self.currentSection < 0 || self.currentSection >= self.subTextLayers.count {
            return;
        }
        let textLayer = self.subTextLayers[self.currentSection];
        self.indicator.center = CGPoint(x: self.bounds.size.width - self.indicator.bounds.size.width / 2 - CGFloat(self.config.indicatorRightMargin), y: textLayer.position.y);
        self.indicator.text = (textLayer.string as! String);
        if animated {
            self.indicator.alpha = 0;
            self.indicator.isHidden = false;
            UIView.animate(withDuration: kAnimationDuration) {
                self.indicator.alpha = 1;
            };
        } else {
            self.indicator.alpha = 1;
            self.indicator.isHidden = false;
        }
    }
    
    private func configCurrentSection() {
        var section = Int.max;
        if let section = delegate?.sectionOfIndexView?(indexView: self, didScroll: tableView)  {
            if section > 0 && section != Int.max {
                return;
            }
        }
        let firstVisibleSection = self.tableView.indexPathsForVisibleRows?.first?.section;
        var insetHeight = 0;
        if !translucentForTableViewInNavigationBar {
            section = firstVisibleSection ?? Int.max;
        } else {
            insetHeight = Int(UIApplication.shared.statusBarFrame.size.height + 44);
            for (index, _) in subTextLayers.enumerated() {
                let sectionFrame = self.tableView.rect(forSection: index);
                if Int(sectionFrame.origin.y + sectionFrame.size.height - self.tableView.contentOffset.y) >= insetHeight {
                    section = index;
                    break;
                }
            }
        }
        if section < 0 {
            return;
        }
        self.currentSection = section;
    }
    
    private func onActionWithDidSelect() {
        if self.currentSection < 0 || self.currentSection >= self.subTextLayers.count {
            return;
        }
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: self.currentSection), at: .top, animated: false);
    }
    
    private func onActionWithScroll() {
        if self.touchingIndexView {
            self.tableView.panGestureRecognizer.isEnabled = false;
            self.tableView.panGestureRecognizer.isEnabled = true;
            return;
        }
        
        let isScrolling = self.tableView.isDragging || self.tableView.isDecelerating;
        if !isScrolling {
            return;
        }
        configCurrentSection();
    }
    
    private func refreshTextLayer(selected: Bool) {
        if self.currentSection < 0 || self.currentSection >= self.subTextLayers.count {
            return;
        }
        
        let textLayer = self.subTextLayers[self.currentSection];
        var bgcColor, foreColor : UIColor?;
        if selected {
            bgcColor = self.config.indexItemSelectedBackgroundColor;
            foreColor = self.config.indexItemSelectedTextColor;
        } else {
            bgcColor = self.config.indexItemBackgroundColor;
            foreColor = self.config.indexItemTextColor;
        }
        CATransaction.begin();
        CATransaction.setDisableActions(true);
        textLayer.backgroundColor = bgcColor?.cgColor;
        textLayer.foregroundColor = foreColor?.cgColor;
        CATransaction.commit();
        
    }
    
    
    // MARK: - UITouch adn UIEvent
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if touchingIndexView {
            return true;
        }
        if subTextLayers.count == 0 {
            return false;
        }
        let firstLayer = subTextLayers.first;
        let lastLayer = subTextLayers.last;
        let space = config.indexItemRightMargin * 2;
        if point.x > self.bounds.width - CGFloat(space) - CGFloat(self.config.indexItemHeight)
            && point.y > firstLayer!.frame.minY - CGFloat(space)
            && point.y < lastLayer!.frame.maxY + CGFloat(space) {
            return true;
        }
        return false;
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        self.touchingIndexView = true;
        let location = touch.location(in: self);
        let currentPosition = SCPositionOfTextLayerInY(y: Float(location.y), margin: kSCIndexViewMargin, space: kSCIndexViewSpace);
        
        if currentPosition < 0 || currentPosition >= (dataSource?.count)! {
            return true;
        }
        hideIndicator(animated: false);
        self.currentSection = currentPosition;
        hideIndicator(animated: true);
        
        onActionWithDidSelect();
        
        self.delegate?.indexView?(indexView: self, atSection: self.currentSection);
        
        return true;
    }
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        self.touchingIndexView = true;
        let location = touch.location(in: self);
        var currentPosition = SCPositionOfTextLayerInY(y: Float(location.y), margin: kSCIndexViewMargin, space: kSCIndexViewSpace);
        
        if currentPosition < 0 {
            currentPosition = 0;
        } else if currentPosition >= (self.dataSource?.count)! {
            currentPosition = (self.dataSource?.count)! - 1;
        }
        
        if currentPosition == self.currentSection {
            return true;
        }
        
        hideIndicator(animated: false);
        self.currentSection = currentPosition;
        showIndicator(animated: false);
        
        onActionWithDidSelect()
        
        self.delegate?.indexView?(indexView: self, atSection: self.currentSection);
        
        return true;
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        self.touchingIndexView = false;
        hideIndicator(animated: true);
    }
    
    override func cancelTracking(with event: UIEvent?) {
        self.touchingIndexView = false;
        hideIndicator(animated: true);
    }
}



struct TYIndexViewConfiguration {
    let indicatorBackgroundColor: UIColor;
    let indicatorTextColor: UIColor;
    let indicatorTextFont: UIFont;
    let indicatorHeight: Float;
    let indicatorRightMargin: Float;
    let indicatorCornerRadius: Float;
    let indexItemBackgroundColor: UIColor;
    let indexItemTextColor: UIColor;
    let indexItemSelectedBackgroundColor: UIColor;
    let indexItemSelectedTextColor: UIColor;
    let indexItemHeight: Float;
    let indexItemRightMargin: Float;
    let indexItemsSpace: Float;
    
    init() {
        indicatorBackgroundColor = UIColor.blue       // 指示器背景颜色
        indicatorTextColor = UIColor.white      // 指示器文字颜色
        indicatorTextFont = UIFont.systemFont(ofSize: 40)    // 指示器文字字体
        indicatorHeight = 80                      // 指示器高度
        indicatorRightMargin = 32                      // 指示器距离右边屏幕距离（default有效）
        indicatorCornerRadius = 20                      // 指示器圆角半径（centerToast有效）
        indexItemBackgroundColor = UIColor.blue      // 索引元素背景颜色
        indexItemTextColor = UIColor.white       // 索引元素文字颜色
        indexItemSelectedBackgroundColor = UIColor.red       // 索引元素选中时背景颜色
        indexItemSelectedTextColor = UIColor.white      // 索引元素选中时文字颜色
        indexItemHeight = 13                      // 索引元素高度
        indexItemRightMargin = 4                       // 索引元素距离右边屏幕距离
        indexItemsSpace = 10
    }
}



@objc protocol TYIndexViewDelegate {
    @objc optional func indexView(indexView: TYIndexView, atSection: Int);
    @objc optional func sectionOfIndexView(indexView: TYIndexView, didScroll: UITableView) -> Int;
}

