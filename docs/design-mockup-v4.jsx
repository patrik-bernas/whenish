import { useState, useRef, useEffect } from "react";

const CITIES_WORK = [
  { name: "Seoul", flag: "🇰🇷", offset: "+1h", time: "20:34", utcOffset: 9, menubar: true, abbr: "SEL", isHome: false },
  { name: "Bali", flag: "🇮🇩", offset: "Same", time: "19:34", utcOffset: 8, menubar: true, abbr: "BAL", isHome: true },
  { name: "Amsterdam", flag: "🇳🇱", offset: "-7h", time: "12:34", utcOffset: 1, menubar: false, abbr: "AMS", isHome: false },
  { name: "San Francisco", flag: "🇺🇸", offset: "-16h", time: "03:34", utcOffset: -8, menubar: false, abbr: "SF", isHome: false },
];

const CITIES_FAMILY = [
  { name: "London", flag: "🇬🇧", offset: "-8h", time: "11:34", utcOffset: 0, menubar: true, abbr: "LDN", isHome: false },
  { name: "Tokyo", flag: "🇯🇵", offset: "+1h", time: "20:34", utcOffset: 9, menubar: false, abbr: "TYO", isHome: false },
  { name: "Sydney", flag: "🇦🇺", offset: "+3h", time: "22:34", utcOffset: 11, menubar: true, abbr: "SYD", isHome: false },
];

const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const BASE_DAY = "Wed";

function getTimelineSegments(utcOffset, barWidth) {
  const hourWidth = barWidth / 48;
  const segments = [];
  for (let h = -24; h < 24; h++) {
    const localHour = ((h + utcOffset) % 24 + 24) % 24;
    let color;
    if (localHour >= 9 && localHour < 17) color = "available";
    else if ((localHour >= 7 && localHour < 9) || (localHour >= 17 && localHour < 21)) color = "caution";
    else color = "sleeping";
    segments.push({ start: (h + 24) * hourWidth, width: hourWidth, color });
  }
  return segments;
}

function TimelineBar({ utcOffset, width = 120, height = 3 }) {
  const segments = getTimelineSegments(utcOffset, width);
  const colors = {
    available: "rgba(134, 214, 177, 0.75)",
    caution: "rgba(229, 195, 120, 0.65)",
    sleeping: "rgba(205, 133, 133, 0.55)",
  };
  return (
    <svg width={width} height={height} style={{ borderRadius: height, overflow: "hidden", display: "block" }}>
      <defs><filter id="tBarBlur"><feGaussianBlur stdDeviation="0.4" /></filter></defs>
      {segments.map((seg, i) => (
        <rect key={i} x={seg.start} y={0} width={seg.width + 0.5} height={height}
          fill={colors[seg.color]} filter="url(#tBarBlur)" />
      ))}
    </svg>
  );
}

