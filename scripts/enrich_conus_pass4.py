#!/usr/bin/env python3
"""Fourth deep enrichment pass for CONUS bases — thinner bases first, then generic-hour fixes."""

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

# Gate expansions — priority thin bases (2-gate) plus refinements
GATE_PATCHES: dict[str, list[dict]] = {
    "creech": [
        {"id": "gate-main", "name": "Main Gate (Bldg 3)", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 access on US 95. Visitor Control Center co-located at Main Gate.",
         "traffic": "high", "address": "1st Street, Bldg 3, Creech AFB, NV 89018",
         "latitude": 36.5822, "longitude": -115.6728},
        {"id": "gate-east", "name": "East Gate", "status": "open", "hours": "Open 24/7",
         "notes": "24/7 alternate access east of Indian Springs. After-hours visitor passes at gate when VCC closed.",
         "traffic": "moderate", "address": "East Gate, Creech AFB, NV 89018",
         "latitude": None, "longitude": None},
        {"id": "gate-vcc", "name": "Visitor Control Center (Main Gate)", "status": "open",
         "hours": "Mon-Fri 0600-1400; closed Sat-Sun and federal holidays",
         "notes": "Day passes and visitor registration. REAL ID required. Phone: 702-404-3694.",
         "traffic": "moderate", "address": "1st Street, Bldg 3, Creech AFB, NV 89018",
         "latitude": None, "longitude": None},
    ],
    "grissom": [
        {"id": "gate-main-hoosier-blvd", "name": "Main Gate (Hoosier Blvd)", "status": "open",
         "hours": "Open 24/7",
         "notes": "Primary 24/7 access point for Grissom ARB. Security Forces: 765-688-3384.",
         "traffic": "moderate", "address": "471 Hoosier Blvd, Grissom ARB, Peru, IN 46971",
         "latitude": 40.6481, "longitude": -86.1521},
        {"id": "gate-visitor-center", "name": "Visitor Center", "status": "open",
         "hours": "Mon-Fri 0730-1515; closed weekends and federal holidays",
         "notes": "Visitor passes and base access registration. REAL ID required. Phone: 765-688-4352.",
         "traffic": "moderate", "address": "1438 Foreman Dr, Grissom ARB, Peru, IN 46971",
         "latitude": None, "longitude": None},
        {"id": "gate-aeroplex", "name": "Grissom Aeroplex Gate (Joint-Use)", "status": "open",
         "hours": "Mon-Fri 0700-1700; closed weekends and federal holidays",
         "notes": "Joint-use airfield access for authorized Aeroplex tenants and contractors.",
         "traffic": "low", "address": "Grissom Aeroplex, Peru, IN 46971",
         "latitude": None, "longitude": None},
    ],
    "altus": [
        {"id": "gate-main", "name": "Main Gate (Falcon Road)", "status": "open", "hours": "Open 24/7",
         "notes": "Primary 24/7 gate. After-hours visitor passes issued here when VCC closed (up to 72 hours).",
         "traffic": "high", "address": "Falcon Road, Altus AFB, OK 73523",
         "latitude": 34.6671, "longitude": -99.2667},
        {"id": "gate-south", "name": "South Gate (Challenger Blvd)", "status": "open",
         "hours": "Mon-Fri 0600-1700; closed weekends and federal holidays",
         "notes": "Weekday commuter gate on Challenger Boulevard.",
         "traffic": "moderate", "address": "Challenger Blvd, Altus AFB, OK 73523",
         "latitude": None, "longitude": None},
        {"id": "gate-jasmine", "name": "Jasmine Gate (North)", "status": "open", "hours": "Open 24/7",
         "notes": "24/7 north-side gate. Convenient for Friendship and Martha communities.",
         "traffic": "moderate", "address": "Jasmine Gate, Altus AFB, OK 73523",
         "latitude": None, "longitude": None},
        {"id": "gate-vcc", "name": "Visitor Control Center", "status": "open",
         "hours": "Mon-Fri 0600-1700; closed weekends and federal holidays",
         "notes": "Located outside South Gate. Day passes up to 14 days. REAL ID required. Phone: 580-481-6340.",
         "traffic": "moderate", "address": "428 Challenger Ave, Altus AFB, OK 73523",
         "latitude": None, "longitude": None},
    ],
    "ellsworth": [
        {"id": "gate-liberty", "name": "Liberty Gate (Main)", "status": "open", "hours": "Open 24/7",
         "notes": "Only 24/7 gate. Visitor Control Center located here. Use for RV/FamCamp access.",
         "traffic": "high", "address": "1940 EP Howe Drive, Ellsworth AFB, SD 57706",
         "latitude": 44.145, "longitude": -103.1036},
        {"id": "gate-bismarck", "name": "Bismarck Gate (Commercial)", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed weekends and federal holidays",
         "notes": "Weekday commuter and commercial gate near I-90.",
         "traffic": "moderate", "address": "Bismarck Gate, Ellsworth AFB, SD 57706",
         "latitude": None, "longitude": None},
        {"id": "gate-patriot", "name": "Patriot Gate", "status": "open",
         "hours": "Mon-Fri 0600-1800; closed weekends and federal holidays",
         "notes": "Weekday commuter gate near I-90. Restricted to authorized personnel without VCC pass.",
         "traffic": "moderate", "address": "Patriot Gate, Ellsworth AFB, SD 57706",
         "latitude": None, "longitude": None},
        {"id": "gate-vcc", "name": "Visitor Control Center (Liberty Gate)", "status": "open",
         "hours": "Mon-Fri 0600-1800; Sat-Sun 0900-1700",
         "notes": "Day passes and visitor registration. REAL ID required. Phone: 605-385-2895.",
         "traffic": "moderate", "address": "2740 Eaker Drive, Ellsworth AFB, SD 57706",
         "latitude": None, "longitude": None},
    ],
}

