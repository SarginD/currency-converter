import Foundation

extension UIView {

    private struct Constant {
        static var defaultTopInset: CGFloat = 20
    }

    public var safeAreaBottomInset: CGFloat {
        if #available(iOS 11, *), let bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
            return bottomInset
        } else {
            return 0
        }
    }

    @objc public var safeAreaTopInset: CGFloat {
        if #available(iOS 11, *), let topInset = UIApplication.shared.keyWindow?.safeAreaInsets.top {
            return topInset > 0 ? topInset : Constant.defaultTopInset
        } else {
            return Constant.defaultTopInset
        }
    }
}
