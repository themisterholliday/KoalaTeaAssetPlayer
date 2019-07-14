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
    @discardableResult func equal(to otherAnchor: Anchor, offsetBy constant: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = anchor.constraint(equalTo: otherAnchor, constant: constant)
        constraint.isActive = true
        return constraint
    }

    @discardableResult func  greaterThanOrEqual(to otherAnchor: Anchor, offsetBy constant: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = anchor.constraint(greaterThanOrEqualTo: otherAnchor, constant: constant)
        constraint.isActive = true
        return constraint
    }

    @discardableResult func  lessThanOrEqual(to otherAnchor: Anchor, offsetBy constant: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = anchor.constraint(lessThanOrEqualTo: otherAnchor, constant: constant)
        constraint.isActive = true
        return constraint
    }
}

extension LayoutDimensionProperty {
    @discardableResult func  equal(to constant: CGFloat) -> NSLayoutConstraint {
        let constraint = anchor.constraint(equalToConstant: constant)
        constraint.isActive = true
        return constraint
    }

    @discardableResult func  greaterThanOrEqual(to constant: CGFloat) -> NSLayoutConstraint {
        let constraint = anchor.constraint(greaterThanOrEqualToConstant: constant)
        constraint.isActive = true
        return constraint
    }

    @discardableResult func  lessThanOrEqual(to constant: CGFloat) -> NSLayoutConstraint {
        let constraint = anchor.constraint(lessThanOrEqualToConstant: constant)
        constraint.isActive = true
        return constraint
    }

    @discardableResult func  equal(to otherAnchor: Anchor, multiplier m: CGFloat = 1.0, constant c: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = anchor.constraint(equalTo: otherAnchor, multiplier: m, constant: c)
        constraint.isActive = true
        return constraint
    }

    @discardableResult func  greaterThanOrEqual(to otherAnchor: Anchor, multiplier m: CGFloat = 1.0, constant c: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = anchor.constraint(greaterThanOrEqualTo: otherAnchor, multiplier: m, constant: c)
        constraint.isActive = true
        return constraint
    }

    @discardableResult func  lessThanOrEqual(to otherAnchor: Anchor, multiplier m: CGFloat = 1.0, constant c: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = anchor.constraint(lessThanOrEqualTo: otherAnchor, multiplier: m, constant: c)
        constraint.isActive = true
        return constraint
    }
}

internal extension UIView {
    func layout(_ closure: (LayoutProxy) -> Void) {
        translatesAutoresizingMaskIntoConstraints = false
        closure(LayoutProxy(view: self))
    }

    func returnedLayout(_ closure: (LayoutProxy) -> [NSLayoutConstraint]) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        return closure(LayoutProxy(view: self))
    }

    @discardableResult func constrainEdgesToSuperView() -> [NSLayoutConstraint]? {
        guard let superview = self.superview else { return nil }
        return self.returnedLayout {
            return [
                $0.top == superview.topAnchor,
                $0.bottom == superview.bottomAnchor,
                $0.leading == superview.leadingAnchor,
                $0.trailing == superview.trailingAnchor,
            ]
        }
    }

    @discardableResult func constrainCenterToSuperview() -> [NSLayoutConstraint]? {
        guard let superview = self.superview else { return nil }
        return self.returnedLayout {
            return [
                $0.centerXAnchor == superview.centerXAnchor,
                $0.centerYAnchor == superview.centerYAnchor,
            ]
        }
    }

    @discardableResult func constrainEdges(to otherView: UIView) -> [NSLayoutConstraint] {
        return self.returnedLayout {
            return [
                $0.top == otherView.topAnchor,
                $0.bottom == otherView.bottomAnchor,
                $0.leading == otherView.leadingAnchor,
                $0.trailing == otherView.trailingAnchor,
            ]
        }
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
@discardableResult func ==<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, CGFloat)) -> NSLayoutConstraint {
    return lhs.equal(to: rhs.0, offsetBy: rhs.1)
}

@discardableResult func ==<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: A) -> NSLayoutConstraint {
    return lhs.equal(to: rhs)
}

@discardableResult func >=<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, CGFloat)) -> NSLayoutConstraint {
    return lhs.greaterThanOrEqual(to: rhs.0, offsetBy: rhs.1)
}

@discardableResult func >=<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: A) -> NSLayoutConstraint {
    return lhs.greaterThanOrEqual(to: rhs)
}

@discardableResult func <=<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, CGFloat)) -> NSLayoutConstraint {
    return lhs.lessThanOrEqual(to: rhs.0, offsetBy: rhs.1)
}

@discardableResult func <=<A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: A) -> NSLayoutConstraint {
    return lhs.lessThanOrEqual(to: rhs)
}

// MARK: - LayoutDimension Operators
@discardableResult func ==<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: A) -> NSLayoutConstraint {
    return lhs.equal(to: rhs)
}

@discardableResult func >=<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: A) -> NSLayoutConstraint {
    return lhs.greaterThanOrEqual(to: rhs)
}

@discardableResult func <=<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: A) -> NSLayoutConstraint {
    return lhs.lessThanOrEqual(to: rhs)
}

@discardableResult func ==<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.equal(to: rhs)
}

@discardableResult func >=<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.greaterThanOrEqual(to: rhs)
}

@discardableResult func <=<A: LayoutDimension>(lhs: LayoutDimensionProperty<A>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.lessThanOrEqual(to: rhs)
}

extension NSLayoutConstraint {
    func activate() {
        self.isActive = true
    }

    func deactivate() {
        self.isActive = false
    }
}

extension Array where Element: NSLayoutConstraint {
    func activateAll() {
        self.forEach({ $0.activate() })
    }

    func deactivateAll() {
        self.forEach({ $0.deactivate() })
    }
}
