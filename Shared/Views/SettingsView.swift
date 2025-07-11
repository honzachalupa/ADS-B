import SwiftUI
import SwiftCore

let SETTINGS_IS_METRIC_UNITS_KEY = "settings_isMetricUnits"
let SETTINGS_IS_INFO_BOX_ENABLED_KEY = "settings_isQuickInfoEnabled"
let SETTINGS_IS_DEBUG_INFO_BOX_ENABLED_KEY = "settings_isDebugInfoBoxEnabled"

struct SettingsView: View {
    @AppStorage(SETTINGS_IS_METRIC_UNITS_KEY) private var isMetricUnits: Bool = false
    @AppStorage(SETTINGS_IS_INFO_BOX_ENABLED_KEY) private var isInfoBoxEnabled: Bool = true
    @AppStorage(SETTINGS_IS_DEBUG_INFO_BOX_ENABLED_KEY) private var isDebugInfoBoxEnabled: Bool = false
    
    var body: some View {
        NavigationStack {
            AboutAppView(
                developerId: 1557529575,
                developerName: "Jan Chalupa",
                developerEmail: "me@janchalupa.dev",
                developerWebsite: "https://www.janchalupa.dev/",
                storeCountryCode: "cz",
                privacyPolicy: privacyPolicyString,
                termsOfService: termsOfServiceString
            ) {
                #if os(watchOS)
                Section("Filter") {
                    MapFilterView()
                    MapLegendView {
                        Text("Legend")
                    }
                }
                #endif
                
                Section {
                    Toggle("Show info box below aircraft icon", isOn: $isInfoBoxEnabled)
                    Toggle("Use metric units", isOn: $isMetricUnits)
                    
                    #if os(iOS)
                    Toggle("Show debug info box", isOn: $isDebugInfoBoxEnabled)
                    #endif
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}

let privacyPolicyString = """
## 1. Introduction

This Privacy Policy describes how the ADS-B app ("the App") handles data and privacy considerations. This App allows users to view real-time aircraft position data and track flight information using publicly available ADS-B data sources.

## 2. Data Collection and Usage

The ADS-B app:

- Does not collect or store any personal information beyond temporary location coordinates
- Does not track user activity for analytics purposes
- Does not use cookies or similar tracking technologies
- Shares your approximate location coordinates with ADS-B data providers only to fetch relevant aircraft data
- Only accesses your device location when granted permission to center the map and fetch area-specific aircraft data

## 3. Location Services

When you use the App:

- Location access is used to center the map on your current position and to fetch aircraft data for your area
- Your approximate location coordinates are sent to ADS-B data providers to retrieve aircraft information in your vicinity
- You can deny location access and the app will function normally with a default map center
- No other location tracking or storage occurs beyond fetching relevant aircraft data

## 4. Data Storage

The App stores data in the following ways:

- App settings and preferences are stored locally on your device
- No personal data is stored in iCloud or external servers
- All aircraft data is fetched in real-time from public ADS-B data sources

## 5. Third-Party Services

The App integrates with the following third-party services:

- ADS-B data providers (adsb.lol) for real-time aircraft position data

These services have their own privacy policies and terms of use. We recommend reviewing their respective policies.

## 6. Public Data Sources

The aircraft tracking data displayed in the App:

- Comes from publicly available ADS-B (Automatic Dependent Surveillance-Broadcast) transmissions
- Is already publicly accessible through various aviation tracking websites
- Does not include any private or confidential information
- Is subject to availability and accuracy of the source data providers

## 7. User Rights and Control

You have full control over your data within the App:

- You can grant or deny location access at any time through iOS Settings
- You can modify app preferences and settings
- All data processing occurs locally on your device

## 8. Children's Privacy

The App is not directed to children under the age of 13, and we do not knowingly collect personal information from children under 13.

## 9. Changes to This Privacy Policy

This Privacy Policy may be updated from time to time. Users will be notified of any changes by updating the "Last Updated" date at the bottom of this policy.

## 10. Contact Information

If you have any questions about this Privacy Policy, please contact me@janchalupa.dev.

---

Last Updated: July 11, 2025
"""

let termsOfServiceString = """
## 1. Introduction

These Terms of Service ("Terms") govern your access to and use of the ADS-B app ("the App"), a SwiftUI-based iOS application that displays real-time aircraft position data. By downloading, installing, or using the App, you agree to be bound by these Terms.

## 2. Data Sources and Availability

The App uses publicly available ADS-B data sources. By using the App, you acknowledge that:

- Aircraft data is sourced from third-party ADS-B data providers
- Data availability and accuracy may vary
- The developer is not responsible for data outages or inaccuracies
- Data is provided for informational purposes only

## 3. User Responsibilities

As a user of the App, you are responsible for:

- Ensuring your use of the App complies with applicable laws and regulations
- Not using the App for any illegal surveillance or tracking activities
- Understanding that displayed information is for general aviation interest only
- Not relying on the App for flight safety or navigation purposes

## 4. Acceptable Use

You agree to use the App only for lawful purposes. You shall not use the App to:

- Engage in any form of harassment or stalking of aircraft or individuals
- Attempt to reverse engineer or bypass any security measures in the App
- Use automated methods to access or use the App in a manner that exceeds reasonable use
- Redistribute, sell, or lease access to the App to third parties
- Use the App for any commercial aviation tracking services without proper authorization

## 5. Aviation Data Disclaimer

The aircraft tracking information provided by the App:

- Is for general aviation interest and educational purposes only
- Should not be used for flight planning, navigation, or safety-critical decisions
- May not be complete, accurate, or up-to-date
- Does not include all aircraft due to various technical and regulatory limitations
- May display delayed or outdated position information

## 6. Intellectual Property

The App, including its code, design, and functionality, is owned by the developer and protected by intellectual property laws. You may not copy, modify, distribute, sell, or lease any part of the App without explicit permission.

## 7. Disclaimer of Warranties

THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT ANY WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. TO THE FULLEST EXTENT PERMITTED BY LAW, WE DISCLAIM ALL WARRANTIES, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

We do not warrant that the App will function without interruption or errors, or that any defects will be corrected.

## 8. Limitation of Liability

TO THE FULLEST EXTENT PERMITTED BY LAW, IN NO EVENT SHALL THE DEVELOPER BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS APP, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## 9. Third-Party Services

The App depends on the following third-party services:

- ADS-B data providers for aircraft position information

Your use of these services through the App is governed by their respective terms and policies.

## 10. Updates to Terms

These Terms may be modified at any time. Notice of significant changes will be provided by updating the version date of these Terms. Your continued use of the App after such modifications constitutes your acceptance of the revised Terms.

## 11. Governing Law

These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which the primary maintainer resides, without regard to its conflict of law provisions.

## 12. Contact Information

If you have any questions about these Terms, please contact me@janchalupa.dev.

---

Last Updated: July 11, 2025
"""