function SliderBar({ scrubValue, onScrub, width = 290 }) {
  const barRef = useRef(null);
  const [dragging, setDragging] = useState(false);
  const barHeight = 5;
  const refUtcOffset = 8;
  const segments = getTimelineSegments(refUtcOffset, width);
  const colors = {
    available: "rgba(134, 214, 177, 0.6)",
    caution: "rgba(229, 195, 120, 0.5)",
    sleeping: "rgba(205, 133, 133, 0.45)",
  };
  const dotX = scrubValue * width;
  const nowX = 0.5 * width;

  const handleMove = (clientX) => {
    if (!barRef.current) return;
    const rect = barRef.current.getBoundingClientRect();
    const x = Math.max(0, Math.min(clientX - rect.left, width));
    onScrub(x / width);
  };

  useEffect(() => {
    if (!dragging) return;
    const onMove = (e) => handleMove(e.clientX);
    const onUp = () => setDragging(false);
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    return () => { window.removeEventListener("mousemove", onMove); window.removeEventListener("mouseup", onUp); };
  }, [dragging]);

  return (
    <div ref={barRef} style={{ position: "relative", width, height: 22, cursor: "pointer" }}
      onMouseDown={(e) => { setDragging(true); handleMove(e.clientX); }}>
      <svg width={width} height={barHeight} style={{
        borderRadius: barHeight, overflow: "hidden", display: "block",
        position: "absolute", top: 9,
      }}>
        {segments.map((seg, i) => (
          <rect key={i} x={seg.start} y={0} width={seg.width + 0.5} height={barHeight} fill={colors[seg.color]} />
        ))}
      </svg>
      {/* Now marker */}
      <div style={{
        position: "absolute", left: nowX - 0.75, top: 5,
        width: 1.5, height: 12, borderRadius: 1,
        background: "rgba(167, 180, 255, 0.5)", zIndex: 1,
        opacity: Math.abs(scrubValue - 0.5) < 0.01 ? 0 : 1,
        transition: "opacity 0.3s",
      }} />
      {/* Dot */}
      <div style={{
        position: "absolute", left: dotX - 9, top: 2,
        width: 18, height: 18, borderRadius: "50%",
        background: "rgba(255,255,255,0.95)",
        boxShadow: "0 1px 8px rgba(0,0,0,0.15), 0 0 0 0.5px rgba(255,255,255,0.6)",
        transition: dragging ? "none" : "left 0.1s ease", zIndex: 2,
      }} />
    </div>
  );
}

