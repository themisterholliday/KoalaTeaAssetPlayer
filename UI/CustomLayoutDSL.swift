//
//  CustomLayoutDSL.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/11/19.
//

import Foundation

protocol LayoutAnchor {
    func constraint(equalTo anchor: Self, constant: CGFloat) -> NSLayoutConstraint
    func constraint(greaterThanOrEqualTo anchor: Self, constant: CGFloat) -> NSLayoutConstraint
    func constraint(lessThanOrEqualTo anchor: Self, constant: CGFloat) -> NSLayoutConstraint
}

protocol LayoutDimension {
    func constraint(equalToConstant c: CGFloat) -> NSLayoutConstraint
    func constraint(greaterThanOrEqualToConstant c: CGFloat) -> NSLayoutConstraint
    func constraint(lessThanOrEqualToConstant c: CGFloat) -> NSLayoutConstraint

    func constraint(equalTo anchor: Self, multiplier m: CGFloat, constant c: CGFloat) -> NSLayoutConstraint
    func constraint(greaterThanOrEqualTo anchor: Self, multiplier m: CGFloat, constant c: CGFloat) -> NSLayoutConstraint
    func constraint(lessThanOrEqualTo anchor: Self, multiplier m: CGFloat, constant c: CGFloat) -> NSLayoutConstraint
}

extension NSLayoutAnchor: LayoutAnchor {}

extension NSLayoutDimension: LayoutDimension {}

struct LayoutProperty<Anchor: LayoutAnchor> {
    fileprivate let anchor: Anchor
}

struct LayoutDimensionProperty<Anchor: LayoutAnchor & LayoutDimension> {
    fileprivate let anchor: Anchor
}

class LayoutProxy {
    lazy var leading = property(with: view.leadingAnchor)
    lazy var trailing = property(with: view.trailingAnchor)
    lazy var top = property(with: view.topAnchor)
    lazy var bottom = property(with: view.bottomAnchor)
    lazy var width = dimensionProperty(with: view.widthAnchor)
    lazy var height = dimensionProperty(with: view.heightAnchor)
    lazy var centerXAnchor = property(with: view.centerXAnchor)
    lazy var centerYAnchor = property(with: view.centerYAnchor)

    private let view: UIView

    fileprivate init(view: UIView) {
        self.view = view
    }

    private func property<A: LayoutAnchor>(with anchor: A) -> LayoutProperty<A> {
        return LayoutProperty(anchor: anchor)
    }

    private func dimensionProperty<A: LayoutDimension>(with anchor: A) -> LayoutDimensionProperty<A> {
        return LayoutDimensionProperty(anchor: anchor)
    }
}

extension LayoutProperty {
    func equal(to otherAnchor: Anchor, offsetBy constant: CGFloat = 0) {
        anchor.constraint(equalTo: otherAnchor, constant: constant).isActive = true
    }

    func greaterThanOrEqual(to otherAnchor: Anchor, offsetBy constant: CGFloat = 0) {
        anchor.constraint(greaterThanOrEqualTo: otherAnchor, constant: constant).isActive = true
    }

    func lessThanOrEqual(to otherAnchor: Anchor, offsetBy constant: CGFloat = 0) {
        anchor.constraint(lessThanOrEqualTo: otherAnchor, constant: constant).isActive = true
    }
}

extension LayoutDimensionProperty {
    func equal(to constant: CGFloat) {
        anchor.constraint(equalToConstant: constant).isActive = true
    }

    func greaterThanOrEqual(to constant: CGFloat) {
        anchor.constraint(greaterThanOrEqualToConstant: constant).isActive = true
    }

    func lessThanOrEqual(to constant: CGFloat) {
        anchor.constraint(lessThanOrEqualToConstant: constant).isActive = true
    }

    func equal(to otherAnchor: Anchor, multiplier m: CGFloat = 1.0, constant c: CGFloat = 0) {
        anchor.constraint(equalTo: otherAnchor, multiplier: m, constant: c).isActive = true
    }

    func greaterThanOrEqual(to otherAnchor: Anchor, multiplier m: CGFloat = 1.0, constant c: CGFloat = 0) {
        anchor.constraint(greaterThanOrEqualTo: otherAnchor, multiplier: m, constant: c).isActive = true
    }

    func lessThanOrEqual(to otherAnchor: Anchor, multiplier m: CGFloat = 1.0, constant c: CGFloat = 0) {
        anchor.constraint(lessThanOrEqualTo: otherAnchor, multiplier: m, constant: c).isActive = true
    }
}

internal extension UIView {
    func layout(using closure: (LayoutProxy) -> Void) {
        translatesAutoresizingMaskIntoConstraints = false
        closure(LayoutProxy(view: self))
    }

    func constrainEdgesToSuperView() {
        guard let superview = self.superview else { return }
        self.layout(using: {
            $0.top == superview.topAnchor
            $0.bottom == superview.bottomAnchor
            $0.leading == superview.leadingAnchor
            $0.trailing == superview.trailingAnchor
        })
    }

    func constrainCenterToSuperview() {
        guard let superview = self.superview else { return }
        self.layout(using: {
            $0.centerXAnchor == superview.centerXAnchor
            $0.centerYAnchor == superview.centerYAnchor
        })
    }

    func constrainEdges(to otherView: UIView) {
        self.layout(using: {
            $0.top == otherView.topAnchor
            $0.bottom == otherView.bottomAnchor
            $0.leading == otherView.leadingAnchor
            $0.trailing == otherView.trailingAnchor
        })
    }
}

// MARK: - Override Operators
func +<A: LayoutAnchor>(lhs: A, rhs: CGFloat) -> (A, CGFloat) {
    return (lhs, rhs)
}

func -<A: LayoutAnchor>(lhs: A, rhs: CGFloat) -> (A, CGFloat) {
    return (lhs, -rhs)
}

// MARK: - LayoutAnchor Operators
func ==<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, CGFloat)) {
    lhs.equal(to: rhs.0, offsetBy: rhs.1)
}

func ==<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: A) {
    lhs.equal(to: rhs)
}

func >=<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, CGFloat)) {
    lhs.greaterThanOrEqual(to: rhs.0, offsetBy: rhs.1)
}

func >=<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: A) {
    lhs.greaterThanOrEqual(to: rhs)
}

func <=<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, CGFloat)) {
    lhs.lessThanOrEqual(to: rhs.0, offsetBy: rhs.1)
}

func <=<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: A) {
    lhs.lessThanOrEqual(to: rhs)
}


// MARK: - LayoutDimension Operators
func ==<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: A) {
    lhs.equal(to: rhs)
}

func >=<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: A) {
    lhs.greaterThanOrEqual(to: rhs)
}

func <=<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: A) {
    lhs.lessThanOrEqual(to: rhs)
}

func ==<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: CGFloat) {
    lhs.equal(to: rhs)
}

func >=<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: CGFloat) {
    lhs.greaterThanOrEqual(to: rhs)
}

func <=<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: CGFloat) {
    lhs.lessThanOrEqual(to: rhs)
}
