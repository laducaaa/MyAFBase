#!/usr/bin/env python3
"""Third deep enrichment pass for CONUS bases — gates, resources, newcomers."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE_DIR = ROOT / "MyAFBase/MyAFBase/Resources/Bases"
NOW = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

OCONUS = {
    "ramstein", "spangdahlem", "aviano", "incirlik", "mildenhall", "lakenheath",
    "kunsan", "osan", "yokota", "misawa", "kadena", "moron", "geilenkirchen",
    "fairford", "croughton", "molesworth", "alconbury", "izmir", "andersen",
    "jber", "eielson", "elmendorf", "richardson", "jbphh",
}

# Gate expansions keyed by base id
GATE_PATCHES: dict[str, list[dict]] = {
    "tinker": [
        {"id": "gate-tinker", "name": "Tinker Gate (Main)", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate at I-40 & S Air Depot Blvd. Visitor Center co-located outside gate.",
         "traffic": "high", "address": "I-40 & S Air Depot Blvd, Tinker AFB, OK 73145",
         "latitude": 35.4147, "longitude": -97.3866},
        {"id": "gate-vcc", "name": "Visitor Center (Pass & ID)", "status": "open",
         "hours": "Mon-Fri 0700-1500; closed federal holidays",
         "notes": "Weekend visitor passes issued at gates. Phone: 405-734-5191.",
         "traffic": "moderate", "address": "Bldg 590, I-40 & S Air Depot Blvd, Tinker AFB, OK 73145",
         "latitude": None, "longitude": None},
        {"id": "gate-hruskocy", "name": "Hruskocy Gate", "status": "open", "hours": "Open 24/7",
         "notes": "Preferred gate for vehicles towing trailers.", "traffic": "moderate",
         "address": "I-40 & Industrial Blvd, Tinker AFB, OK 73145", "latitude": None, "longitude": None},
        {"id": "gate-gott", "name": "Gott Gate", "status": "open", "hours": "Open 24/7",
         "notes": "Preferred gate for vehicles towing trailers.", "traffic": "moderate",
         "address": "S Air Depot Blvd & SE 59th St, Tinker AFB, OK 73145", "latitude": None, "longitude": None},
        {"id": "gate-lancer", "name": "Lancer Gate", "status": "open", "hours": "Mon-Fri 0500-2000",
         "notes": "Closed weekends and federal holidays.", "traffic": "moderate",
         "address": "S Douglas Blvd N of SE 44th St, Tinker AFB, OK 73145", "latitude": None, "longitude": None},
    ],
    "dyess": [
        {"id": "gate-main", "name": "Main Gate (Arnold Blvd)", "status": "open", "hours": "Open 24/7",
         "notes": "Only 24/7 gate. Visitor Control Center at 1518 E Arnold Blvd, Bldg 9265.",
         "traffic": "high", "address": "1518 E Arnold Blvd, Dyess AFB, TX 79607",
         "latitude": 32.4208, "longitude": -99.8486},
        {"id": "gate-vcc", "name": "Visitor Control Center (Bldg 9265)", "status": "open",
         "hours": "Mon-Fri 0600-2200; closed weekends and federal holidays",
         "notes": "Day passes and visitor registration. REAL ID required. Phone: 325-696-2432.",
         "traffic": "moderate", "address": "1518 E Arnold Blvd, Bldg 9265, Dyess AFB, TX 79607",
         "latitude": None, "longitude": None},
        {"id": "gate-tye", "name": "Tye Gate", "status": "open", "hours": "Mon-Fri 0530-1730; closed weekends and federal holidays",
         "notes": "Weekday commuter gate.", "traffic": "low",
         "address": "Tye Gate, Dyess AFB, TX 79607", "latitude": None, "longitude": None},
    ],
    "eglin": [
        {"id": "gate-east", "name": "East Gate", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 access. After-hours visitor passes from gate guards (not contractors/foreign nationals).",
         "traffic": "high", "address": "East Gate, Eglin AFB, FL 32542", "latitude": 30.4833, "longitude": -86.5254},
        {"id": "gate-west", "name": "West Gate", "status": "open", "hours": "Open 24/7",
         "notes": "24/7 alternate access.", "traffic": "moderate",
         "address": "West Gate, Eglin AFB, FL 32542", "latitude": None, "longitude": None},
        {"id": "gate-vcc", "name": "Visitor Control Center (Armament Museum)", "status": "open",
         "hours": "Mon-Fri 0700-1600; Sat-Sun 0800-1200",
         "notes": "Bldg 2938 at Air Force Armament Museum. Passes no longer issued at gate VCC during duty hours.",
         "traffic": "moderate", "address": "100 Museum Dr, Bldg 2938, Eglin AFB, FL 32542",
         "latitude": None, "longitude": None},
    ],
    "grand-forks": [
        {"id": "gate-main", "name": "Main Gate", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate with Visitor Control Center (Bldg 812). After-hours visitors report to Main Gate Bldg 144.",
         "traffic": "high", "address": "Main Gate, Grand Forks AFB, ND 58205",
         "latitude": 47.9611, "longitude": -97.4012},
        {"id": "gate-vcc", "name": "Visitor Control Center (Bldg 812)", "status": "open",
         "hours": "Mon-Fri 0730-1630; closed federal holidays, down days, and family days",
         "notes": "Day passes and visitor registration. Phone: 701-747-3587.",
         "traffic": "moderate", "address": "Bldg 812, Grand Forks AFB, ND 58205", "latitude": None, "longitude": None},
        {"id": "gate-south", "name": "Commercial (South) Gate", "status": "open",
         "hours": "Mon-Fri 0600-1900; closed weekends and federal holidays",
         "notes": "Commercial VCC Bldg 147 open Mon-Fri 0630-1700.", "traffic": "moderate",
         "address": "Highway 2 east side, Grand Forks AFB, ND 58205", "latitude": None, "longitude": None},
        {"id": "gate-eielson-school", "name": "Eielson School Gate", "status": "open",
         "hours": "Mon-Fri: inbound 0600-1530; outbound 1600-1800",
         "notes": "Limited weekday access on County Rd 3 north of Main Gate.", "traffic": "low",
         "address": "County Rd 3, Grand Forks AFB, ND 58205", "latitude": None, "longitude": None},
    ],
    "laughlin": [
        {"id": "gate-west", "name": "West Gate (Main)", "status": "open", "hours": "Open 24/7",
         "notes": "Only 24/7 gate. After-hours visitor passes from gate guards when VCC closed.",
         "traffic": "high", "address": "West Gate, Laughlin AFB, TX 78843",
         "latitude": 29.3597, "longitude": -100.7778},
        {"id": "gate-north", "name": "North Gate", "status": "open",
         "hours": "Mon-Fri 1430-1730 outbound only; closed weekends and federal holidays",
         "notes": "Outbound-only weekday gate.", "traffic": "low",
         "address": "North Gate, Laughlin AFB, TX 78843", "latitude": None, "longitude": None},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open",
         "hours": "Mon-Fri 0700-1600; closed AETC resiliency days and federal holidays",
         "notes": "Day passes and visitor registration. REAL ID required.",
         "traffic": "moderate", "address": "Laughlin AFB, TX 78843", "latitude": None, "longitude": None},
    ],
    "malmstrom": [
        {"id": "gate-10th", "name": "10th Ave Gate (Main)", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate with Visitor Control Center.",
         "traffic": "high", "address": "10th Ave N, Malmstrom AFB, MT 59402",
         "latitude": 47.5053, "longitude": -111.1831},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open", "hours": "Daily 0600-2200",
         "notes": "Visitor passes and base access. REAL ID required.",
         "traffic": "moderate", "address": "Malmstrom AFB, MT 59402", "latitude": None, "longitude": None},
        {"id": "gate-2nd", "name": "2nd Ave Gate", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed weekends and federal holidays",
         "notes": "Weekday commuter gate.", "traffic": "low",
         "address": "2nd Ave N, Malmstrom AFB, MT 59402", "latitude": None, "longitude": None},
    ],
    "minot": [
        {"id": "gate-main", "name": "Main Gate (Bldg 240)", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate with Visitor Control Center.",
         "traffic": "high", "address": "Main Gate, Minot AFB, ND 58705",
         "latitude": 48.4156, "longitude": -101.3587},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open",
         "hours": "Mon-Fri 0630-1630; closed weekends and federal holidays",
         "notes": "Day passes and visitor registration. REAL ID required.",
         "traffic": "moderate", "address": "Bldg 240, Minot AFB, ND 58705", "latitude": None, "longitude": None},
        {"id": "gate-north", "name": "North Gate", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed weekends and federal holidays",
         "notes": "Weekday commuter gate.", "traffic": "low",
         "address": "North Gate, Minot AFB, ND 58705", "latitude": None, "longitude": None},
    ],
    "mountain-home": [
        {"id": "gate-main", "name": "Main Gate", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate with Visitor Control Center.",
         "traffic": "high", "address": "Main Gate, Mountain Home AFB, ID 83648",
         "latitude": 43.0436, "longitude": -115.8724},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open",
         "hours": "Mon-Fri 0700-1600; closed weekends and federal holidays",
         "notes": "Day passes and visitor registration. REAL ID required.",
         "traffic": "moderate", "address": "Mountain Home AFB, ID 83648", "latitude": None, "longitude": None},
        {"id": "gate-west", "name": "West Gate", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed weekends and federal holidays",
         "notes": "Weekday commuter gate.", "traffic": "low",
         "address": "West Gate, Mountain Home AFB, ID 83648", "latitude": None, "longitude": None},
    ],
    "patrick": [
        {"id": "gate-main", "name": "South Gate (Main)", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate. Visitor Control Center at South Gate.",
         "traffic": "high", "address": "South Gate, Patrick SFB, FL 32925",
         "latitude": 28.2342, "longitude": -80.6101},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open",
         "hours": "Mon-Fri 0700-1500; closed weekends and federal holidays",
         "notes": "Day passes and visitor registration. REAL ID required.",
         "traffic": "moderate", "address": "South Gate, Patrick SFB, FL 32925", "latitude": None, "longitude": None},
        {"id": "gate-north", "name": "North Gate", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed weekends and federal holidays",
         "notes": "Weekday access for authorized personnel.", "traffic": "low",
         "address": "North Gate, Patrick SFB, FL 32925", "latitude": None, "longitude": None},
    ],
    "andrews": [
        {"id": "gate-main", "name": "Main Gate", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate at Joint Base Andrews.", "traffic": "high",
         "address": "Main Gate, Joint Base Andrews, MD 20762", "latitude": 38.8108, "longitude": -76.8670},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open",
         "hours": "Mon-Fri 0600-1800; Sat 0800-1600; closed Sun and federal holidays",
         "notes": "1832 Robert M Bond Dr. Phone: 301-981-0232.",
         "traffic": "moderate", "address": "1832 Robert M Bond Dr, JB Andrews, MD 20762", "latitude": None, "longitude": None},
        {"id": "gate-virginia", "name": "Virginia Gate", "status": "open", "hours": "Daily 0500-2100",
         "notes": "Alternate access gate.", "traffic": "moderate",
         "address": "Virginia Gate, JB Andrews, MD 20762", "latitude": None, "longitude": None},
        {"id": "gate-pearl-harbor", "name": "Pearl Harbor Gate", "status": "open",
         "hours": "Inbound 0500-1600; Outbound 0500-1800",
         "notes": "Limited inbound/outbound hours.", "traffic": "low",
         "address": "Pearl Harbor Gate, JB Andrews, MD 20762", "latitude": None, "longitude": None},
    ],
    "barksdale": [
        {"id": "gate-west", "name": "Shreveport (West) Gate — Main", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate with West Gate Visitor Center (0600-2200 daily). After-hours passes at gate.",
         "traffic": "high", "address": "Barksdale Blvd, Barksdale AFB, LA 71110",
         "latitude": 32.5010, "longitude": -93.6627},
        {"id": "gate-vcc-west", "name": "West Gate Visitor Center", "status": "open", "hours": "Daily 0600-2200",
         "notes": "REAL ID required. Phone: 318-456-3587.", "traffic": "moderate",
         "address": "Wilbur Wright Dr, Barksdale AFB, LA 71110", "latitude": None, "longitude": None},
        {"id": "gate-north", "name": "Bossier (North) Gate", "status": "open",
         "hours": "Mon-Fri 0600-1745; Sat 0800-1400; closed Sun",
         "notes": "Weekday and Saturday access.", "traffic": "moderate",
         "address": "Bossier Gate, Barksdale AFB, LA 71110", "latitude": None, "longitude": None},
        {"id": "gate-bodcau", "name": "Bodcau (South) Gate", "status": "open",
         "hours": "Mon-Thu 0430-2359; Fri-Sun 0430-0100",
         "notes": "Extended weekend hours.", "traffic": "moderate",
         "address": "Bodcau Gate, Barksdale AFB, LA 71110", "latitude": None, "longitude": None},
        {"id": "gate-east", "name": "Industrial (East) Gate", "status": "open",
         "hours": "Mon-Fri 0545-1745; passenger inbound Mon-Fri 0630-0800 only",
         "notes": "Commercial and limited passenger access. East VCC Mon-Fri 0600-1745.", "traffic": "low",
         "address": "East Gate, Barksdale AFB, LA 71110", "latitude": None, "longitude": None},
    ],
    "shaw": [
        {"id": "gate-main", "name": "Main Gate", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate. VCC adjacent to Main Gate on Broad St/Shaw Dr.",
         "traffic": "high", "address": "Main Gate, Shaw AFB, SC 29152",
         "latitude": 33.9727, "longitude": -80.4706},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open",
         "hours": "Mon-Fri 0730-1630; closed weekends and federal holidays",
         "notes": "After-hours passes at Main Gate Security Forces. Phone: 803-895-2038.",
         "traffic": "moderate", "address": "Broad St/Shaw Dr, Shaw AFB, SC 29152", "latitude": None, "longitude": None},
        {"id": "gate-sumter", "name": "Sumter Gate", "status": "open", "hours": "Open 24/7",
         "notes": "24/7 alternate access (temporary hours).", "traffic": "moderate",
         "address": "Sumter Gate, Shaw AFB, SC 29152", "latitude": None, "longitude": None},
        {"id": "gate-441", "name": "441 Gate", "status": "open", "hours": "Daily 0600-2000",
         "notes": "Temporary 7-day access.", "traffic": "low",
         "address": "441 Gate, Shaw AFB, SC 29152", "latitude": None, "longitude": None},
    ],
    "offutt": [
        {"id": "gate-stratcom", "name": "STRATCOM Gate", "status": "open", "hours": "Open 24/7",
         "notes": "24/7 gate. After-hours visitor passes when VCC closed.", "traffic": "high",
         "address": "Capehart Rd, Offutt AFB, NE 68113", "latitude": 41.1183, "longitude": -95.9150},
        {"id": "gate-kenney", "name": "Kenney (Flag) Gate", "status": "open", "hours": "Daily 0600-2100",
         "notes": "Primary visitor gate off Fort Crook Rd.", "traffic": "high",
         "address": "Fort Crook Rd, Offutt AFB, NE 68113", "latitude": None, "longitude": None},
        {"id": "gate-bellevue", "name": "Bellevue Gate", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed federal holidays, ACC Family Days, and Wing Goal Days",
         "notes": "Weekday access from Bellevue.", "traffic": "moderate",
         "address": "Bellevue Gate, Offutt AFB, NE 68113", "latitude": None, "longitude": None},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open",
         "hours": "Mon-Fri 0700-1600; closed federal holidays, ACC Family Days, and Wing Goal Days",
         "notes": "Day passes and visitor registration.", "traffic": "moderate",
         "address": "Offutt AFB, NE 68113", "latitude": None, "longitude": None},
    ],
    "dover": [
        {"id": "gate-main", "name": "Main Gate (Liberty Way)", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 access off Route 113.", "traffic": "high",
         "address": "Liberty Way, Dover AFB, DE 19902", "latitude": 39.1301, "longitude": -75.4663},
        {"id": "gate-north", "name": "North Gate", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed weekends and federal holidays",
         "notes": "Weekday commuter gate.", "traffic": "moderate",
         "address": "North Gate, Dover AFB, DE 19902", "latitude": None, "longitude": None},
        {"id": "gate-south", "name": "South Gate", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed weekends and federal holidays",
         "notes": "Weekday commuter gate.", "traffic": "low",
         "address": "South Gate, Dover AFB, DE 19902", "latitude": None, "longitude": None},
        {"id": "gate-vcc", "name": "Visitor Control Center (Bldg 520)", "status": "open",
         "hours": "Mon-Fri 0600-1750; Sat-Sun 0900-1630",
         "notes": "REAL ID or alternate ID docs required. Phone: 302-677-3645; after-hours 302-677-6664.",
         "traffic": "moderate", "address": "Bldg 520, Dover AFB, DE 19902", "latitude": None, "longitude": None},
    ],
    "ellsworth": [
        {"id": "gate-main", "name": "Main Gate (Elsworth Blvd)", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate.", "traffic": "high",
         "address": "Main Gate, Ellsworth AFB, SD 57706", "latitude": 44.1450, "longitude": -103.1036},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open",
         "hours": "Mon-Fri 0600-1800; Sat-Sun 0900-1700",
         "notes": "Day passes and visitor registration. Phone: 605-385-2895.",
         "traffic": "moderate", "address": "Ellsworth AFB, SD 57706", "latitude": None, "longitude": None},
    ],
    "vandenberg": [
        {"id": "gate-santa-maria", "name": "Santa Maria Gate (Main)", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate. Visitor Center at 6 California Blvd outside gate Mon-Fri 0600-1800.",
         "traffic": "high", "address": "Santa Maria Gate, Vandenberg SFB, CA 93437",
         "latitude": 34.7423, "longitude": -120.5724},
        {"id": "gate-vcc", "name": "Visitor Center", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed Sat-Sun and federal holidays",
         "notes": "Phone: 805-606-7663. Does not sell merchandise or provide launch schedules.",
         "traffic": "moderate", "address": "6 California Blvd, Vandenberg SFB, CA 93437", "latitude": None, "longitude": None},
        {"id": "gate-south", "name": "South Gate", "status": "open", "hours": "Open 24/7",
         "notes": "24/7 alternate access.", "traffic": "moderate",
         "address": "South Gate, Vandenberg SFB, CA 93437", "latitude": None, "longitude": None},
        {"id": "gate-solvang", "name": "Solvang Gate", "status": "open", "hours": "Daily 0600-2000",
         "notes": "Daily access gate.", "traffic": "low",
         "address": "Solvang Gate, Vandenberg SFB, CA 93437", "latitude": None, "longitude": None},
        {"id": "gate-lompoc", "name": "Lompoc Gate (Commercial)", "status": "open",
         "hours": "Commercial 0600-1200; all traffic 1200-1800",
         "notes": "Commercial vehicle inspections mornings; all traffic afternoons.", "traffic": "low",
         "address": "Lompoc Gate, Vandenberg SFB, CA 93437", "latitude": None, "longitude": None},
    ],
    "whiteman": [
        {"id": "gate-spirit", "name": "Spirit Gate (Main)", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate.", "traffic": "high",
         "address": "Spirit Gate, Whiteman AFB, MO 65305", "latitude": 38.7303, "longitude": -93.5479},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed weekends and federal holidays",
         "notes": "Day passes and visitor registration. REAL ID required.",
         "traffic": "moderate", "address": "Whiteman AFB, MO 65305", "latitude": None, "longitude": None},
        {"id": "gate-south", "name": "South Gate", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed weekends and federal holidays",
         "notes": "Weekday commuter gate.", "traffic": "low",
         "address": "South Gate, Whiteman AFB, MO 65305", "latitude": None, "longitude": None},
    ],
    "altus": [
        {"id": "gate-main", "name": "Main Gate", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate with Visitor Center.", "traffic": "high",
         "address": "Main Gate, Altus AFB, OK 73523", "latitude": 34.6671, "longitude": -99.2667},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open",
         "hours": "Mon-Fri 0600-1700; closed weekends and federal holidays",
         "notes": "Day passes and visitor registration. REAL ID required.",
         "traffic": "moderate", "address": "Altus AFB, OK 73523", "latitude": None, "longitude": None},
    ],
}

# Per-base resource field updates by resource id
RESOURCE_PATCHES: dict[str, dict[str, dict]] = {
    "tinker": {
        "res-tinker-vcc": {"hours": "Mon-Fri 0700-1500", "phone": "405-734-5191",
            "address": "Bldg 590, I-40 & S Air Depot Blvd, Tinker AFB, OK 73145",
            "url": "https://www.tinker.af.mil/About-Tinker/Newcomers-Info/"},
    },
    "dyess": {
        "res-dyess-vcc": {"hours": "Mon-Fri 0600-2200", "phone": "325-696-2432",
            "address": "1518 E Arnold Blvd, Bldg 9265, Dyess AFB, TX 79607"},
    },
    "grand-forks": {
        "res-grand-forks-vcc": {"hours": "Mon-Fri 0730-1630", "phone": "701-747-3587",
            "address": "Bldg 812, Grand Forks AFB, ND 58205",
            "url": "https://www.grandforks.af.mil/Grand-Forks-Virtual-Visitor-Center/"},
    },
    "laughlin": {
        "res-laughlin-vcc": {"hours": "Mon-Fri 0700-1600", "phone": "830-298-5211",
            "url": "https://www.laughlin.af.mil/About-Us/Visitor-Control-Center/"},
    },
    "malmstrom": {
        "res-malmstrom-vcc": {"hours": "Daily 0600-2200", "phone": "406-731-2707"},
    },
    "eglin": {
        "res-eglin-visitor-center": {"hours": "Mon-Fri 0700-1600; Sat-Sun 0800-1200",
            "address": "100 Museum Dr, Bldg 2938, Eglin AFB, FL 32542",
            "url": "https://www.eglin.af.mil/About-Us/Fact-Sheets/Display/Article/3886337/eglin-visitor-control-center/"},
    },
    "travis": {
        "res-travis-visitor-center": {"hours": "Mon-Fri 0600-1800; Sat-Sun 0800-1600", "phone": "707-424-1462"},
    },
    "sheppard": {
        "res-sheppard-visitor-center": {"hours": "Mon-Fri 0630-1700", "phone": "940-676-7441"},
    },
    "andrews": {
        "res-andrews-vcc": {"hours": "Mon-Fri 0600-1800; Sat 0800-1600", "phone": "301-981-0232",
            "address": "1832 Robert M Bond Dr, JB Andrews, MD 20762"},
    },
    "barksdale": {
        "res-barksdale-vcc": {"hours": "Daily 0600-2200", "phone": "318-456-3587"},
    },
    "shaw": {
        "res-shaw-vcc": {"hours": "Mon-Fri 0730-1630", "phone": "803-895-2038"},
    },
    "offutt": {
        "res-offutt-vcc": {"hours": "Mon-Fri 0700-1600", "phone": "402-294-4138"},
    },
    "dover": {
        "res-dover-vcc": {"hours": "Mon-Fri 0600-1750; Sat-Sun 0900-1630", "phone": "302-677-3645"},
    },
    "ellsworth": {
        "res-ellsworth-vcc": {"hours": "Mon-Fri 0600-1800; Sat-Sun 0900-1700", "phone": "605-385-2895"},
    },
    "vandenberg": {
        "res-vandenberg-vcc": {"hours": "Mon-Fri 0600-1800", "phone": "805-606-7663",
            "address": "6 California Blvd, Vandenberg SFB, CA 93437"},
    },
}

NEWCOMERS_DEFAULTS = {
    "nc-1": ("Required Documents",
             "PCS orders, CAC, medical/dental records, marriage and birth certificates if applicable, and travel receipts for finance settlement."),
    "nc-2": ("In-Processing Schedule",
             "Report to your gaining unit upon arrival and visit MPF within required timelines. Contact base lodging for after-hours arrivals."),
    "nc-4": ("Sponsor Program",
             "Your sponsor should meet you upon arrival. Contact M&FRC if no sponsor is assigned before departure."),
}


def ensure_newcomers(data: dict) -> None:
    nc = data.setdefault("newcomers", {})
    nc.setdefault("moreInfoURL", f"https://www.{data['id'].replace('-', '')}.af.mil/")
    pa = nc.setdefault("primaryAction", {})
    if not pa.get("phone"):
        for em in data.get("emergencyNumbers", []):
            if "Base Operator" in em.get("label", ""):
                pa["phone"] = em["number"]
                break
    sections = {s["id"]: s for s in nc.get("sections", [])}
    for sid, (title, body) in NEWCOMERS_DEFAULTS.items():
        if sid not in sections:
            nc.setdefault("sections", []).append({"id": sid, "title": title, "body": body, "links": None})
    if not any(s.get("id") == "nc-3" for s in nc.get("sections", [])):
        nc["sections"].append({
            "id": "nc-3", "title": "Housing",
            "body": "Contact the Housing Office before arrival. Base lodging available for initial arrivals.",
            "links": [{"id": "link-housing", "title": "Housing Office",
                       "url": f"https://www.housing.af.mil/housing/housing-on-base/{data['id']}/"}],
        })
    if not any(s.get("id") == "nc-5" for s in nc.get("sections", [])):
        nc["sections"].append({
            "id": "nc-5", "title": "Quick Resources",
            "body": "Official installation resources plus Military OneSource for relocation support.",
            "links": [
                {"id": "link-mos", "title": "Military OneSource", "url": "https://www.militaryonesource.mil/"},
            ],
        })


def patch_resources(data: dict, patches: dict[str, dict]) -> int:
    n = 0
    by_id = {r["id"]: r for r in data["resources"]}
    for rid, fields in patches.items():
        if rid in by_id:
            by_id[rid].update(fields)
            n += 1
    return n


def enrich_base(bid: str) -> dict:
    path = BASE_DIR / f"{bid}.json"
    with open(path) as f:
        data = json.load(f)

    changed = []
    if bid in GATE_PATCHES:
        data["gates"] = GATE_PATCHES[bid]
        changed.append("gates")

    if bid in RESOURCE_PATCHES:
        n = patch_resources(data, RESOURCE_PATCHES[bid])
        if n:
            changed.append(f"{n} resources")

    ensure_newcomers(data)
    data["dataUpdatedAt"] = NOW

    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    return {
        "id": bid,
        "resources": len(data["resources"]),
        "gates": len(data["gates"]),
        "changed": changed,
    }


def main() -> None:
    results = []
    for path in sorted(BASE_DIR.glob("*.json")):
        bid = path.stem
        if bid in OCONUS or bid.startswith("_") or bid == "bases_index":
            continue
        results.append(enrich_base(bid))

    print(f"Enriched {len(results)} CONUS bases at {NOW}\n")
    for i, r in enumerate(results, 1):
        ch = ", ".join(r["changed"]) if r["changed"] else "timestamp+newcomers"
        print(f"  {i:2}. {r['id']:<22} res={r['resources']:2} gates={r['gates']:2}  [{ch}]")


if __name__ == "__main__":
    main()