export default function TimezoneApp() {
  const [activeGroup, setActiveGroup] = useState("Work");
  const [scrubValue, setScrubValue] = useState(0.5);
  const [menubarToggles, setMenubarToggles] = useState({});
  const groups = ["Work", "Family", "Travel"];
  const cities = activeGroup === "Work" ? CITIES_WORK : activeGroup === "Family" ? CITIES_FAMILY : [];
  const offsetHours = Math.round((scrubValue - 0.5) * 48);
  const offsetLabel = offsetHours === 0 ? "Now" : `${offsetHours > 0 ? "+" : ""}${offsetHours}h from now`;
  const localTimeStr = "19:34";

  const getAdjustedTime = (baseTime, offsetH) => {
    const [h, m] = baseTime.split(":").map(Number);
    const newH = h + offsetH;
    const wrappedH = ((newH % 24) + 24) % 24;
    return `${String(wrappedH).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
  };

  const getDayLabel = (baseTime, offsetH) => {
    const [h] = baseTime.split(":").map(Number);
    const newH = h + offsetH;
    if (newH >= 24) return "Tomorrow";
    if (newH < 0) return "Yesterday";
    return "Today";
  };

  const isMenubar = (city) => menubarToggles[city.name] !== undefined ? menubarToggles[city.name] : city.menubar;
  const toggleMenubar = (name) => {
    const allCities = CITIES_WORK.concat(CITIES_FAMILY);
    const city = allCities.find(c => c.name === name);
    const current = menubarToggles[name] !== undefined ? menubarToggles[name] : city?.menubar;
    setMenubarToggles(p => ({ ...p, [name]: !current }));
  };
  const menubarCities = cities.filter(c => isMenubar(c));
  const timelineWidth = 120;
  const lineX = scrubValue * timelineWidth;

  return (
    <div style={{
      minHeight: "100vh",
      background: "linear-gradient(160deg, #1a1520 0%, #2d2235 25%, #1e2a3a 50%, #1a2332 75%, #151820 100%)",
      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
      gap: 28,
      fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", system-ui, sans-serif',
      padding: "40px 20px", position: "relative", overflow: "hidden",
    }}>
      {/* Ambient blobs */}
      <div style={{ position: "absolute", top: "10%", left: "20%", width: 400, height: 400,
        background: "radial-gradient(circle, rgba(139, 92, 246, 0.08) 0%, transparent 70%)",
        borderRadius: "50%", filter: "blur(60px)", pointerEvents: "none" }} />
      <div style={{ position: "absolute", bottom: "15%", right: "15%", width: 350, height: 350,
        background: "radial-gradient(circle, rgba(59, 130, 246, 0.06) 0%, transparent 70%)",
        borderRadius: "50%", filter: "blur(50px)", pointerEvents: "none" }} />
      <div style={{ position: "absolute", top: "50%", left: "50%", width: 300, height: 300,
        transform: "translate(-50%, -50%)",
        background: "radial-gradient(circle, rgba(217, 175, 135, 0.05) 0%, transparent 70%)",
        borderRadius: "50%", filter: "blur(40px)", pointerEvents: "none" }} />

      {/* Menubar */}
      <div style={{
        background: "rgba(255, 255, 255, 0.06)",
        backdropFilter: "blur(30px) saturate(1.4)", WebkitBackdropFilter: "blur(30px) saturate(1.4)",
        borderRadius: 10, padding: "7px 18px",
        display: "flex", alignItems: "center", gap: 10,
        border: "0.5px solid rgba(255,255,255,0.1)",
        boxShadow: "0 2px 16px rgba(0,0,0,0.2), inset 0 0.5px 0 rgba(255,255,255,0.08)",
      }}>
        <span style={{ fontSize: 11, color: "rgba(255,255,255,0.35)" }}>◉</span>
        <span style={{
          fontSize: 12, fontFamily: '"SF Mono", "Menlo", "Fira Code", monospace',
          color: "rgba(255,255,255,0.8)", letterSpacing: "0.03em", fontWeight: 400,
        }}>
          {menubarCities.length > 0
            ? menubarCities.map(c => `${c.abbr} ${getAdjustedTime(c.time, offsetHours)}`).join("  ·  ")
            : "No cities selected"}
        </span>
      </div>

      {/* Popover */}
      <div style={{
        width: 370,
        background: "rgba(255, 255, 255, 0.08)",
        backdropFilter: "blur(60px) saturate(1.6)", WebkitBackdropFilter: "blur(60px) saturate(1.6)",
        borderRadius: 22,
        border: "0.5px solid rgba(255, 255, 255, 0.12)",
        boxShadow: "0 24px 80px rgba(0,0,0,0.35), 0 8px 32px rgba(0,0,0,0.2), inset 0 0.5px 0 rgba(255,255,255,0.15), inset 0 -0.5px 0 rgba(255,255,255,0.05)",
        overflow: "hidden",
      }}>
        <div style={{ padding: "20px 24px 14px" }}>
          {/* Search + Settings (no close X) */}
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <div style={{
              flex: 1, display: "flex", alignItems: "center", gap: 8,
              background: "rgba(255, 255, 255, 0.06)",
              borderRadius: 12, padding: "9px 14px",
              border: "0.5px solid rgba(255, 255, 255, 0.08)",
            }}>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.3)" strokeWidth="2.5" strokeLinecap="round">
                <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
              </svg>
              <span style={{ fontSize: 13, color: "rgba(255,255,255,0.3)", fontWeight: 400 }}>Add city...</span>
            </div>
            <button style={{
              background: "rgba(255,255,255,0.06)", border: "0.5px solid rgba(255,255,255,0.08)",
              borderRadius: 10, width: 32, height: 32,
              cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
              color: "rgba(255,255,255,0.35)", fontSize: 14, transition: "background 0.2s",
            }}
              onMouseEnter={e => e.currentTarget.style.background = "rgba(255,255,255,0.1)"}
              onMouseLeave={e => e.currentTarget.style.background = "rgba(255,255,255,0.06)"}
            >⚙</button>
          </div>

          {/* Pills */}
          <div style={{ display: "flex", justifyContent: "center", gap: 6, marginTop: 14 }}>
            {groups.map(g => (
              <button key={g} onClick={() => setActiveGroup(g)} style={{
                padding: "6px 16px", borderRadius: 20,
                border: activeGroup === g ? "0.5px solid rgba(255,255,255,0.15)" : "0.5px solid rgba(255,255,255,0.08)",
                background: activeGroup === g ? "rgba(255, 255, 255, 0.14)" : "rgba(255, 255, 255, 0.04)",
                color: activeGroup === g ? "rgba(255,255,255,0.9)" : "rgba(255,255,255,0.35)",
                fontSize: 12, fontWeight: activeGroup === g ? 600 : 400,
                cursor: "pointer", transition: "all 0.25s ease",
                backdropFilter: activeGroup === g ? "blur(10px)" : "none",
              }}
                onMouseEnter={e => { if (activeGroup !== g) e.currentTarget.style.background = "rgba(255,255,255,0.08)"; }}
                onMouseLeave={e => { if (activeGroup !== g) e.currentTarget.style.background = "rgba(255,255,255,0.04)"; }}
              >{g}</button>
            ))}
          </div>
        </div>

        {/* City list */}
        <div>
          {cities.map((city, i) => {
            const dayLabel = getDayLabel(city.time, offsetHours);
            return (
              <div key={city.name}>
                {i === 0 && <div style={{ height: 0.5, background: "rgba(255,255,255,0.06)", margin: "0 24px" }} />}
                <div style={{
                  display: "flex", alignItems: "center", padding: "12px 24px", gap: 10,
                  transition: "background 0.2s", position: "relative",
                }}
                  onMouseEnter={e => e.currentTarget.style.background = "rgba(255,255,255,0.03)"}
                  onMouseLeave={e => e.currentTarget.style.background = "transparent"}
                >
                  {/* Home indicator glow */}
                  {city.isHome && (
                    <div style={{
                      position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)",
                      width: 40, height: 40, borderRadius: "50%",
                      background: "radial-gradient(circle, rgba(167, 180, 255, 0.12) 0%, transparent 70%)",
                      pointerEvents: "none",
                    }} />
                  )}

                  {/* Flag + home pin */}
                  <div style={{ position: "relative", width: 26, textAlign: "center", flexShrink: 0 }}>
                    <span style={{ fontSize: 20, lineHeight: 1 }}>{city.flag}</span>
                    {city.isHome && (
                      <span style={{
                        position: "absolute", bottom: -3, right: -4,
                        fontSize: 8, lineHeight: 1,
                      }}>📍</span>
                    )}
                  </div>

                  {/* Name + offset */}
                  <div style={{ minWidth: 72 }}>
                    <div style={{
                      fontSize: 13.5, fontWeight: city.isHome ? 600 : 500,
                      color: city.isHome ? "rgba(200, 210, 255, 0.95)" : "rgba(255,255,255,0.88)",
                      letterSpacing: "-0.01em",
                    }}>{city.name}</div>
                    <div style={{
                      fontSize: 10.5, color: "rgba(255,255,255,0.3)", fontWeight: 400, marginTop: 1.5,
                      letterSpacing: "0.01em",
                    }}>{city.isHome ? "You" : city.offset}</div>
                  </div>

                  {/* Timeline bar */}
                  <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", position: "relative" }}>
                    <div style={{ position: "relative" }}>
                      <TimelineBar utcOffset={city.utcOffset} width={timelineWidth} height={3} />
                      <div style={{
                        position: "absolute", left: lineX, top: -3, width: 1, height: 9,
                        background: "rgba(255, 255, 255, 0.45)", borderRadius: 1,
                      }} />
                    </div>
                  </div>

                  {/* Time + always-visible date */}
                  <div style={{ minWidth: 58, textAlign: "right" }}>
                    <div style={{
                      fontSize: 21, fontWeight: 300, color: "rgba(255,255,255,0.85)",
                      fontVariantNumeric: "tabular-nums", letterSpacing: "-0.02em",
                      fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", system-ui, sans-serif',
                    }}>
                      {getAdjustedTime(city.time, offsetHours)}
                    </div>
                    <div style={{
                      fontSize: 9.5,
                      color: dayLabel !== "Today"
                        ? "rgba(167, 180, 255, 0.55)"
                        : "rgba(255,255,255,0.2)",
                      fontWeight: dayLabel !== "Today" ? 500 : 400,
                      marginTop: 1,
                      letterSpacing: "0.02em",
                      height: 13,
                    }}>
                      {dayLabel}
                    </div>
                  </div>

                  {/* Menubar toggle */}
                  <button onClick={() => toggleMenubar(city.name)} style={{
                    width: 7, height: 7, borderRadius: "50%",
                    background: isMenubar(city) ? "rgba(167, 180, 255, 0.7)" : "rgba(255,255,255,0.15)",
                    border: "none", cursor: "pointer", padding: 0,
                    transition: "all 0.25s ease",
                    boxShadow: isMenubar(city) ? "0 0 8px rgba(167, 180, 255, 0.35)" : "none",
                    flexShrink: 0,
                  }} />

                  {/* Remove */}
                  <button style={{
                    background: "none", border: "none", cursor: "pointer",
                    color: "rgba(255,255,255,0.12)", fontSize: 11, padding: 0, lineHeight: 1,
                    transition: "color 0.2s", flexShrink: 0,
                  }}
                    onMouseEnter={e => e.currentTarget.style.color = "rgba(255,255,255,0.4)"}
                    onMouseLeave={e => e.currentTarget.style.color = "rgba(255,255,255,0.12)"}
                  >✕</button>
                </div>

                {i < cities.length - 1 && (
                  <div style={{ height: 0.5, background: "rgba(255,255,255,0.06)", margin: "0 24px" }} />
                )}
              </div>
            );
          })}
        </div>

        {/* Slider area */}
        <div style={{ padding: "10px 24px 14px" }}>
          <div style={{ height: 0.5, background: "rgba(255,255,255,0.06)", marginBottom: 12 }} />

          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 8 }}>
            <span style={{ fontSize: 11, color: "rgba(255,255,255,0.3)", fontWeight: 400 }}>{offsetLabel}</span>
            <button onClick={() => setScrubValue(0.5)} style={{
              display: "flex", alignItems: "center", gap: 4,
              background: "none", border: "none", cursor: "pointer",
              color: "rgba(167, 180, 255, 0.6)", fontSize: 12.5, fontWeight: 400,
              fontVariantNumeric: "tabular-nums",
              fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", system-ui, sans-serif',
              opacity: scrubValue === 0.5 ? 0.5 : 1, transition: "opacity 0.2s",
              letterSpacing: "-0.01em",
            }}>
              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                <circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" />
              </svg>
              {localTimeStr}
            </button>
          </div>

          <div style={{ paddingLeft: 4, paddingRight: 4 }}>
            <SliderBar scrubValue={scrubValue} onScrub={setScrubValue} width={290} />
          </div>

          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 4 }}>
            <span style={{ fontSize: 9.5, color: "rgba(255,255,255,0.18)", fontWeight: 400, letterSpacing: "0.02em" }}>-24h</span>
            <span style={{ fontSize: 9.5, color: "rgba(255,255,255,0.18)", fontWeight: 400, letterSpacing: "0.02em" }}>+24h</span>
          </div>
        </div>

        {/* Legend — inside the component */}
        <div style={{
          display: "flex", justifyContent: "center", gap: 18, alignItems: "center",
          padding: "0 24px 16px",
        }}>
          {[
            { color: "rgba(134, 214, 177, 0.7)", label: "Available" },
            { color: "rgba(229, 195, 120, 0.65)", label: "Heads up" },
            { color: "rgba(205, 133, 133, 0.55)", label: "Sleeping" },
          ].map(item => (
            <div key={item.label} style={{ display: "flex", alignItems: "center", gap: 5 }}>
              <div style={{ width: 5, height: 5, borderRadius: "50%", background: item.color }} />
              <span style={{ fontSize: 10, color: "rgba(255,255,255,0.25)", fontWeight: 400, letterSpacing: "0.02em" }}>{item.label}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
