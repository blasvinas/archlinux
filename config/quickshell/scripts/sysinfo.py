#!/usr/bin/env python3
"""Emit a JSON snapshot of system stats for the Quickshell dashboard.

Fields: cpu (0..100), cpuCores [..], mem {used,total,percent},
swap {used,total,percent}, disk {used,total,percent}, temp (C),
uptime (seconds), load [1,5,15], host, user.
All values are best-effort; missing data is reported as 0 / "".
"""

import glob
import json
import os
import re
import shutil
import subprocess
import time


def read_cpu():
    """Return (total_jiffies, idle_jiffies) per cpu line (index 0 = aggregate)."""
    out = []
    try:
        with open("/proc/stat") as f:
            for line in f:
                if not line.startswith("cpu"):
                    continue
                parts = line.split()
                if len(parts) < 5:
                    continue
                vals = [int(x) for x in parts[1:]]
                idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
                total = sum(vals)
                out.append((total, idle))
    except OSError:
        pass
    return out


CLK_TCK = os.sysconf("SC_CLK_TCK")
PAGE_SIZE = os.sysconf("SC_PAGE_SIZE")


def proc_times():
    """Snapshot per-pid cumulative CPU jiffies -> {pid: (ticks, comm)}."""
    out = {}
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            with open(f"/proc/{pid}/stat") as f:
                data = f.read()
            # comm is wrapped in parens and may itself contain spaces/parens.
            rp = data.rindex(")")
            comm = data[data.index("(") + 1:rp]
            rest = data[rp + 2:].split()
            ticks = int(rest[11]) + int(rest[12])  # utime + stime
            out[pid] = (ticks, comm)
        except (OSError, ValueError, IndexError):
            continue
    return out


def proc_rss(pid):
    """Resident set size in bytes for a pid (0 if unavailable)."""
    try:
        with open(f"/proc/{pid}/statm") as f:
            return int(f.read().split()[1]) * PAGE_SIZE
    except (OSError, ValueError, IndexError):
        return 0


def sample(interval=0.25):
    """Sample CPU (aggregate + per-core) and per-process CPU over one interval.

    Returns (core_percentages, processes) where processes is a list of
    {pid, name, cpu, mem} for currently running tasks.
    """
    cpu_a = read_cpu()
    proc_a = proc_times()
    time.sleep(interval)
    cpu_b = read_cpu()
    proc_b = proc_times()

    cores = []
    for (t0, i0), (t1, i1) in zip(cpu_a, cpu_b):
        dt = t1 - t0
        di = i1 - i0
        cores.append(round(100.0 * (dt - di) / dt, 1) if dt > 0 else 0.0)

    procs = []
    for pid, (ticks1, comm) in proc_b.items():
        ticks0 = proc_a[pid][0] if pid in proc_a else ticks1
        dticks = max(0, ticks1 - ticks0)
        cpu = 100.0 * (dticks / CLK_TCK) / interval  # htop-style, may exceed 100
        procs.append({
            "pid": int(pid),
            "name": comm,
            "cpu": round(cpu, 1),
            "mem": proc_rss(pid),
        })
    return cores, procs


def top_processes(procs, limit=6):
    """Return {byCpu, byMem}: the heaviest processes on each axis."""
    by_cpu = sorted(procs, key=lambda p: p["cpu"], reverse=True)[:limit]
    by_mem = sorted(procs, key=lambda p: p["mem"], reverse=True)[:limit]
    return {"byCpu": by_cpu, "byMem": by_mem}


def meminfo():
    info = {}
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                k, _, v = line.partition(":")
                info[k.strip()] = int(v.split()[0])  # kB
    except OSError:
        pass
    return info


def temperature():
    # Prefer package/core temps, else first readable thermal zone.
    best = 0.0
    try:
        for zone in glob.glob("/sys/class/thermal/thermal_zone*"):
            try:
                with open(os.path.join(zone, "type")) as f:
                    ztype = f.read().strip()
                with open(os.path.join(zone, "temp")) as f:
                    t = int(f.read().strip()) / 1000.0
            except OSError:
                continue
            if ztype in ("x86_pkg_temp", "coretemp", "k10temp", "cpu-thermal"):
                return round(t, 1)
            best = max(best, t)
    except OSError:
        pass
    # hwmon fallback
    if best == 0.0:
        for hw in glob.glob("/sys/class/hwmon/hwmon*/temp1_input"):
            try:
                with open(hw) as f:
                    best = max(best, int(f.read().strip()) / 1000.0)
            except OSError:
                continue
    return round(best, 1)


