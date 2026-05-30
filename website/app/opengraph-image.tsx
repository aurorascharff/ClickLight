import { ImageResponse } from "next/og";

export const alt = "ClickLight - make clicks visible";
export const size = {
  height: 630,
  width: 1200,
};
export const contentType = "image/png";

export default function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          alignItems: "center",
          background:
            "radial-gradient(circle at 18% 24%, rgba(100, 216, 255, 0.65), transparent 28%), radial-gradient(circle at 76% 18%, rgba(255, 93, 87, 0.48), transparent 28%), radial-gradient(circle at 48% 88%, rgba(255, 216, 106, 0.32), transparent 34%), linear-gradient(135deg, #07101a 0%, #16111d 48%, #080910 100%)",
          color: "#f7f7fb",
          display: "flex",
          height: "100%",
          justifyContent: "center",
          padding: 72,
          position: "relative",
          width: "100%",
        }}
      >
        <div
          style={{
            alignItems: "flex-start",
            display: "flex",
            flexDirection: "column",
            gap: 28,
            width: "100%",
          }}
        >
          <div
            style={{
              alignItems: "center",
              display: "flex",
              gap: 34,
            }}
          >
            <div
              style={{
                border: "10px solid #f7f7fb",
                borderRadius: 999,
                display: "flex",
                height: 108,
                position: "relative",
                width: 108,
              }}
            >
              <div
                style={{
                  background: "#f7f7fb",
                  borderRadius: 999,
                  height: 18,
                  left: 35,
                  position: "absolute",
                  top: 35,
                  width: 18,
                }}
              />
              <div
                style={{
                  background: "#f7f7fb",
                  clipPath: "polygon(14% 0%, 100% 42%, 66% 54%, 88% 92%, 64% 100%, 43% 63%, 22% 88%)",
                  height: 92,
                  left: 48,
                  position: "absolute",
                  top: 42,
                  transform: "rotate(-7deg)",
                  width: 92,
                }}
              />
            </div>
            <div
              style={{
                display: "flex",
                flexDirection: "column",
              }}
            >
              <div
                style={{
                  fontSize: 112,
                  fontWeight: 800,
                  letterSpacing: 0,
                  lineHeight: 0.9,
                }}
              >
                ClickLight
              </div>
              <div
                style={{
                  color: "rgba(247,247,251,0.72)",
                  fontSize: 34,
                  fontWeight: 500,
                  marginTop: 24,
                }}
              >
                Make clicks visible during demos, screen sharing, and UX reviews.
              </div>
            </div>
          </div>
        </div>
        <div
          style={{
            border: "6px solid #64d8ff",
            borderRadius: 999,
            bottom: 86,
            boxShadow: "0 0 40px rgba(100,216,255,0.55)",
            height: 130,
            position: "absolute",
            right: 142,
            width: 130,
          }}
        />
      </div>
    ),
    size
  );
}
