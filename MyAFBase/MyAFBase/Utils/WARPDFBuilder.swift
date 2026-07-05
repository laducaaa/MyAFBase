import UIKit

/// Renders a WAR Tracker report (or nomination draft) to a paginated PDF using
/// UIKit text layout — all drawing stays in the standard top-left coordinate
/// system so nothing renders upside down.
enum WARPDFBuilder {
    private static let pageSize = CGSize(width: 612, height: 792)
    private static let margin: CGFloat = 48

    static func makePDF(title: String, subtitle: String, bodyText: String) -> Data {
        let textWidth = pageSize.width - margin * 2
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]
        let body = NSAttributedString(string: bodyText, attributes: bodyAttributes)
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage(attributedString: body)
        textStorage.addLayoutManager(layoutManager)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        return renderer.pdfData { context in
            context.beginPage()
            var y = margin

            y += drawLine(title, at: y, width: textWidth, font: .boldSystemFont(ofSize: 18))
            y += 6

            if !subtitle.isEmpty {
                y += drawLine(subtitle, at: y, width: textWidth, font: .systemFont(ofSize: 11), color: .darkGray)
                y += 14
            }

            var glyphIndex = 0
            var isFirstBodyPage = true

            while glyphIndex < layoutManager.numberOfGlyphs {
                if !isFirstBodyPage {
                    context.beginPage()
                    y = margin
                }
                isFirstBodyPage = false

                let availableHeight = pageSize.height - y - margin
                let container = NSTextContainer(size: CGSize(width: textWidth, height: availableHeight))
                container.lineFragmentPadding = 0
                layoutManager.addTextContainer(container)

                let glyphRange = layoutManager.glyphRange(for: container)
                guard glyphRange.length > 0 else { break }

                layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: CGPoint(x: margin, y: y))
                glyphIndex = glyphRange.upperBound
                layoutManager.removeTextContainer(at: layoutManager.textContainers.count - 1)
            }
        }
    }

    private static func drawLine(
        _ string: String,
        at y: CGFloat,
        width: CGFloat,
        font: UIFont,
        color: UIColor = .black
    ) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attributed = NSAttributedString(string: string, attributes: attrs)
        let height = ceil(attributed.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height)
        attributed.draw(in: CGRect(x: margin, y: y, width: width, height: height))
        return height
    }
}