RESOURCE_PATCHES: dict[str, dict[str, dict]] = {
    "creech": {
        "res-creech-unaccompanied-housing": {
            "address": "Bldg 24, 1065 Perimeter Rd, Creech AFB, NV 89018",
            "building": "Bldg 24",
        },
        "res-creech-medical": {
            "address": "Bldg 24, Creech AFB, NV 89018",
            "hours": "Mon-Fri 0730-1630; appointments via TRICARE Online",
            "phone": "702-404-2273",
            "building": "Bldg 24",
        },
        "res-432-fss": {
            "address": "Bldg 24, 1065 Perimeter Rd, Creech AFB, NV 89018",
            "phone": "702-404-1110",
            "building": "Bldg 24",
        },
        "res-creech-mpf": {
            "address": "Bldg 24, 1065 Perimeter Rd, Creech AFB, NV 89018",
            "phone": "702-404-1110",
            "building": "Bldg 24",
        },
        "res-creech-finance": {
            "address": "Bldg 24, 1065 Perimeter Rd, Creech AFB, NV 89018",
            "building": "Bldg 24",
        },
        "res-creech-outdoor-rec": {
            "address": "Bldg 24, Creech AFB, NV 89018",
            "phone": "702-652-2514",
        },
        "res-creech-vcc": {
            "hours": "Mon-Fri 0600-1400; after-hours at Main Gate with sponsor",
            "phone": "702-404-3694",
            "url": "https://www.creech.af.mil/",
        },
    },
    "grissom": {
        "res-grissom-chocks": {
            "hours": "Primary UTA weekends: Fri 1800-0000, Sat 1700-0000",
            "address": "6963 Tanker St, Grissom ARB, Peru, IN 46971",
            "phone": "765-688-2615",
            "building": None,
        },
        "res-grissom-fitness": {
            "phone": "765-688-2987",
        },
        "res-grissom-odr": {
            "address": "7088 Tanker St, Bldg 431, Grissom ARB, Peru, IN 46971",
            "hours": "Mon-Fri 0730-1630",
            "building": "Bldg 431",
        },
        "res-grissom-itt": {
            "hours": "Mon-Fri 0730-1630",
            "address": "7088 Tanker St, Bldg 431, Grissom ARB, Peru, IN 46971",
            "phone": "765-688-2000",
            "building": "Bldg 431",
        },
        "res-grissom-fss": {
            "address": "7207 Grissom Ave, Grissom ARB, Peru, IN 46971",
            "phone": "765-688-2752",
        },
        "res-grissom-visitor-center": {
            "hours": "Mon-Fri 0730-1515; closed weekends and federal holidays",
            "address": "1438 Foreman Dr, Grissom ARB, Peru, IN 46971",
            "phone": "765-688-4352",
        },
    },
    "altus": {
        "res-altus-dfac": {
            "hours": "Mon-Fri: Bfast 0600-0800, Lunch 1100-1300, Dinner 1630-1830; Sat-Sun: Bfast 0730-0830, Lunch 1100-1300, Dinner 1630-1800; Touch & Go 1930-0200 daily",
        },
        "res-altus-vcc": {
            "hours": "Mon-Fri 0600-1700; closed weekends and federal holidays",
            "phone": "580-481-6340",
            "address": "428 Challenger Ave, Altus AFB, OK 73523",
            "url": "https://www.altus.af.mil/About-Us/Visitor-Information/",
        },
        "res-altus-credit-union": {
            "url": "https://www.redriverfcu.org/",
        },
    },
    "ellsworth": {
        "res-ellsworth-dfac-raider": {
            "address": "Bldg 1200, Ellsworth AFB, SD 57706",
            "building": "Bldg 1200",
        },
        "res-ellsworth-bx": {
            "address": "2649 Lemay St, Bldg 1650, Ellsworth AFB, SD 57706",
            "building": "Bldg 1650",
        },
        "res-ellsworth-sentinel-cu": {
            "address": "2649 Lemay St, Ellsworth AFB, SD 57706",
            "url": "https://www.sentinelfcu.org/",
        },
        "res-ellsworth-bowling": {
            "name": "Bandit Lanes Bowling Center",
            "hours": "Mon-Thu 1200-2000; Fri 1400-2200 (Cosmic 2000-2200); Sat 1600-2200 (Cosmic 1800-2200); Sun 1200-2200",
            "url": "https://ellsworthfss.com/bandit-lanes-bowling-alley/",
        },
        "res-ellsworth-golf": {
            "address": "Prairie Ridge Golf Course, Ellsworth AFB, SD 57706",
            "hours": "Seasonal; pro shop Mon-Fri 0700-1700",
            "phone": "605-923-4999",
            "url": "https://ellsworthfss.com/",
        },
        "res-ellsworth-medical": {
            "address": "2900 Doolittle Dr, Ellsworth AFB, SD 57706",
            "hours": "Mon-Fri 0700-1630; closed third Wed afternoon for training",
            "phone": "605-385-6700",
            "building": None,
        },
        "res-ellsworth-vcc": {
            "hours": "Mon-Fri 0600-1800; Sat-Sun 0900-1700",
            "address": "2740 Eaker Drive, Ellsworth AFB, SD 57706",
            "phone": "605-385-2895",
            "url": "https://www.ellsworth.af.mil/Contact-Us/Visitor-Control-Center/",
        },
        "res-28-fss": {
            "address": "1000 Ellsworth St, Ellsworth AFB, SD 57706",
            "phone": "605-385-1110",
        },
    },
    "beale": {
        "res-beale-dfac-contrails": {
            "hours": "Mon-Fri: Bfast 0530-0800, Lunch 1030-1330, Dinner 1630-1900, Midnight 2230-0030; Sat-Sun: Bfast 0730-0900, Brunch 1030-1330, Dinner 1630-1830, Midnight 2230-0030",
            "url": "https://bealefss.com/contrails/",
            "building": None,
        },
        "res-beale-commissary": {
            "hours": "Mon closed; Tue-Thu 0900-1900; Fri 0900-1800; Sat 1000-1700; Sun 1000-1700",
            "address": "17601 25th St, Bldg 25608, Beale AFB, CA 95903",
            "phone": "530-634-2422",
            "url": "https://shop.commissaries.com/stores/beale-afb",
            "building": "Bldg 25608",
        },
        "res-beale-fitness-harris": {
            "hours": "Mon-Fri 0500-2300; Sat-Sun 0800-2000",
            "url": "https://bealefss.com/harris-fitness-center/",
        },
        "res-beale-fitness-omni": {
            "hours": "Mon-Fri 0500-2000; Sat-Sun 0800-1700",
            "url": "https://bealefss.com/omni-fitness-center/",
        },
        "res-beale-bowling": {
            "hours": "Mon-Thu 1200-2000; Fri-Sat 1200-2100; Sun 1200-1700",
            "url": "https://bealefss.com/beale-lanes/",
        },
        "res-beale-golf": {
            "address": "Beale Golf Course, Beale AFB, CA 95903",
            "phone": "530-634-2250",
            "url": "https://bealefss.com/",
        },
        "res-beale-medical": {
            "address": "15301 Warren Shingle Rd, Beale AFB, CA 95903",
            "hours": "Mon-Fri 0730-1630",
            "phone": "530-634-2941",
            "building": None,
        },
        "res-beale-vcc": {
            "hours": "Mon-Fri 0730-1630; Sat 0800-1300; Sun closed",
            "address": "24112 A St, Beale AFB, CA 95903",
            "phone": "530-634-2953",
            "url": "https://www.beale.af.mil/",
        },
        "res-9-fss": {
            "address": "17800 B St, Beale AFB, CA 95903",
            "phone": "530-634-1110",
        },
    },
    "fe-warren": {
        "res-fe-warren-dfac-chadwell": {
            "phone": "307-773-3740",
        },
        "res-fe-warren-commissary": {
            "hours": "Sun 1000-1800; Mon-Sat 0900-1900",
            "address": "1520 Randall Ave, F.E. Warren AFB, WY 82005",
            "phone": "307-773-5266",
            "url": "https://shop.commissaries.com/stores/fe-warren-afb",
        },
        "res-fe-warren-credit-union": {
            "address": "Bldg 722, F.E. Warren AFB, WY 82005",
            "url": "https://www.warrenfcu.com/",
        },
        "res-fe-warren-fitness-freedom": {
            "hours": "Mon-Fri 0500-2300; Sat-Sun 0800-1900; 24/7 CAC access after registration",
            "phone": "307-773-6199",
            "url": "https://funatwarren.com/fitness-sports/",
        },
        "res-fe-warren-fitness-independence": {
            "hours": "Mon-Fri 0500-2300; Sat-Sun 0800-1900; 24/7 CAC access after registration",
            "phone": "307-773-3863",
            "url": "https://funatwarren.com/fitness-sports/",
        },
        "res-fe-warren-mfrc": {
            "address": "Bldg 210, F.E. Warren AFB, WY 82005",
            "phone": "307-773-5941",
            "url": "https://funatwarren.com/",
        },
        "res-90-fss": {
            "address": "F.E. Warren AFB, WY 82005",
            "phone": "307-773-3510",
            "url": "https://funatwarren.com/",
        },
        "res-fe-warren-outdoor-rec": {
            "address": "6110 Buffalo Soldier Rd, F.E. Warren AFB, WY 82005",
            "phone": "307-773-3556",
            "url": "https://funatwarren.com/",
        },
        "res-fe-warren-golf": {
            "name": "Warren Adventure Park (Golf & Recreation)",
            "address": "6110 Buffalo Soldier Rd, F.E. Warren AFB, WY 82005",
            "phone": "307-773-3556",
            "url": "https://funatwarren.com/",
        },
        "res-fe-warren-medical": {
            "address": "Bldg 120, F.E. Warren AFB, WY 82005",
            "hours": "Mon-Fri 0730-1630",
            "phone": "307-773-3461",
            "url": "https://warren.tricare.mil/",
        },
        "res-fe-warren-bowling": {
            "name": "Warren Lanes Bowling Center",
            "hours": "Mon-Thu 1100-2200; Fri-Sat 1100-2300; Sun 1200-1800",
            "address": "6004 10th Cavalry, Bldg 303, F.E. Warren AFB, WY 82005",
            "phone": "307-773-2210",
            "url": "https://funatwarren.com/",
            "building": "Bldg 303",
        },
        "res-fe-warren-vcc": {
            "hours": "Daily 0600-1800; closed federal holidays",
            "address": "4600 Randall Ave, Bldg 520, F.E. Warren AFB, WY 82005",
            "phone": "307-773-3694",
            "url": "https://www.warren.af.mil/Base-Access/",
            "building": "Bldg 520",
        },
    },
    "charleston": {
        "res-charleston-commissary": {
            "hours": "Sun 1100-1800; Mon-Sat 0900-1900",
            "address": "103 Lawson Dr, Bldg 1991, Joint Base Charleston, SC 29404",
            "phone": "843-963-7469",
            "url": "https://shop.commissaries.com/stores/charleston-afb",
            "building": "Bldg 1991",
        },
        "res-sc-federal-cu": {
            "hours": "Mon-Fri 0900-1700",
            "address": "102 N Davis Dr, Bldg 322, Joint Base Charleston, SC 29404",
            "phone": "843-797-5600",
            "url": "https://www.scfederal.org/",
            "building": "Bldg 322",
        },
        "res-heritage-trust-cu": {
            "hours": "Mon-Fri 0900-1700",
            "address": "205 W Hill Blvd, Joint Base Charleston, SC 29404",
            "phone": "843-266-8300",
            "url": "https://www.heritagetrust.com/",
        },
        "res-ab-fitness": {
            "hours": "Mon-Fri 0500-2000; Sat-Sun 0900-1500; CAC 24/7 access after registration",
            "url": "https://jbcharleston.com/",
        },
        "res-sams-fitness": {
            "hours": "Mon-Fri 0530-2030; Sat-Sun 0900-1500",
            "url": "https://jbcharleston.com/",
        },
        "res-unaccompanied-housing": {
            "address": "205 W Hill Blvd, Joint Base Charleston, SC 29404",
            "phone": "843-963-3800",
        },
        "res-mfrc": {
            "hours": "Mon-Fri 0800-1630",
            "address": "102 N Davis Dr, Bldg 322, Joint Base Charleston, SC 29404",
            "phone": "843-963-4406",
            "url": "https://jbcharleston.com/",
            "building": "Bldg 322",
        },
        "res-outdoor-rec": {
            "address": "2482 Red Bank Rd, Bldg 85, Joint Base Charleston, SC 29405",
            "phone": "843-794-7190",
            "hours": "Mon-Fri 0800-1630",
            "building": "Bldg 85",
        },
        "res-medical": {
            "address": "204 W Hill Blvd, Joint Base Charleston, SC 29404",
            "hours": "Mon-Fri 0730-1630; closed third Wed afternoon for training",
            "phone": "843-963-6880",
            "building": None,
        },
    },
    "los-angeles": {
        "res-los-angeles-south-bay-bar-grill": {
            "hours": "Mon-Fri: Bfast 0600-1000, Lunch 1100-1400; bar Wed-Fri 1600-2000",
            "url": "https://lafss.com/south-bay-bar-grill/",
        },
        "res-los-angeles-harbor-view-lounge": {
            "hours": "Mon-Fri 1100-1400 lunch; Fri lounge 1700-2100; see lafss.com for events",
        },
        "res-los-angeles-bx-food-court": {
            "hours": "Mon-Sat 0700-1900; Sun 1000-1800",
        },
        "res-los-angeles-commissary": {
            "hours": "Sun/Tue-Sat 0900-1830; Mon 1100-1700",
            "phone": "424-336-2262",
        },
        "res-los-angeles-fitness": {
            "hours": "Mon-Fri 0500-2100; Sat-Sun 0800-1800; CAC access available",
            "address": "483 N Aviation Blvd, Bldg 286, Los Angeles SFB, El Segundo, CA 90245",
            "url": "https://lafss.com/fitness/",
        },
        "res-los-angeles-fss": {
            "address": "483 N Aviation Blvd, Bldg 270, Los Angeles SFB, El Segundo, CA 90245",
            "phone": "310-653-2803",
            "building": "Bldg 270",
        },
        "res-los-angeles-mfrc": {
            "hours": "Mon-Fri 0800-1600; closed first Thu monthly for training",
        },
        "res-los-angeles-lodge": {
            "address": "2400 S Pacific Ave, Fort MacArthur, San Pedro, CA 90731",
            "phone": "310-653-8296",
        },
        "res-los-angeles-housing-referral": {
            "address": "2400 S Pacific Ave, Bldg 410, Fort MacArthur, San Pedro, CA 90731",
            "phone": "310-653-8468",
            "building": "Bldg 410",
            "hours": "Mon-Fri 0800-1600",
        },
        "res-los-angeles-dental": {
            "hours": "Mon/Tue/Thu/Fri 0800-1600; Wed 0900-1600",
        },
        "res-los-angeles-finance": {
            "hours": "Mon-Fri 0800-1600",
            "phone": "310-653-5114",
        },
        "res-los-angeles-mpf": {
            "hours": "Mon-Fri 0800-1500; closed first Thu monthly for training",
        },
        "res-los-angeles-cdc": {
            "hours": "Mon-Fri 0630-1730",
        },
        "res-los-angeles-school-liaison": {
            "hours": "Mon-Fri 0800-1600",
        },
        "res-los-angeles-odr": {
            "hours": "Mon-Fri 0800-1600",
        },
        "res-los-angeles-itt": {
            "hours": "Mon-Fri 0900-1600",
            "phone": "310-653-1304",
        },
        "res-los-angeles-community-center": {
            "hours": "Mon-Fri 1100-1400 lunch; Fri lounge 1700-2100; events vary",
        },
    },
    "jbmdl": {
        "res-jbmdl-dfac-mcguire": {
            "hours": "Mon-Fri: Bfast 0600-0830, Lunch 1030-1330, Dinner 1630-1900; Sat-Sun/Holidays: Bfast 0600-0830, Lunch 1030-1300, Dinner 1630-1800",
            "url": "https://gomdl.com/halvorsen-hall-dining-facility/",
        },
        "res-jbmdl-dfac-dix": {
            "name": "Dix Dining Facility",
            "hours": "Mon-Fri: Bfast 0600-0800, Lunch 1100-1300, Dinner 1630-1830; UTA weekends: Bfast 0700-0900, Lunch 1100-1300",
            "phone": "609-562-2095",
        },
        "res-jbmdl-bx": {
            "hours": "Mon-Sat 0900-2000; Sun 1000-1800",
            "address": "3452 Broidy Rd, Bldg 3452, JB MDL McGuire, NJ 08641",
            "phone": "609-723-6904",
            "url": "https://www.shopmyexchange.com/store-locator/mcguire-main-exchange",
            "building": "Bldg 3452",
        },
        "res-jbmdl-commissary": {
            "hours": "Sun 1000-1900; Mon-Sat 0900-2000",
            "address": "3453 Broidy Rd, Bldg 3453, JB MDL McGuire, NJ 08641",
            "phone": "609-754-2153",
            "url": "https://shop.commissaries.com/stores/mcguire-afb",
            "building": "Bldg 3453",
        },
        "res-jbmdl-andrews-cu": {
            "address": "3452 Broidy Rd, JB MDL McGuire, NJ 08641",
            "phone": "609-754-4030",
            "url": "https://www.andrewsfcu.org/",
        },
        "res-jbmdl-fort-dix-cu": {
            "address": "5200 Texas Ave, JB MDL Dix, NJ 08640",
            "phone": "609-562-0770",
            "url": "https://www.fortdixfcu.org/",
        },
        "res-jbmdl-lakehurst-cu": {
            "address": "620 Lansdowne Rd, JB MDL Lakehurst, NJ 08733",
            "phone": "732-323-5300",
            "url": "https://www.navyfederal.org/",
        },
        "res-jbmdl-fitness-mcguire": {
            "hours": "Mon-Fri 0600-1800; 24/7 CAC access after registration",
            "address": "2504 POW/MIA Blvd, Bldg 1706, JB MDL McGuire, NJ 08641",
            "phone": "609-754-6085",
            "url": "https://gomdl.com/fitness-center-mcguire/",
        },
        "res-jbmdl-fitness-dix": {
            "hours": "Mon-Fri 0500-1900; Sat-Sun 0600-1200; 24/7 CAC access after registration",
            "address": "Bldg 6053, 8th St & Millville Rd, JB MDL Dix, NJ 08640",
            "url": "https://gomdl.com/griffith-field-house/",
        },
        "res-jbmdl-fitness-lakehurst": {
            "hours": "Mon-Fri 0700-1900; Sat-Sun 0800-1200; 24/7 CAC access after registration",
            "url": "https://gomdl.com/fitness-center-lakehurst/",
        },
        "res-jbmdl-golf": {
            "name": "JB MDL Golf Course (McGuire)",
            "address": "McGuire Blvd, JB MDL McGuire, NJ 08641",
            "phone": "609-754-3195",
            "hours": "Seasonal; call pro shop for tee times",
            "url": "https://gomdl.com/",
        },
        "res-jbmdl-bowling": {
            "name": "Dix Bowling Center",
            "hours": "Mon-Thu 1100-2200; Fri-Sat 1100-0000; Sun 1200-1800",
            "address": "6054 Doughboy Loop, Bldg 6045, JB MDL Dix, NJ 08640",
            "phone": "609-562-6667",
            "url": "https://gomdl.com/",
            "building": "Bldg 6045",
        },
        "res-jbmdl-medical": {
            "address": "Bldg 1200, McGuire Blvd, JB MDL McGuire, NJ 08641",
            "hours": "Mon-Fri 0730-1630",
            "phone": "609-754-9000",
            "url": "https://jbmdl.tricare.mil/",
            "building": "Bldg 1200",
        },
        "res-87-fss": {
            "address": "Bldg 3435, Broidy Rd, JB MDL McGuire, NJ 08641",
            "phone": "609-754-3131",
            "url": "https://gomdl.com/",
            "building": "Bldg 3435",
        },
    },
    "shaw": {
        "res-shaw-dfac-williams": {
            "hours": "Mon-Fri: Bfast 0600-0800, Lunch 1100-1300, Dinner 1630-1900, Midnight 2300-0030; Sat-Sun: Bfast 0730-1230, Dinner 1630-1800, Midnight 2300-0030",
            "phone": "803-895-9791",
            "url": "https://shaw20fss.com/",
        },
        "res-shaw-commissary": {
            "hours": "Sun 1100-1800; Mon-Sat 0900-1900",
            "address": "510 Shaw Dr, Shaw AFB, SC 29152",
            "phone": "803-895-9900",
            "url": "https://shop.commissaries.com/stores/shaw-afb",
        },
        "res-shaw-fitness-main": {
            "hours": "Staffed Mon-Fri 0500-2100, Sat-Sun 0800-1800; 24/7 CAC access after registration",
            "address": "428 Shaw Dr, Shaw AFB, SC 29152",
            "phone": "803-895-2284",
            "url": "https://shaw20fss.com/",
        },
        "res-shaw-fitness-annex": {
            "hours": "Staffed Mon-Fri 0700-1400 (seasonal); 24/7 CAC access after registration",
            "address": "5 Lasano Rd, Shaw AFB, SC 29152",
            "phone": "803-895-0947",
            "url": "https://shaw20fss.com/shaw-fitness-health-center-annex/",
        },
        "res-shaw-bowling": {
            "hours": "Mon-Thu 1100-2200; Fri-Sat 1100-2300; Sun 1200-2000",
            "address": "416 Recreation St, Shaw AFB, SC 29152",
            "phone": "803-895-2732",
            "url": "https://shaw20fss.com/",
        },
        "res-20-fss": {
            "address": "510 Shaw Dr, Shaw AFB, SC 29152",
            "phone": "803-895-2017",
            "url": "https://shaw20fss.com/",
        },
        "res-shaw-outdoor-rec": {
            "hours": "Mon-Fri 0800-1630",
            "phone": "803-895-2017",
        },
    },
    "malmstrom": {
        "res-malmstrom-dfac-elkhorn": {
            "hours": "Mon-Fri: Bfast 0600-0900, Lunch 1100-1300, Dinner 1630-1830; Sat-Sun: Bfast 0730-0900, Lunch 1100-1300, Dinner 1630-1800",
            "phone": "406-731-2707",
            "url": "https://www.malmstrom.af.mil/",
        },
        "res-malmstrom-commissary": {
            "hours": "Sun 1000-1900; Mon 1100-1730 (self-checkout); Tue-Sat 0900-1900",
            "address": "7228 4th Ave N, Malmstrom AFB, MT 59402",
            "phone": "406-731-3432",
            "url": "https://shop.commissaries.com/stores/malmstrom-afb",
        },
        "res-malmstrom-fitness": {
            "hours": "Daily 0500-2200 staffed; 24/7 access after registration at front desk",
            "address": "7547 Goddard Dr, Bldg 1010, Malmstrom AFB, MT 59402",
            "phone": "406-731-2707",
            "url": "https://www.malmstrom.af.mil/",
            "building": "Bldg 1010",
        },
        "res-malmstrom-bowling": {
            "hours": "Mon-Thu 1100-2200; Fri-Sat 1100-0000; Sun 1200-1800",
            "phone": "406-731-2707",
        },
        "res-341-fss": {
            "phone": "406-731-2707",
            "url": "https://www.malmstrom.af.mil/",
        },
        "res-malmstrom-outdoor-rec": {
            "hours": "Mon-Fri 0800-1630",
            "phone": "406-731-2707",
        },
        "res-malmstrom-vcc": {
            "hours": "Daily 0600-2200",
            "phone": "406-731-2707",
        },
    },
    "minot": {
        "res-minot-dfac-dakota": {
            "hours": "Mon-Fri: Bfast 0600-0900, Lunch 1030-1330, Dinner 1630-1830; Sat-Sun: Bfast 0630-0830, Lunch 1030-1330, Dinner 1630-1830",
            "address": "213 Tanker Trail, Minot AFB, ND 58704",
            "phone": "701-723-2145",
            "url": "https://usafdining-minot.sodexomyway.com/en-us/the-dakota-inn",
        },
        "res-minot-fitness": {
            "hours": "Staffed Mon-Thu 0500-0000, Fri 0500-2100, Sat-Sun 0800-1800; 24/7 CAC access after registration",
            "address": "220 Tanker Trail, Minot AFB, ND 58705",
            "phone": "701-723-2145",
            "url": "https://5thforcesupport.com/mcadoo-fitness-center/",
        },
        "res-minot-bowling": {
            "name": "Rough Rider Bowling Center",
            "hours": "Mon-Thu 1100-2200; Fri-Sat 1100-0000; Sun 1200-1800",
            "phone": "701-723-2145",
            "url": "https://5thforcesupport.com/",
        },
        "res-5-fss": {
            "phone": "701-723-2145",
            "url": "https://5thforcesupport.com/",
        },
        "res-minot-outdoor-rec": {
            "hours": "Mon-Fri 0800-1630",
            "phone": "701-723-2145",
        },
    },
    "whiteman": {
        "res-whiteman-dfac-ozark": {
            "hours": "Mon-Fri: Bfast 0600-0900, Lunch 1100-1300, Dinner 1630-1900, Midnight 2300-0100; Sat-Sun: Bfast 0700-0900, Lunch 1100-1300, Dinner 1630-1800",
            "address": "323 Spirit Blvd, Whiteman AFB, MO 65305",
            "phone": "660-687-5677",
            "url": "https://whitemanforcesupport.com/",
        },
        "res-whiteman-commissary": {
            "hours": "Sun 1000-1800; Mon-Sat 0900-1900",
            "address": "750 Vandenberg Ave, Whiteman AFB, MO 65305",
            "phone": "660-687-5100",
            "url": "https://shop.commissaries.com/stores/whiteman-afb",
        },
        "res-whiteman-fitness": {
            "hours": "Mon-Thu 0500-2200; Fri 0500-2000; Sat-Sun 1000-1700; 24/7 access card after registration",
            "address": "777 Mitchell Ave, Bldg 2014, Whiteman AFB, MO 65305",
            "phone": "660-687-5495",
            "url": "https://whitemanforcesupport.com/fitness-center/",
            "building": "Bldg 2014",
        },
        "res-whiteman-bowling": {
            "name": "Stars & Strikes Bowling Center",
            "hours": "Mon-Thu 1100-2200; Fri-Sat 1100-0000; Sun 1200-1800",
            "address": "699 Mitchell Ave, Whiteman AFB, MO 65305",
            "phone": "660-687-5114",
            "url": "https://whitemanforcesupport.com/",
        },
        "res-509-fss": {
            "address": "511 Spirit Blvd, Whiteman AFB, MO 65305",
            "phone": "660-687-2752",
            "url": "https://whitemanforcesupport.com/",
        },
        "res-whiteman-outdoor-rec": {
            "hours": "Mon-Fri 0800-1630",
            "address": "725 2nd St, Bldg 110, Whiteman AFB, MO 65305",
            "phone": "660-687-5565",
        },
        "res-whiteman-vcc": {
            "hours": "Mon-Fri 0600-1800; closed weekends and federal holidays",
            "phone": "660-687-3226",
        },
    },
    "patrick": {
        "res-patrick-dfac-riverside": {
            "hours": "Daily: Bfast 0630-0900 (weekends 0630-0830), Lunch 1030-1330, Dinner 1630-1900 (weekends 1630-1830); Grab & Go between meals",
            "address": "Bldg 350, Patrick SFB, FL 32925",
            "phone": "321-494-4248",
            "url": "https://www.gopatrickfl.com/riverside-dining.html",
            "building": "Bldg 350",
        },
        "res-patrick-commissary": {
            "hours": "Sun 1000-1800; Mon-Sat 0900-1900",
            "address": "Bldg 950, Patrick SFB, FL 32925",
            "phone": "321-494-6500",
            "url": "https://shop.commissaries.com/stores/patrick-afb",
        },
        "res-patrick-fitness": {
            "hours": "Mon-Fri 0500-2000; Sat-Sun 0700-1600; 24/7 registered CAC access outside staffed hours",
            "phone": "321-494-4947",
            "url": "https://www.gopatrickfl.com/sports-and-fitness.html",
        },
        "res-patrick-bowling": {
            "name": "Shark Lanes Bowling Center",
            "hours": "Wed-Thu 1100-1400; Fri 1100-1400 and 1700-2100; Sat 1100-2200; Sun 1200-1800",
            "address": "832 O Malley Rd, Patrick SFB, FL 32925",
            "phone": "321-494-4947",
            "url": "https://www.gopatrickfl.com/",
        },
        "res-45-fss": {
            "phone": "321-494-7000",
            "url": "https://www.gopatrickfl.com/",
        },
        "res-patrick-outdoor-rec": {
            "hours": "Mon-Fri 0800-1630; boat rentals Wed-Sat 1030-1430",
            "phone": "321-494-7000",
        },
        "res-patrick-vcc": {
            "hours": "Mon-Fri 0700-1500; closed weekends and federal holidays",
            "phone": "321-494-4444",
        },
    },
    "mountain-home": {
        "res-mountain-home-dfac-wagonwheel": {
            "hours": "Mon-Fri: Bfast 0600-0900, Lunch 1100-1300, Dinner 1630-1900, Midnight 2300-0130; Sat-Sun: Bfast 0700-0900, Lunch 1130-1330, Dinner 1700-1900",
            "phone": "208-828-6420",
            "url": "https://mountainhomefss.com/",
        },
        "res-mountain-home-commissary": {
            "hours": "Sun 1000-1800; Mon-Sat 0900-1900",
            "address": "Mountain Home AFB, ID 83648",
            "phone": "208-828-2164",
            "url": "https://shop.commissaries.com/stores/mountain-home-afb",
        },
        "res-mountain-home-fitness": {
            "hours": "Manned Mon-Fri 0600-1800; 24/7 CAC access after registration at main desk",
            "address": "385 Aardvark Ave, Bldg 2371, Mountain Home AFB, ID 83648",
            "phone": "208-828-2381",
            "url": "https://mountainhomefss.com/fitness-sports-center/",
            "building": "Bldg 2371",
        },
        "res-mountain-home-bowling": {
            "name": "Strikers Bowling Center & Grill",
            "hours": "Mon-Thu 1100-2200; Fri-Sat 1100-0000; Sun 1200-1800",
            "phone": "208-828-6329",
            "url": "https://mountainhomefss.com/",
        },
        "res-366-fss": {
            "phone": "208-828-2381",
            "url": "https://mountainhomefss.com/",
        },
        "res-mountain-home-outdoor-rec": {
            "hours": "Mon-Fri 0800-1630",
            "phone": "208-828-2246",
        },
        "res-mountain-home-vcc": {
            "hours": "Mon-Fri 0700-1600; closed weekends and federal holidays",
            "phone": "208-828-6700",
        },
    },
    "offutt": {
        "res-offutt-fitness-fieldhouse": {
            "hours": "Mon-Fri 0500-2100; Sat-Sun 0700-1700; 24/7 CAC access after registration",
            "phone": "402-294-2200",
            "url": "https://www.offuttforcesupport.com/",
        },
        "res-offutt-bowling": {
            "hours": "Mon-Thu 1100-2200; Fri-Sat 1100-0000; Sun 1200-1800",
            "phone": "402-294-2200",
            "url": "https://www.offuttforcesupport.com/",
        },
        "res-55-fss": {
            "phone": "402-294-2200",
            "url": "https://www.offuttforcesupport.com/",
        },
        "res-offutt-outdoor-rec": {
            "hours": "Mon-Fri 0800-1630",
            "phone": "402-294-2200",
        },
    },
}

