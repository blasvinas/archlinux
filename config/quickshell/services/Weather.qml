pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Weather via wttr.in (no API key; auto-locates by IP). Refreshes every 30 min.
Singleton {
    id: root

    property bool useFahrenheit: true

    // Current conditions.
    property bool ready: false
    property bool loading: false
    property string location: ""
    property int tempC: 0
    property int tempF: 0
    property int feelsC: 0
    property int feelsF: 0
    property int humidity: 0
    property int windKmph: 0
    property int windMph: 0
    property string windDir: ""
    property string description: ""
    property int code: 113
    property string sunrise: ""
    property string sunset: ""

    // 3-day forecast: [{ date, day, min, max, code, desc }].
    property var forecast: []

    readonly property int temp: useFahrenheit ? tempF : tempC
    readonly property int feels: useFahrenheit ? feelsF : feelsC
    readonly property string unit: useFahrenheit ? "°F" : "°C"
    readonly property int wind: useFahrenheit ? windMph : windKmph
    readonly property string windUnit: useFahrenheit ? "mph" : "km/h"

    function toggleUnit() { useFahrenheit = !useFahrenheit; store.setText(useFahrenheit ? "F" : "C"); }
    function refresh() { if (!loading) { loading = true; proc.running = true; } }

    // Day/night by comparing "now" to sunrise/sunset (fallback: 6-18h).
    readonly property bool isDay: {
        var h = new Date().getHours();
        return h >= 6 && h < 19;
    }

    // Map wttr/WWO weather codes to Nerd Font glyphs (day/night aware).
    function iconFor(c, day) {
        function g(cp) { return String.fromCodePoint(cp); }
        switch (parseInt(c)) {
        case 113: return day ? g(0xF0599) : g(0xF0594);           // clear
        case 116: return day ? g(0xF0595) : g(0xF0F31);           // partly cloudy
        case 119: case 122: return g(0xF0590);                    // cloudy / overcast
        case 143: case 248: case 260: return g(0xF0591);          // mist / fog
        case 200: case 386: case 389: case 392: case 395:
            return g(0xF067E);                                    // thunder
        case 176: case 263: case 266: case 293: case 296:
        case 299: case 323: case 326: case 353: case 362:
        case 368: return g(0xF0597);                              // light rain / drizzle
        case 302: case 305: case 308: case 356: case 359:
            return g(0xF0596);                                    // heavy rain / pouring
        case 179: case 227: case 230: case 329: case 332:
        case 335: case 338: case 371: case 395:
            return g(0xF0598);                                    // snow
        case 182: case 185: case 281: case 284: case 311:
        case 314: case 317: case 320: case 365: case 350:
        case 374: case 377: return g(0xF067F);                    // sleet / freezing
        default: return g(0xF0590);
        }
    }

    function currentIcon() { return iconFor(code, isDay); }

    Process {
        id: proc
        command: ["curl", "-s", "--max-time", "15", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    var d = JSON.parse(this.text);
                    var c = d.current_condition[0];
                    root.tempC = parseInt(c.temp_C);
                    root.tempF = parseInt(c.temp_F);
                    root.feelsC = parseInt(c.FeelsLikeC);
                    root.feelsF = parseInt(c.FeelsLikeF);
                    root.humidity = parseInt(c.humidity);
                    root.windKmph = parseInt(c.windspeedKmph);
                    root.windMph = parseInt(c.windspeedMiles);
                    root.windDir = c.winddir16Point || "";
                    root.description = (c.weatherDesc && c.weatherDesc[0]) ? c.weatherDesc[0].value : "";
                    root.code = parseInt(c.weatherCode);

                    var area = d.nearest_area && d.nearest_area[0];
                    if (area) {
                        var name = area.areaName[0].value;
                        var region = area.region && area.region[0] ? area.region[0].value : "";
                        root.location = region && region !== name ? (name + ", " + region) : name;
                    }

                    var astro = d.weather[0].astronomy[0];
                    root.sunrise = astro.sunrise;
                    root.sunset = astro.sunset;

                    var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                    var fc = [];
                    for (var i = 0; i < d.weather.length && i < 3; i++) {
                        var w = d.weather[i];
                        var noon = w.hourly[Math.min(4, w.hourly.length - 1)];
                        var dt = new Date(w.date + "T00:00:00");
                        fc.push({
                            date: w.date,
                            day: i === 0 ? "Today" : days[dt.getDay()],
                            minC: parseInt(w.mintempC), maxC: parseInt(w.maxtempC),
                            minF: parseInt(w.mintempF), maxF: parseInt(w.maxtempF),
                            code: parseInt(noon.weatherCode),
                            desc: (noon.weatherDesc && noon.weatherDesc[0]) ? noon.weatherDesc[0].value : ""
                        });
                    }
                    root.forecast = fc;
                    root.ready = true;
                } catch (e) {
                    console.log("Weather parse error:", e);
                }
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        triggeredOnStart: true
        repeat: true
        onTriggered: root.refresh()
    }

    // Persist unit choice.
    FileView {
        id: store
        path: Quickshell.statePath("weather-unit")
        onLoaded: root.useFahrenheit = text().trim() !== "C"
    }
}
