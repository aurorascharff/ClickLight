import AppKit

final class ClickOverlayView: NSView {
    private var screenFrame: CGRect
    private var settings: ClickSettings
    private var pulses: [ClickPulse] = []
    private var displayLink: Timer?

    init(screenFrame: CGRect, settings: ClickSettings) {
        self.screenFrame = screenFrame
        self.settings = settings
        super.init(frame: CGRect(origin: .zero, size: screenFrame.size))
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        nil
    }

    func apply(settings: ClickSettings) {
        self.settings = settings
    }

    func show(event: ClickEvent, settings: ClickSettings) {
        self.settings = settings

        let localPoint = CGPoint(
            x: event.location.x - screenFrame.minX,
            y: event.location.y - screenFrame.minY
        )

        pulses.append(ClickPulse(
            kind: event.kind,
            point: localPoint,
            startTime: CACurrentMediaTime(),
            duration: duration(for: event.kind),
            baseSize: size(for: event.kind),
            intensity: settings.intensity,
            color: color(for: event.kind)
        ))

        startDisplayLink()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let now = CACurrentMediaTime()
        pulses = pulses.filter { !$0.isExpired(at: now) }

        for pulse in pulses {
            draw(pulse: pulse, at: now, in: context)
        }

        if pulses.isEmpty {
            stopDisplayLink()
        }
    }

    private func draw(pulse: ClickPulse, at now: CFTimeInterval, in context: CGContext) {
        let progress = pulse.progress(at: now)
        let eased = 1 - pow(1 - progress, 3)
        let fade = 1 - eased
        let visualIntensity = max(0.15, min(1.35, pulse.intensity))
        let alpha = clamp(fade * (0.18 + visualIntensity * 0.78))
        let lineWidth = max(2.25, pulse.baseSize * (0.035 + visualIntensity * 0.045))

        context.saveGState()
        context.setLineCap(.round)
        context.setLineJoin(.round)

        switch pulse.kind {
        case .leftDown:
            drawGlowIfNeeded(
                context: context,
                point: pulse.point,
                radius: pulse.baseSize * (0.28 + 0.78 * eased),
                color: pulse.color,
                alpha: fade * visualIntensity
            )
            drawRing(
                context: context,
                point: pulse.point,
                radius: pulse.baseSize * (0.18 + 0.62 * eased),
                lineWidth: lineWidth,
                color: pulse.color,
                alpha: alpha
            )
            drawDot(context: context, point: pulse.point, radius: pulse.baseSize * 0.085, color: pulse.color, alpha: alpha * 0.75)
        case .leftUp:
            drawGlowIfNeeded(
                context: context,
                point: pulse.point,
                radius: pulse.baseSize * (0.42 + 0.56 * eased),
                color: pulse.color,
                alpha: fade * visualIntensity * 0.7
            )
            drawRing(
                context: context,
                point: pulse.point,
                radius: pulse.baseSize * (0.34 + 0.44 * eased),
                lineWidth: lineWidth * 0.7,
                color: pulse.color,
                alpha: alpha * 0.65
            )
        case .rightDown:
            drawGlowIfNeeded(
                context: context,
                point: pulse.point,
                radius: pulse.baseSize * (0.28 + 0.7 * eased),
                color: pulse.color,
                alpha: fade * visualIntensity
            )
            drawRing(
                context: context,
                point: pulse.point,
                radius: pulse.baseSize * (0.18 + 0.54 * eased),
                lineWidth: lineWidth,
                color: pulse.color,
                alpha: alpha
            )
            drawCrosshair(context: context, point: pulse.point, size: pulse.baseSize * 0.28, color: pulse.color, alpha: alpha * 0.85)
        case .rightUp:
            drawGlowIfNeeded(
                context: context,
                point: pulse.point,
                radius: pulse.baseSize * (0.36 + 0.5 * eased),
                color: pulse.color,
                alpha: fade * visualIntensity * 0.65
            )
            drawRing(
                context: context,
                point: pulse.point,
                radius: pulse.baseSize * (0.28 + 0.42 * eased),
                lineWidth: lineWidth * 0.7,
                color: pulse.color,
                alpha: alpha * 0.6
            )
        case .drag:
            drawDot(
                context: context,
                point: pulse.point,
                radius: pulse.baseSize * (0.08 + 0.065 * visualIntensity),
                color: pulse.color,
                alpha: alpha * 0.78
            )
        }

        context.restoreGState()
    }

