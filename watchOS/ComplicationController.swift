import ClockKit

let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""
let imageName = "ComplicationIcon"
let imageTintedName = "ComplicationIconTinted"

final class ComplicationController: NSObject, CLKComplicationDataSource {
    // This method contains important information about your complication.
    func complicationDescriptors() async -> [CLKComplicationDescriptor] {
        [
            CLKComplicationDescriptor(
                identifier: "watch-complication",
                displayName: appName,
                supportedFamilies: [.graphicCircular, .graphicCorner])
        ]
    }
    
    // This method is for creating a complication sample. It defines how it will look in Complication Picker Mode.
    func localizableSampleTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
        guard let fullColorImage = UIImage(named: imageName) else { return nil }
        let fullColorImageProvider = CLKFullColorImageProvider(fullColorImage: fullColorImage)
        
        switch complication.family {
            case .graphicCircular:
                let template = CLKComplicationTemplateGraphicCircularImage(imageProvider: fullColorImageProvider)
                return template
                
            case .graphicCorner:
                let template = CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: fullColorImageProvider)
                return template
                
            default:
                return nil
        }
    }
    
    // This method is for creating an actual live complication.
    func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? {
        guard
            let fullColorImage = UIImage(named: imageName),
            let tintColorImage = UIImage(named: imageTintedName)
        else { return nil }
        
        let tintColorImageProvider = CLKImageProvider(onePieceImage: tintColorImage)
        let fullColorImageProvider = CLKFullColorImageProvider(fullColorImage: fullColorImage, tintedImageProvider: tintColorImageProvider)
        
        switch complication.family {
            case .graphicCircular:
                let template = CLKComplicationTemplateGraphicCircularImage(imageProvider: fullColorImageProvider)
                return CLKComplicationTimelineEntry(date: .now, complicationTemplate: template)
                
            case .graphicCorner:
                let template = CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: fullColorImageProvider)
                return CLKComplicationTimelineEntry(date: .now, complicationTemplate: template)
                
            default:
                return nil
        }
    }
}
