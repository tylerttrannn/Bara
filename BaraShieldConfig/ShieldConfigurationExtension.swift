//
//  ShieldConfigurationExtension.swift
//  BaraShieldConfig
//
//  Created by Tyler Tran on 2/28/26.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        
        // Customize the shield as needed for applications.
        return ShieldConfiguration(
            backgroundBlurStyle: .systemThinMaterial,
            backgroundColor: .none,

            title: .init(
                text: "\(application.localizedDisplayName ?? "App") blocked by Bara",
                color: .white
            ),
            
            
            subtitle: .init(
                text: "This app is blocked by Bara. Open Bara to request more time.",
                color: UIColor(white: 0.85, alpha: 1.0)
            ),
            
            primaryButtonLabel: .init(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.25, green: 0.5, blue: 1.0, alpha: 1.0),
       
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for applications shielded because of their category.
        return ShieldConfiguration(
            backgroundBlurStyle: .systemThinMaterial,
            backgroundColor: .none,
            
            title: .init(
                text: "Blocked by Bara",
                color: .white
            ),
            
            subtitle: .init(
                text: "This app is blocked by Bara. Open Bara to request more time.",
                color: UIColor(white: 0.85, alpha: 1.0)
            ),
            
            primaryButtonLabel: .init(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.25, green: 0.5, blue: 1.0, alpha: 1.0),
       
        )
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Customize the shield as needed for web domains.
        return ShieldConfiguration(
            backgroundBlurStyle: .systemThinMaterial,
            backgroundColor: .none,
            
            title: .init(
                text: "Blocked by Bara",
                color: .white
            ),
            
            subtitle: .init(
                text: "This app is blocked by Bara. Open Bara to request more time.",
                color: UIColor(white: 0.85, alpha: 1.0)
            ),
            
            primaryButtonLabel: .init(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.25, green: 0.5, blue: 1.0, alpha: 1.0),
       
        )
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for web domains shielded because of their category.
        return ShieldConfiguration(
            backgroundBlurStyle: .systemThinMaterial,
            backgroundColor: .none,
            
            title: .init(
                text: "Blocked by Bara",
                color: .white
            ),
            
            subtitle: .init(
                text: "This app is blocked by Bara. Open Bara to request more time.",
                color: UIColor(white: 0.85, alpha: 1.0)
            ),
            
            primaryButtonLabel: .init(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.25, green: 0.5, blue: 1.0, alpha: 1.0),
       
        )
    }
}