    private func drawGlowIfNeeded(
        context: CGContext,
        point: CGPoint,
        radius: CGFloat,
        color: NSColor,
        alpha: CGFloat
    ) {
        guard settings.intensity >= 0.7 else { return }
        let glowAlpha = clamp(alpha * (settings.intensity >= 1.2 ? 0.18 : 0.08))
        context.setFillColor(color.withAlphaComponent(glowAlpha).cgColor)
        context.fillEllipse(in: CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }

    private func drawRing(
        context: CGContext,
        point: CGPoint,
        radius: CGFloat,
        lineWidth: CGFloat,
        color: NSColor,
        alpha: CGFloat
    ) {
        context.setStrokeColor(color.withAlphaComponent(alpha).cgColor)
        context.setLineWidth(lineWidth)
        context.strokeEllipse(in: CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }

    private func drawDot(context: CGContext, point: CGPoint, radius: CGFloat, color: NSColor, alpha: CGFloat) {
        context.setFillColor(color.withAlphaComponent(alpha).cgColor)
        context.fillEllipse(in: CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }

    private func drawCrosshair(context: CGContext, point: CGPoint, size: CGFloat, color: NSColor, alpha: CGFloat) {
        context.setStrokeColor(color.withAlphaComponent(alpha).cgColor)
        context.setLineWidth(max(2, size * 0.12))
        context.move(to: CGPoint(x: point.x - size, y: point.y))
        context.addLine(to: CGPoint(x: point.x + size, y: point.y))
        context.move(to: CGPoint(x: point.x, y: point.y - size))
        context.addLine(to: CGPoint(x: point.x, y: point.y + size))
        context.strokePath()
    }

    private func startDisplayLink() {
        guard displayLink == nil else { return }
        displayLink = Timer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(displayLinkDidTick), userInfo: nil, repeats: true)
        RunLoop.main.add(displayLink!, forMode: .common)
    }

    @objc private func displayLinkDidTick() {
        needsDisplay = true
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func color(for kind: ClickKind) -> NSColor {
        switch kind {
        case .leftDown:
            return NSColor(calibratedRed: 0.0, green: 0.74, blue: 1.0, alpha: 1)
        case .leftUp:
            return NSColor(calibratedRed: 0.4, green: 0.88, blue: 1.0, alpha: 1)
        case .rightDown, .rightUp:
            return NSColor(calibratedRed: 1.0, green: 0.46, blue: 0.19, alpha: 1)
        case .drag:
            return NSColor(calibratedRed: 0.92, green: 0.84, blue: 0.22, alpha: 1)
        }
    }

    private func duration(for kind: ClickKind) -> TimeInterval {
        switch kind {
        case .drag:
            return min(0.2, settings.duration * 0.55)
        case .leftUp, .rightUp:
            return settings.duration * 0.78
        case .leftDown, .rightDown:
            return settings.duration
        }
    }

    private func size(for kind: ClickKind) -> CGFloat {
        switch kind {
        case .drag:
            return settings.size * 0.6
        case .leftUp, .rightUp:
            return settings.size * 0.82
        case .leftDown, .rightDown:
            return settings.size
        }
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        max(0, min(1, value))
    }
}

private struct ClickPulse {
    let kind: ClickKind
    let point: CGPoint
    let startTime: CFTimeInterval
    let duration: TimeInterval
    let baseSize: CGFloat
    let intensity: CGFloat
    let color: NSColor

    func progress(at time: CFTimeInterval) -> CGFloat {
        CGFloat(max(0, min(1, (time - startTime) / duration)))
    }

    func isExpired(at time: CFTimeInterval) -> Bool {
        progress(at: time) >= 1
    }
}