NEWCOMERS_PATCHES: dict[str, dict] = {
    "altus": {
        "primaryAction": {
            "title": "Visitor Control Center",
            "url": "https://www.altus.af.mil/About-Us/Visitor-Information/",
            "phone": "580-481-6340",
            "address": "428 Challenger Ave, Altus AFB, OK 73523",
        },
    },
    "ellsworth": {
        "primaryAction": {
            "title": "Visitor Control Center (Liberty Gate)",
            "url": "https://www.ellsworth.af.mil/Contact-Us/Visitor-Control-Center/",
            "phone": "605-385-2895",
            "address": "2740 Eaker Drive, Ellsworth AFB, SD 57706",
        },
    },
}

# Bases to enrich (priority first, then scan list)
PASS4_BASES = [
    "creech", "grissom", "altus", "ellsworth", "beale",
    "fe-warren", "charleston", "los-angeles", "jbmdl",
    # Batch 2 — remaining thin/generic bases
    "shaw", "malmstrom", "minot", "whiteman", "patrick",
    "mountain-home", "offutt", "los-angeles",  # los-angeles re-run for batch-2 hour patches
]


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

    if bid in NEWCOMERS_PATCHES:
        nc = data.setdefault("newcomers", {})
        pa = nc.setdefault("primaryAction", {})
        pa.update(NEWCOMERS_PATCHES[bid]["primaryAction"])
        changed.append("newcomers")

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


