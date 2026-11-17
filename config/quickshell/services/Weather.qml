pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Weather via Open-Meteo (no API key) with ipapi.co for IP geolocation.
// Provides current conditions, an hourly forecast and a 7-day daily forecast.
// Refreshes every 30 min. All values are fetched in metric and converted to
// imperial in QML so the unit toggle is instant (no re-fetch).
Singleton {
    id: root

    property bool useFahrenheit: true

    // Geolocation (cached across refreshes).
    property real lat: 0
    property real lon: 0

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
    property int code: 0
    property bool currentIsDay: true
    property string sunrise: ""
    property string sunset: ""

    // 7-day forecast: [{ date, day, code, minC, maxC, minF, maxF, desc }].
    property var forecast: []
    // Hourly forecast (upcoming ~24h): [{ hour, tempC, tempF, code, pop, isDay }].
    property var hourly: []

    readonly property int temp: useFahrenheit ? tempF : tempC
    readonly property int feels: useFahrenheit ? feelsF : feelsC
    readonly property string unit: useFahrenheit ? "°F" : "°C"
    readonly property int wind: useFahrenheit ? windMph : windKmph
    readonly property string windUnit: useFahrenheit ? "mph" : "km/h"

    function toggleUnit() { useFahrenheit = !useFahrenheit; store.setText(useFahrenheit ? "F" : "C"); }

    function refresh() {
        if (loading)
            return;
        loading = true;
        if (lat === 0 && lon === 0)
            geoProc.running = true;     // locate, then fetch (chained)
        else
            startWeather();
    }

    // ---- Unit / value helpers ------------------------------------------------
    function cToF(c) { return Math.round(c * 9 / 5 + 32); }
    function kmhToMph(k) { return Math.round(k * 0.621371); }

    readonly property var compass: ["N","NNE","NE","ENE","E","ESE","SE","SSE",
                                    "S","SSW","SW","WSW","W","WNW","NW","NNW"]
    function dirFromDeg(deg) { return compass[Math.round(deg / 22.5) % 16]; }

    readonly property bool isDay: currentIsDay

    // ---- WMO weather-code mapping -------------------------------------------
    function descFor(c) {
        switch (parseInt(c)) {
        case 0: return "Clear sky";
        case 1: return "Mainly clear";
        case 2: return "Partly cloudy";
        case 3: return "Overcast";
        case 45: case 48: return "Fog";
        case 51: return "Light drizzle";
        case 53: return "Drizzle";
        case 55: return "Heavy drizzle";
        case 56: case 57: return "Freezing drizzle";
        case 61: return "Light rain";
        case 63: return "Rain";
        case 65: return "Heavy rain";
        case 66: case 67: return "Freezing rain";
        case 71: return "Light snow";
        case 73: return "Snow";
        case 75: return "Heavy snow";
        case 77: return "Snow grains";
        case 80: return "Light showers";
        case 81: return "Showers";
        case 82: return "Heavy showers";
        case 85: return "Snow showers";
        case 86: return "Heavy snow showers";
        case 95: return "Thunderstorm";
        case 96: case 99: return "Thunderstorm, hail";
        default: return "";
        }
    }

    // Map WMO codes to Nerd Font glyphs (day/night aware).
    function iconFor(c, day) {
        function g(cp) { return String.fromCodePoint(cp); }
        switch (parseInt(c)) {
        case 0: case 1: return day ? g(0xF0599) : g(0xF0594);      // clear
        case 2: return day ? g(0xF0595) : g(0xF0F31);              // partly cloudy
        case 3: return g(0xF0590);                                 // overcast
        case 45: case 48: return g(0xF0591);                       // fog
        case 51: case 53: case 55:
        case 61: case 63:
        case 80: case 81: return g(0xF0597);                       // drizzle / light rain
        case 65: case 82: return g(0xF0596);                       // heavy rain
        case 56: case 57: case 66: case 67: return g(0xF067F);     // freezing / sleet
        case 71: case 73: case 75: case 77:
        case 85: case 86: return g(0xF0598);                       // snow
        case 95: case 96: case 99: return g(0xF067E);              // thunder
        default: return g(0xF0590);
        }
    }

    function currentIcon() { return iconFor(code, currentIsDay); }

    // ---- Networking ----------------------------------------------------------
    function startWeather() {
        weatherProc.command = ["curl", "-s", "--max-time", "15",
            "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + root.lat + "&longitude=" + root.lon
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,"
            + "weather_code,wind_speed_10m,wind_direction_10m,is_day"
            + "&hourly=temperature_2m,weather_code,precipitation_probability,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
            + "&timezone=auto&forecast_days=7"];
        weatherProc.running = true;
    }

    // Step 1: IP geolocation via wttr.in (returns coordinates + place name).
    Process {
        id: geoProc
        command: ["curl", "-s", "--max-time", "15", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text);
                    var area = d.nearest_area && d.nearest_area[0];
                    if (area) {
                        root.lat = parseFloat(area.latitude);
                        root.lon = parseFloat(area.longitude);
                        var name = area.areaName && area.areaName[0] ? area.areaName[0].value : "";
                        var region = area.region && area.region[0] ? area.region[0].value : "";
                        root.location = (region && region !== name)
                            ? (name + ", " + region) : (name || "Weather");
                    }
                } catch (e) {
                    console.log("Weather geo error:", e);
                }
                if (root.lat !== 0 || root.lon !== 0)
                    root.startWeather();
                else
                    root.loading = false;
            }
        }
    }

    // Step 2: Open-Meteo forecast.
    Process {
        id: weatherProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    var d = JSON.parse(this.text);

                    // Current conditions.
                    var cur = d.current;
                    root.tempC = Math.round(cur.temperature_2m);
                    root.tempF = root.cToF(cur.temperature_2m);
                    root.feelsC = Math.round(cur.apparent_temperature);
                    root.feelsF = root.cToF(cur.apparent_temperature);
                    root.humidity = Math.round(cur.relative_humidity_2m);
                    root.windKmph = Math.round(cur.wind_speed_10m);
                    root.windMph = root.kmhToMph(cur.wind_speed_10m);
                    root.windDir = root.dirFromDeg(cur.wind_direction_10m);
                    root.code = parseInt(cur.weather_code);
                    root.currentIsDay = cur.is_day === 1;
                    root.description = root.descFor(root.code);

                    // Daily (7-day) forecast.
                    var days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
                    var dl = d.daily;
                    var fc = [];
                    for (var i = 0; i < dl.time.length; i++) {
                        var dt = new Date(dl.time[i] + "T00:00:00");
                        fc.push({
                            date: dl.time[i],
                            day: i === 0 ? "Today" : days[dt.getDay()],
                            code: parseInt(dl.weather_code[i]),
                            maxC: Math.round(dl.temperature_2m_max[i]),
                            minC: Math.round(dl.temperature_2m_min[i]),
                            maxF: root.cToF(dl.temperature_2m_max[i]),
                            minF: root.cToF(dl.temperature_2m_min[i]),
                            desc: root.descFor(dl.weather_code[i])
                        });
                    }
                    root.forecast = fc;

                    // Sunrise/sunset for today (HH:MM, 12h).
                    function hhmm(iso) {
                        var t = new Date(iso);
                        var h = t.getHours(), m = t.getMinutes();
                        var ap = h >= 12 ? "PM" : "AM";
                        var h12 = h % 12; if (h12 === 0) h12 = 12;
                        return h12 + ":" + (m < 10 ? "0" + m : m) + " " + ap;
                    }
                    if (dl.sunrise && dl.sunrise[0]) root.sunrise = hhmm(dl.sunrise[0]);
                    if (dl.sunset && dl.sunset[0]) root.sunset = hhmm(dl.sunset[0]);

                    // Hourly: next ~24h starting from the current hour.
                    var hl = d.hourly;
                    var now = new Date();
                    var hrs = [];
                    for (var j = 0; j < hl.time.length && hrs.length < 24; j++) {
                        var ht = new Date(hl.time[j]);
                        if (ht.getTime() + 3600000 < now.getTime())
                            continue; // skip past hours
                        var hh = ht.getHours();
                        var ap2 = hh >= 12 ? "PM" : "AM";
                        var h12b = hh % 12; if (h12b === 0) h12b = 12;
                        hrs.push({
                            hour: (hrs.length === 0 ? "Now" : (h12b + ap2)),
                            tempC: Math.round(hl.temperature_2m[j]),
                            tempF: root.cToF(hl.temperature_2m[j]),
                            code: parseInt(hl.weather_code[j]),
                            pop: hl.precipitation_probability ? parseInt(hl.precipitation_probability[j]) : 0,
                            isDay: hl.is_day ? hl.is_day[j] === 1 : true
                        });
                    }
                    root.hourly = hrs;

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
