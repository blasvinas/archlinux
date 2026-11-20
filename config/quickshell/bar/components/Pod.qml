import QtQuick
import QtQuick.Effects
import "../../services" as Svc

// A floating "island" of the bar: translucent glass surface with a subtle
// top-lit gradient, a hairline edge and a soft drop shadow.
Rectangle {
    id: pod

    height: Svc.Theme.barHeight
    radius: Svc.Theme.podRadius

    gradient: Gradient {
        GradientStop { position: 0.0; color: Svc.Theme.barBgTop }
        GradientStop { position: 1.0; color: Svc.Theme.barBg }
    }

    border.color: Svc.Theme.podBorder
    border.width: 1

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Svc.Theme.shadowColor
        shadowBlur: Svc.Theme.shadowBlur
        shadowVerticalOffset: Svc.Theme.shadowY
        autoPaddingEnabled: true
    }
}