def scan_thin_bases() -> list[dict]:
    """Report remaining CONUS bases with thin/generic entries."""
    thin = []
    for path in sorted(BASE_DIR.glob("*.json")):
        bid = path.stem
        if bid in OCONUS or bid.startswith("_") or bid == "bases_index":
            continue
        with open(path) as f:
            data = json.load(f)
        resources = data.get("resources", [])
        generic = sum(
            1 for r in resources
            if any(x in str(r.get("hours", "")) for x in (
                "See FSS", "See posted", "Varies by", "duty hours",
                "See directory", "See commissary", "See lafss",
            ))
        )
        no_phone = sum(1 for r in resources if not r.get("phone"))
        gates = len(data.get("gates", []))
        if generic > 2 or gates < 3 or no_phone > 4:
            thin.append({
                "id": bid, "res": len(resources), "gates": gates,
                "generic": generic, "no_phone": no_phone,
            })
    return thin


def main() -> None:
    results = []
    for bid in PASS4_BASES:
        results.append(enrich_base(bid))

    print(f"Pass 4 enriched {len(results)} priority bases at {NOW}\n")
    for i, r in enumerate(results, 1):
        ch = ", ".join(r["changed"]) if r["changed"] else "timestamp only"
        print(f"  {i}. {r['id']:<22} res={r['resources']:2} gates={r['gates']:2}  [{ch}]")
        if i % 5 == 0:
            print(f"  --- Progress: {i}/{len(results)} priority bases complete ---\n")

    print("\n=== Remaining thin CONUS bases (generic hours > 2 or gates < 3) ===")
    for t in scan_thin_bases():
        print(f"  {t['id']:<22} res={t['res']:2} gates={t['gates']} generic={t['generic']} no_phone={t['no_phone']}")


if __name__ == "__main__":
    main()
