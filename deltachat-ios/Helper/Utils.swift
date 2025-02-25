import Foundation
import UIKit
import DcCore

struct Utils {
    private static let inviteDomain = "i.delta.chat"

    static func isEmail(url: URL) -> Bool {
        let mailScheme = "mailto"
        if let scheme = url.scheme {
            return mailScheme == scheme && DcContext.mayBeValidAddr(email: url.absoluteString.substring(mailScheme.count + 1, url.absoluteString.count))
        }
        return false
    }

    static func getEmailFrom(_ url: URL) -> String {
        let mailScheme = "mailto"
        return url.absoluteString.substring(mailScheme.count + 1, url.absoluteString.count)
    }

    public static func getBackgroundImageURL(name: String) -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask) as [URL]
        guard let identifier = Bundle.main.bundleIdentifier else {
            logger.error("backgroundImageURL: Could not find bundle identifier")
            return nil
        }
        guard let directoryURL = urls.last else {
            logger.error("backgroundImageURL: Could not find directory url for .applicationSupportDirectory in .userDomainMask")
            return nil
        }
        return directoryURL.appendingPathComponent(identifier).appendingPathComponent(name)
    }

    public static func getSafeBottomLayoutInset() -> CGFloat {
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.first
            return window?.safeAreaInsets.bottom ?? 0
        }
        // iOS 11 and 12
        let window = UIApplication.shared.keyWindow
        return window?.safeAreaInsets.bottom ?? 0
    }

    public static func getInviteLink(context: DcContext, chatId: Int) -> String? {
        // convert `OPENPGP4FPR:FPR#a=ADDR&n=NAME&...` to `https://i.delta.chat/#FPR&a=ADDR&n=NAME&...`
        if var data = context.getSecurejoinQr(chatId: chatId), let range = data.range(of: "#") {
            data.replaceSubrange(range, with: "&")
            if let range = data.range(of: "OPENPGP4FPR:") {
                data.replaceSubrange(range, with: "https://" + inviteDomain + "/#")
                return data
            }
        }
        return nil
    }

    public static func share(message: DcMsg, parentViewController: UIViewController, sourceView: UIView) {
        guard let fileURL = message.fileURL else { return }
        let objectsToShare: [Any]
        if message.type == DC_MSG_WEBXDC {
            let dict = message.getWebxdcInfoDict()
            let previewImage = message.getWebxdcPreviewImage()
            let previewText = dict["name"] as? String ?? fileURL.lastPathComponent
            objectsToShare = [WebxdcItemSource(title: previewText,
                                               previewImage: previewImage,
                                               url: fileURL)]
        } else {
            objectsToShare = [fileURL]
        }

        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [.copyToPasteboard]
        activityVC.popoverPresentationController?.sourceView = sourceView
        parentViewController.present(activityVC, animated: true, completion: nil)
    }

    public static func share(url: String, parentViewController: UIViewController) {
        if let url = URL(string: url) {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            parentViewController.present(activityVC, animated: true, completion: nil)
        }
    }
}