def gpu():
    """Best-effort GPU usage/temperature. Returns {usage,temp,mem,memTotal,name}."""
    res = {"usage": 0.0, "temp": 0.0, "mem": 0, "memTotal": 0, "name": ""}
    # NVIDIA via nvidia-smi
    if shutil.which("nvidia-smi"):
        try:
            out = subprocess.run(
                [
                    "nvidia-smi",
                    "--query-gpu=utilization.gpu,temperature.gpu,"
                    "memory.used,memory.total,name",
                    "--format=csv,noheader,nounits",
                ],
                capture_output=True, text=True, timeout=2,
            ).stdout.strip().splitlines()
            if out:
                parts = [p.strip() for p in out[0].split(",")]
                res["usage"] = float(parts[0])
                res["temp"] = float(parts[1])
                res["mem"] = int(float(parts[2])) * 1024 * 1024
                res["memTotal"] = int(float(parts[3])) * 1024 * 1024
                res["name"] = parts[4]
                return res
        except (OSError, ValueError, subprocess.SubprocessError):
            pass
    # AMD / Intel via DRM sysfs
    for dev in sorted(glob.glob("/sys/class/drm/card*/device")):
        busy = os.path.join(dev, "gpu_busy_percent")
        if not os.path.exists(busy):
            continue
        try:
            with open(busy) as f:
                res["usage"] = float(f.read().strip())
        except OSError:
            continue
        # VRAM
        try:
            with open(os.path.join(dev, "mem_info_vram_used")) as f:
                res["mem"] = int(f.read().strip())
            with open(os.path.join(dev, "mem_info_vram_total")) as f:
                res["memTotal"] = int(f.read().strip())
        except OSError:
            pass
        # Temperature via hwmon under the device
        for hw in glob.glob(os.path.join(dev, "hwmon/hwmon*/temp1_input")):
            try:
                with open(hw) as f:
                    res["temp"] = int(f.read().strip()) / 1000.0
            except OSError:
                pass
        return res
    return res


def net_totals():
    """Total rx/tx bytes across physical interfaces (excludes lo/virtual)."""
    rx = tx = 0
    skip = re.compile(r"^(lo|docker|veth|br-|virbr|tun|tap|wg)")
    try:
        with open("/proc/net/dev") as f:
            for line in f.readlines()[2:]:
                name, _, data = line.partition(":")
                name = name.strip()
                if skip.match(name):
                    continue
                fields = data.split()
                if len(fields) >= 9:
                    rx += int(fields[0])
                    tx += int(fields[8])
    except OSError:
        pass
    return rx, tx


def main():
    cores, procs = sample()
    cpu = cores[0] if cores else 0.0
    per_core = cores[1:] if len(cores) > 1 else []

    mi = meminfo()
    mem_total = mi.get("MemTotal", 0)
    mem_avail = mi.get("MemAvailable", mi.get("MemFree", 0))
    mem_used = max(0, mem_total - mem_avail)
    swap_total = mi.get("SwapTotal", 0)
    swap_free = mi.get("SwapFree", 0)
    swap_used = max(0, swap_total - swap_free)

    try:
        du = shutil.disk_usage("/")
        disk = {
            "used": du.used,
            "total": du.total,
            "percent": round(100.0 * du.used / du.total, 1) if du.total else 0.0,
        }
    except OSError:
        disk = {"used": 0, "total": 0, "percent": 0.0}

    try:
        with open("/proc/uptime") as f:
            uptime = int(float(f.read().split()[0]))
    except OSError:
        uptime = 0

    try:
        load = list(os.getloadavg())
    except OSError:
        load = [0.0, 0.0, 0.0]

    net_rx, net_tx = net_totals()
    g = gpu()

    snapshot = {
        "cpu": cpu,
        "cpuCores": per_core,
        "mem": {
            "used": mem_used * 1024,
            "total": mem_total * 1024,
            "percent": round(100.0 * mem_used / mem_total, 1) if mem_total else 0.0,
        },
        "swap": {
            "used": swap_used * 1024,
            "total": swap_total * 1024,
            "percent": round(100.0 * swap_used / swap_total, 1) if swap_total else 0.0,
        },
        "disk": disk,
        "temp": temperature(),
        "uptime": uptime,
        "load": [round(x, 2) for x in load],
        "gpu": {
            "usage": g["usage"],
            "temp": g["temp"],
            "mem": g["mem"],
            "memTotal": g["memTotal"],
            "name": g["name"],
        },
        "net": {"rx": net_rx, "tx": net_tx, "t": time.time()},
        "procs": top_processes(procs),
        "host": os.uname().nodename,
        "user": os.environ.get("USER", ""),
    }
    print(json.dumps(snapshot))


if __name__ == "__main__":
    main()
