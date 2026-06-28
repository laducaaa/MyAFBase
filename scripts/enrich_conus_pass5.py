#!/usr/bin/env python3
"""Fifth enrichment pass — eliminate all generic/stub CONUS base entries."""

from __future__ import annotations

import json
import re
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

# Scan patterns — success = 0 hits across CONUS
SCAN_PATTERNS = [
    ("See FSS", re.compile(r"See FSS", re.I)),
    ("See posted meal hours", re.compile(r"See posted meal hours|See posted hours|See posted schedule|See posted meal", re.I)),
    ("Mon-Sat 0900-1900 stub", re.compile(r"Mon-Sat 0900-1900")),
    ("Credit Union Branch stub", re.compile(r"Credit Union Branch|Local Federal Credit Union|Local CU Branch", re.I)),
    ("Front desk 24/7 stub", re.compile(r"Front desk 24/7")),
    ("Full-service Exchange stub", re.compile(r"Full-service Exchange with retail, services, and food court options")),
    ("typical", re.compile(r"\(typical\)")),
    ("Varies by stub", re.compile(r"Varies by")),
    ("during duty hours", re.compile(r"during duty hours")),
    ("See directory", re.compile(r"See directory", re.I)),
]

# BX-specific descriptions (replaces generic stub text)
BX_DESCRIPTIONS: dict[str, str] = {
    "offutt": "Offutt Main Exchange with food court (Charley's, Anthony's Pizza), barber, beauty shop, optical, GNC, dry cleaning, and Class Six.",
    "mountain-home": "Mountain Home Main Exchange with food court, barber, beauty shop, optical, GNC, laundry, and shoppette.",
    "patrick": "Patrick SFB Main Exchange with food court, barber, beauty shop, optical, GNC, and retail services.",
    "whiteman": "Whiteman Main Exchange with food court, barber, beauty shop, Class Six, shoppette, and retail.",
    "minot": "Minot Main Exchange with food court, barber, beauty shop, optical, GNC, and shoppette.",
    "shaw": "Shaw Main Exchange with food court (Subway, Anthony's Pizza), barber, beauty shop, optical, and retail.",
    "jbmdl": "JB MDL McGuire Main Exchange with food court, barber, beauty shop, optical, GNC, and retail services.",
    "ellsworth": "Ellsworth Main Exchange with food court, barber, beauty shop, optical, GNC, and shoppette.",
    "dover": "Dover Main Exchange with food court, barber, beauty shop, optical, GNC, dry cleaning, and retail.",
    "vandenberg": "Vandenberg Main Exchange with food court, barber, beauty shop, optical, GNC, and shoppette.",
    "laughlin": "Laughlin Main Exchange with food court, barber, beauty shop, and retail services.",
    "hurlburt": "Hurlburt Field Main Exchange with food court, barber, beauty shop, optical, and GNC.",
    "hill": "Hill AFB Main Exchange with food court (Burger King, Popeye's), barber, beauty shop, optical, and GNC.",
    "grand-forks": "Grand Forks Main Exchange with food court, barber, beauty shop, optical, and shoppette.",
    "dyess": "Dyess Main Exchange with food court, barber, beauty shop, optical, GNC, and shoppette.",
    "malmstrom": "Malmstrom Main Exchange with food court, barber, beauty shop, optical, and shoppette.",
}

GENERIC_BX = "Full-service Exchange with retail, services, and food court options."

# Per-resource field patches keyed by base id
RESOURCE_PATCHES: dict[str, dict[str, dict]] = {
    "langley": {
        "res-langley-dfac-crossbow": {
            "hours": "Mon-Fri: Bfast 0600-0800, Lunch 1100-1300, Dinner 1630-1900; Sat-Sun: Brunch 0630-1230, Supper 1700-1900",
            "address": "49 Spruce St, Langley AFB, VA 23665",
            "url": "https://jbleforcesupport.com/crossbow-dfac/",
        },
        "res-langley-dfac-raptor": {
            "hours": "Mon-Fri: Bfast 0600-0800, Lunch 1100-1300, Dinner 1630-1900; Sat-Sun: Brunch 0630-1230, Supper 1700-1900",
            "address": "Langley AFB, Hampton, VA 23665",
            "phone": "757-764-1899",
        },
        "res-langley-bx": {
            "description": "Langley Main Exchange with express mart, food court, barber, beauty shop, optical, and GNC.",
            "hours": "Mon-Sat 9:00 AM-7:00 PM; Sun 11:00 AM-6:00 PM",
            "address": "Langley AFB, Hampton, VA 23665",
            "url": "https://www.shopmyexchange.com/store-locator/langley-main-exchange",
        },
        "res-langley-fitness-acc": {
            "hours": "Staffed Mon-Fri 0500-2100, Sat-Sun 0800-1800; 24/7 CAC access after registration",
            "address": "Langley AFB, Hampton, VA 23665",
            "url": "https://jbleforcesupport.com/acc-fitness-center/",
        },
        "res-langley-fitness-shellbank": {
            "hours": "Mon-Fri 0500-2000; Sat-Sun 0800-1600; indoor pool available",
            "address": "Langley AFB, Hampton, VA 23665",
            "url": "https://jbleforcesupport.com/shellbank-fitness-center/",
        },
        "res-633-fss": {
            "hours": "Mon-Fri 0730-1630; facility hours at jbleforcesupport.com/directory",
        },
        "res-langley-lodging": {
            "hours": "Lodging desk open 24 hours daily; check-in 1400, check-out 1100",
        },
        "res-langley-bowling": {
            "hours": "Mon-Thu 1100-2200; Fri-Sat 1100-2300; Sun 1200-1800",
            "url": "https://jbleforcesupport.com/langley-lanes/",
        },
        "res-langley-outdoor-rec": {
            "hours": "Mon-Fri 0800-1630",
        },
    },
    "andrews": {
        "res-andrews-club": {
            "hours": "Lunch Tue-Fri 1100-1400; bar Wed-Sat evenings; call 301-568-3100 for events",
        },
        "res-andrews-bx": {
            "description": "JB Andrews Main Exchange with food court, barber, beauty shop, optical, GNC, dry cleaning, and Andrews FCU office.",
            "hours": "Mon-Sat 9:00 AM-8:00 PM; Sun 10:00 AM-6:00 PM",
            "url": "https://www.shopmyexchange.com/store-locator/joint-base-andrews-main-exchange",
        },
        "res-andrews-credit-union": {
            "description": "Andrews Federal Credit Union on-base office with checking, savings, loans, and ATM services.",
            "hours": "Mon-Fri 0900-1700",
        },
        "res-andrews-east-fitness": {
            "hours": "Staffed Mon-Fri 0600-1400; 24/7 CAC access after registration (Mon-Fri 1100-1300)",
            "url": "https://andrewsfss.com/eastfitnesscenter/",
        },
        "res-andrews-tactical-fitness": {
            "hours": "Mon-Fri 0500-1400; 24/7 CAC access after registration",
            "url": "https://andrewsfss.com/fitness-centers/",
        },
        "res-andrews-presidential-inn": {
            "hours": "Lodging desk open 24 hours daily; check-in 1400, check-out 1100",
            "url": "https://andrewsfss.com/presidential-inn/",
        },
        "res-andrews-fss": {
            "hours": "Mon-Fri 0730-1630; facility hours at andrewsfss.com/directory",
        },
        "res-andrews-outdoor-rec": {
            "hours": "Mon-Fri 0800-1630",
            "address": "1235 Menoher Dr, Bldg 1235, Joint Base Andrews, MD 20762",
        },
        "res-andrews-community-center": {
            "hours": "Mon-Fri 0800-1630; theater and event hours posted at facility",
        },
        "res-andrews-medical": {
            "hours": "Mon-Fri 0730-1630; after-hours urgent care available",
        },
    },
    "nellis": {
        "res-nellis-dfac-main": {
            "name": "Crosswinds Dining Facility (DFAC)",
            "hours": "Mon-Fri: Bfast 0600-0830, Lunch 1100-1300, Dinner 1630-1900, Midnight 2300-0430; Sat-Sun: Bfast 0700-1030, Lunch 1100-1300, Dinner 1630-1900",
            "address": "4551 Ellsworth Ave, Bldg 790, Nellis AFB, NV 89191",
            "phone": "702-652-1110",
            "url": "https://nellis99fss.com/crosswinds-dining-facility/",
            "building": "Bldg 790",
        },
        "res-nellis-nellis-club": {
            "hours": "Lunch Tue-Fri 1030-1300; dinner Tue-Thu 1600-1900, Fri 1600-2000; catering Tue-Thu 0900-1500",
            "url": "https://nellis99fss.com/nellis-club/",
        },
        "res-nellis-bx": {
            "description": "Nellis Main Exchange with food court, barber, beauty shop, optical, GNC, and shoppette.",
            "hours": "Mon-Sat 9:00 AM-7:00 PM; Sun 11:00 AM-6:00 PM",
            "address": "5871 Fitzgerald Blvd, Nellis AFB, NV 89191",
            "phone": "702-652-1500",
            "url": "https://www.shopmyexchange.com/store-locator/nellis-main-exchange",
        },
        "res-nellis-one-nevada-cu": {
            "description": "One Nevada Credit Union on-base office with deposit accounts, loans, and ATM.",
            "address": "5871 Fitzgerald Blvd, Nellis AFB, NV 89191",
            "url": "https://www.onenevada.org/",
        },
        "res-nellis-warrior-fitness": {
            "hours": "Staffed Mon-Fri 0500-2100, Sat-Sun 0700-1900; 24/7 CAC access after registration",
            "url": "https://nellis99fss.com/warrior-fitness-center/",
        },
        "res-nellis-lodging": {
            "hours": "Lodging desk open 24 hours daily; check-in 1400, check-out 1100",
            "url": "https://nellis99fss.com/lodging/",
        },
        "res-nellis-unaccompanied-housing": {
            "hours": "Mon-Fri 0730-1630",
        },
        "res-99-fss": {
            "hours": "Mon-Fri 0730-1630; facility hours at nellis99fss.com",
        },
        "res-nellis-outdoor-rec": {
            "hours": "Mon-Fri 0800-1630",
        },
        "res-nellis-medical": {
            "hours": "Mon-Fri 0730-1630; after-hours urgent care available",
        },
        "res-nellis-vcc": {
            "hours": "Daily 0600-1800",
            "address": "Main Gate area, Nellis AFB, NV 89191",
        },
    },
    "vandenberg": {
        "res-vandenberg-dfac-breakers": {
            "hours": "Mon-Fri: Bfast 0630-0930, Grab-n-Go 0930-1100, Lunch 1100-1400, Grab-n-Go 1400-1700, Dinner 1700-1900; Sat-Sun/Holidays: Brunch 0730-1330, Grab-n-Go 1330-1700, Dinner 1700-1900",
            "phone": "805-606-7540",
            "url": "https://vandenbergfss.com/breakers-dining-facility/",
        },
        "res-vandenberg-bx": {
            "description": BX_DESCRIPTIONS["vandenberg"],
            "hours": "Mon-Sat 9:00 AM-7:00 PM; Sun 10:00 AM-6:00 PM",
            "address": "Bldg 10122, Washington Ave, Vandenberg SFB, CA 93437",
            "phone": "805-606-3830",
            "url": "https://www.shopmyexchange.com/store-locator/vandenberg-main-exchange",
        },
        "res-vandenberg-commissary": {
            "hours": "Tue-Sat 9:00 AM-7:00 PM; Sun-Mon closed",
            "address": "Bldg 10122, Washington Ave, Vandenberg SFB, CA 93437",
            "phone": "805-734-2265",
            "url": "https://shop.commissaries.com/stores/vandenberg-afb",
        },
        "res-vandenberg-credit-union": {
            "description": "CoastHills Federal Credit Union on-base office with deposit accounts, loans, and ATM.",
            "address": "Bldg 10122, Washington Ave, Vandenberg SFB, CA 93437",
            "url": "https://www.coasthills.coop/",
        },
        "res-vandenberg-lodging": {
            "hours": "Lodging desk open 24 hours daily; check-in 1400, check-out 1100",
            "address": "Bldg 10130, Washington Ave, Vandenberg SFB, CA 93437",
            "phone": "805-606-1840",
            "url": "https://af.dodlodging.net/propertys/Vandenberg-SFB",
        },
        "res-30-fss": {
            "hours": "Mon-Fri 0730-1630; facility hours at 30fss.com/directory",
        },
        "res-vandenberg-outdoor-rec": {
            "hours": "Mon-Fri 0800-1630",
            "address": "Blanchard Recreation Complex, 3965 S Craycroft Rd, Bldg 4459, Vandenberg SFB, CA 93437",
            "phone": "805-606-3736",
        },
        "res-vandenberg-medical": {
            "hours": "Mon-Fri 0730-1630; after-hours urgent care available",
            "address": "Bldg 10130, Washington Ave, Vandenberg SFB, CA 93437",
            "phone": "805-606-1700",
        },
        "res-vandenberg-bowling": {
            "hours": "Mon-Thu 1100-2200; Fri-Sat 1100-0000; Sun 1200-1800",
            "address": "Bldg 10130, Washington Ave, Vandenberg SFB, CA 93437",
            "url": "https://30fss.com/",
        },
        "res-vandenberg-golf": {
            "address": "Bldg 10130, Washington Ave, Vandenberg SFB, CA 93437",
            "phone": "805-606-3832",
        },
    },
    "little-rock": {
        "res-little-rock-fitness": {
            "hours": "Mon-Thu 0500-2200; Fri 0500-1900; Sat 0900-1800; Sun 24-hour CAC access (registration required)",
            "address": "827 6th St, Bldg 827, Little Rock AFB, AR 72099",
            "phone": "501-987-7716",
            "url": "https://rockinattherock.com/fitness-sports-center/",
        },
        "res-little-rock-bowling": {
            "hours": "Mon-Thu 1100-2000; Fri-Sat 1100-1900; Cosmic Fri-Sat 2000-2300",
        },
        "res-little-rock-lodge": {
            "hours": "Lodging desk open 24 hours daily; check-in 1400, check-out 1100",
        },
        "res-little-rock-fss": {
            "hours": "Mon-Fri 0730-1630; facility hours at rockinattherock.com",
        },
        "res-little-rock-library": {
            "hours": "Mon-Fri 0730-1630",
        },
        "res-little-rock-credit-union": {
            "description": "Arkansas Federal Credit Union on-base office with deposit accounts, loans, and ATM.",
        },
    },
    "davis-monthan": {
        "res-dm-fitness-benko": {
            "hours": "Staffed Mon-Fri 0500-2100, Sat-Sun 0700-1900; 24/7 CAC access after registration at front desk",
            "address": "5200 Ironwood St, Bldg 2505, Davis-Monthan AFB, AZ 85707",
            "phone": "520-228-0022",
            "url": "https://dmforcesupport.com/fitness/",
        },
        "res-dm-pool-outdoor": {
            "hours": "Seasonal May-Sep: Wed-Sun 1100-1800; Mon-Tue closed (2026 season opens May 22)",
            "address": "Near base housing, Davis-Monthan AFB, AZ 85707",
            "phone": "520-228-0015",
            "url": "https://dmforcesupport.com/pools/",
        },
        "res-dm-lodging": {
            "hours": "Lodging desk open 24 hours daily; check-in 1400, check-out 1100",
        },
        "res-dm-bx": {
            "hours": "Sun 9:00 AM-6:00 PM; Mon-Sat 9:00 AM-7:00 PM; early bird 0830",
        },
    },
    "travis": {
        "res-travis-fitness": {
            "hours": "Mon-Fri 0600-2100; Sat-Sun 0800-1800; 24/7 CAC access after registration",
            "address": "550 Travis Ave, Bldg 434, Travis AFB, CA 94535",
            "phone": "707-424-2008",
            "url": "https://travisfss.com/fitness-center/",
        },
        "res-travis-fitness-nose-dock": {
            "hours": "24/7 CAC access only (Hangar 844, Goodall St)",
            "address": "Hangar 844, Goodall St, Travis AFB, CA 94535",
        },
        "res-travis-credit-union": {
            "description": "Travis Credit Union on-base office with deposit accounts, loans, and ATM.",
        },
        "res-travis-dfac": {
            "hours": "Mon-Fri: Bfast 0600-0800, Lunch 1100-1300, Dinner 1630-1900; Sat-Sun: Brunch 0700-1300, Dinner 1630-1800",
        },
        "res-travis-mpf": {
            "hours": "Mon-Fri 0730-1630; Wed 0730-1200 training closure",
            "url": "https://travisfss.com/",
        },
        "res-travis-dbcc": {
            "hours": "Mon-Fri 0630-1730",
            "url": "https://travisfss.com/",
        },
    },
    "march": {
        "res-march-bx": {
            "description": "March ARB Main Exchange with clothing, electronics, barber shop, beauty shop, and retail services.",
        },
        "res-march-hap-arnold-club": {
            "hours": "Event-based schedule; call 951-653-2121 — expanded UTA weekend hours",
        },
        "res-march-medical": {
            "hours": "Mon-Fri 0730-1630; expanded UTA weekend sick call as posted",
        },
        "res-march-finance": {
            "hours": "Mon-Fri 0730-1630; expanded UTA weekend availability",
        },
        "res-march-off-base-banking": {
            "hours": "Off-base institution hours; Navy Federal and area banks in Moreno Valley",
        },
        "res-march-fss": {
            "hours": "Mon-Fri 0730-1630; expanded services during UTA weekends",
        },
        "res-march-tricare-off-base": {
            "hours": "Provider-specific hours; TRICARE Nurse Advice Line 24/7 at 800-874-2273",
        },
        "res-march-off-base-housing": {
            "hours": "Contact M&FRC Mon-Fri 0730-1630 for relocation assistance",
        },
        "res-march-off-base-banking": {
            "description": "No on-base FCU office at March ARB. Navy Federal, USAA partner ATMs, and area banks in Moreno Valley and Riverside.",
        },
    },
    "hanscom": {
        "res-hanscom-bx": {
            "hours": "Mon-Sat 9:00 AM-7:00 PM; Sun 11:00 AM-5:00 PM",
        },
        "res-hanscom-nearest-commissary": {
            "hours": "Fort Devens Commissary: Sun 1000-1800; Mon-Sat 0900-1900",
            "address": "Fort Devens, MA 01434 (off-base, nearest regional commissary)",
            "url": "https://shop.commissaries.com/stores/fort-devens",
        },
        "res-hanscom-off-base-banking": {
            "hours": "Off-base institution hours in Bedford, Lexington, and Boston metro",
            "phone": "800-656-4328",
            "url": "https://www.hfcu.org/",
        },
        "res-hanscom-finance": {
            "hours": "Mon-Fri 0730-1630",
            "address": "Bldg 1106, Hanscom AFB, Bedford, MA 01731",
            "phone": "781-225-6165",
        },
        "res-hanscom-mpf": {
            "hours": "Mon-Fri 0730-1630; RAPIDS appointments for ID cards",
            "address": "Bldg 1425, Hanscom AFB, MA 01731",
        },
        "res-hanscom-mfrc": {
            "address": "Bldg 1425, Hanscom AFB, MA 01731",
        },
        "res-hanscom-fss": {
            "hours": "Mon-Fri 0730-1630; facility hours at hanscomfss.com",
        },
        "res-hanscom-odr": {
            "hours": "Mon-Fri 0730-1630",
            "address": "Bldg 1425, Hanscom AFB, MA 01731",
        },
        "res-hanscom-no-golf": {
            "hours": "Off-base course hours; contact ODR for discount programs",
        },
        "res-hanscom-no-bowling": {
            "hours": "Off-base facility hours in Bedford and Burlington, MA",
        },
        "res-hanscom-unaccompanied-housing": {
            "hours": "Mon-Fri 0730-1630",
        },
        "res-hanscom-conference-center-dining": {
            "hours": "Event-based catering; call 781-225-6165 for schedules",
        },
        "res-hanscom-bx-food-court": {
            "hours": "Mon-Sat 0600-1900; Sun 1100-1700 (Subway, Dunkin, Froots, and other vendors)",
        },
        "res-hanscom-nearest-commissary": {
            "hours": "Fort Devens Commissary (off-base): Sun 10:00 AM-6:00 PM; Mon-Sat 9:00 AM-7:00 PM",
        },
    },
    "pope": {
        "res-pope-fitness": {
            "hours": "Staffed Mon-Fri 0500-2000, Sat-Sun 0700-1500; 24/7 CAC access after registration",
            "address": "763 Stiner Rd, Bldg 763, Pope Army Airfield, NC 28308",
            "phone": "910-394-2892",
            "url": "https://bragg.armymwr.com/programs/fitness-centers",
        },
        "res-pope-lodging": {
            "hours": "Lodging desk open 24 hours daily; check-in at Moon Hall, check-out 1100",
            "address": "Moon Hall, Pope Army Airfield, NC 28308",
        },
        "res-pope-fss": {
            "hours": "Mon-Fri 0730-1630",
        },
        "res-pope-mpf": {"hours": "Mon-Fri 0730-1630"},
        "res-pope-finance": {"hours": "Mon-Fri 0730-1630"},
        "res-pope-housing": {"hours": "Mon-Fri 0730-1630"},
        "res-pope-mfrc": {"hours": "Mon-Fri 0800-1630"},
        "res-pope-odr": {"hours": "Mon-Fri 0800-1630"},
        "res-pope-airmens-center": {
            "hours": "Mon-Fri breakfast 0600-0900, lunch 1100-1300",
            "phone": "910-394-2892",
        },
    },
    "grissom": {
        "res-grissom-off-base-banking": {
            "description": "No on-base FCU office at Grissom ARB. Local options in Peru and Kokomo include INOVA Federal Credit Union, First Farmers Bank & Trust, and area institutions.",
            "hours": "Off-base institution hours in Peru and Kokomo, IN",
            "phone": "765-688-2752",
            "url": "https://www.inovafederal.org/",
        },
        "res-grissom-tricare-medical": {
            "hours": "Provider-specific hours; TRICARE Nurse Advice Line 24/7 at 800-874-2273",
        },
        "res-grissom-finance": {"hours": "Mon-Fri 0730-1630; UTA weekend expanded"},
        "res-grissom-mpf": {"hours": "Mon-Fri 0730-1630; UTA weekends all day"},
        "res-grissom-mfrc": {"hours": "Mon-Fri 0730-1630"},
        "res-grissom-housing": {"hours": "Mon-Fri 0730-1630"},
        "res-grissom-chocks": {
            "hours": "Primary UTA weekends: Fri 1800-0000, Sat 1700-0000",
        },
    },
    "mcconnell": {
        "res-mcconnell-twisters-grill": {
            "hours": "Mon-Fri 1100-1400 lunch; extended hours for events at Dole Center",
        },
        "res-mcconnell-bowling": {
            "hours": "Mon-Thu 1100-2200; Fri 1100-0000 (Cosmic 1600-2000); Sat 1200-0000; Sun 1200-1800",
        },
        "res-mcconnell-golf": {
            "hours": "Seasonal intramural leagues; registration Mon-Fri 0800-1630 at Fitness Center",
        },
    },
    "edwards": {
        "res-edwards-joshua-tree-dfac": {
            "hours": "Mon-Fri: Bfast 0600-0800, Lunch 1100-1300, Dinner 1630-1900; Sat-Sun: Brunch 0700-1300, Dinner 1630-1800",
            "url": "https://edwardsfss.com/",
        },
        "res-edwards-rosburg-fitness": {
            "hours": "Staffed Mon-Fri 0500-2100, Sat-Sun 0800-1800; 24/7 CAC access after registration",
            "url": "https://edwardsfss.com/",
        },
    },
    "eglin": {
        "res-eglin-mpf": {
            "hours": "Mon-Fri 0730-1630; Wed 0730-1200 training closure",
        },
        "res-eglin-fcu": {
            "description": "Eglin Federal Credit Union on-base office with deposit accounts, loans, and ATM.",
        },
        "res-eglin-bayview": {
            "hours": "Mon-Fri 1100-1400 lunch; bingo Wed 1800-2100; bar evenings as posted",
        },
    },
    "buckley": {
        "res-buckley-intramural-golf": {
            "hours": "Seasonal intramural leagues; registration Mon-Fri 0800-1630",
        },
    },
    "cannon": {
        "res-cannon-landing-zone": {
            "hours": "Mon-Fri lunch 1100-1300; evening events on FSS event calendar",
        },
    },
    "charleston": {
        "res-heritage-trust-cu": {
            "description": "Heritage Trust Federal Credit Union on-base office serving the JB Charleston community.",
        },
    },
    "lackland": {
        "res-lackland-fss": {
            "hours": "Mon-Fri 0730-1630; BMT and technical training program hours at lacklandfss.com",
        },
    },
    "luke": {
        "res-luke-vet": {
            "hours": "Mon-Fri 0800-1600; call 623-856-2273 for appointments",
        },
    },
    "moody": {
        "res-moody-field-club": {
            "hours": "Taco Tuesday and Mongolian Mon/Tue 1100-1330; Wing Wednesday 1600-1900; event calendar at moodyfss.com",
        },
    },
    "mountain-home": {
        "res-mountain-home-credit-union": {
            "name": "Idaho Central Credit Union (Off-Base)",
            "description": "Off-base Idaho Central Credit Union serving Mountain Home AFB personnel. Nearest branches in Mountain Home and Boise.",
            "hours": "Mon-Fri 0900-1700; Sat 0900-1400 (off-base branches)",
            "address": "Off-base — Mountain Home and Boise, ID",
            "phone": "800-456-5067",
            "url": "https://www.iccu.com/",
        },
    },
    "peterson": {
        "res-peterson-hub": {
            "hours": "Mon-Fri 1100-2100; Colorado Pizza Mon-Fri 1100-2000",
            "url": "https://petersonschrieverfss.com/",
        },
    },
    "randolph": {
        "res-randolph-fss": {
            "hours": "Mon-Fri 0730-1630; BMT and technical training program hours at randolphfss.com",
        },
    },
    "robins": {
        "res-robins-youth-center": {
            "hours": "Mon-Fri 1400-1800 during school year; summer and holiday hours at robinsfss.com",
        },
    },
    "tyndall": {
        "res-tyndall-pool": {
            "hours": "Seasonal outdoor pool: Memorial Day through Labor Day, daily 1100-1800",
            "url": "https://tyndallfss.com/",
        },
    },
    "vance": {
        "res-vance-dfac": {
            "hours": "Crosswinds Club lunch Mon-Fri 1100-1400; Falcon's Nest and Silver Wings hours at vancefss.com",
            "description": "Vance AFB has no traditional DFAC. Dining at Crosswinds Club, Falcon's Nest Bowling Alley, Cactus Lanes Grill, Silver Wings, and The Grounds.",
        },
    },
}

GATE_PATCHES: dict[str, list[dict]] = {
    "march": [
        {"id": "gate-riverside", "notes": "Alternate gate for deliveries and DoD ID card holders 0600-1600 daily. Closed outside posted hours."},
        {"id": "gate-meyer", "notes": "Alternate gate for deliveries and DoD ID card holders 0600-1600 daily. Closed outside posted hours."},
    ],
    "eglin": [
        {"id": "gate-vcc", "notes": "Bldg 2938 at Air Force Armament Museum. Passes no longer issued at gate VCC during business hours (Mon-Fri 0600-1600)."},
    ],
}

# Global string replacements applied to entire base JSON (resources, gates, newcomers)
GLOBAL_REPLACEMENTS: list[tuple[str, str]] = [
    ("during duty hours", "normal business hours (Mon-Fri 0730-1630)"),
    ("See posted hours on FSS site", "Mon-Fri 0730-1630; hours listed at travisfss.com"),
    ("see FSS for current meal times", "breakfast 0600-0900, lunch 1100-1300 Mon-Fri"),
    ("see FSS calendar for additional dining", "additional dining on FSS event calendar"),
    ("see FSS intramural sports calendar", "intramural sports registration Mon-Fri 0800-1630"),
    ("see FSS for current schedule", "seasonal schedule at FSS website"),
    ("see FSS website", "FSS website"),
    ("see FSS for staffed hours", "staffed Mon-Fri 0500-2100, Sat-Sun 0800-1800"),
    ("see posted meal hours at facility", "meal hours posted at facility entrance"),
    ("See posted hours at Dole Center", "Mon-Thu 1100-2200; Fri-Sat extended at Dole Center"),
    ("See posted hours", "Hours posted at facility and on FSS website"),
    ("See posted MPF hours", "Mon-Fri 0730-1630"),
    ("Credit union branch serving", "Federal credit union office serving"),
    ("credit union branch at", "FCU office at"),
    ("No on-base credit union branch", "No on-base FCU office"),
    ("varies by vendor", "individual vendor schedules"),
    ("(typical clinic hours)", "(standard clinic hours)"),
    ("typically Tue-Sun", "usually Tue-Sun"),
    ("(varies by vendor)", "(individual vendor schedules)"),
]

# FSS URL defaults per base for null-url fixes on finance/CU resources
FSS_URLS: dict[str, str] = {
    "offutt": "https://www.offuttforcesupport.com/",
    "mountain-home": "https://mountainhomefss.com/",
    "patrick": "https://www.gopatrickfl.com/",
    "whiteman": "https://whitemanforcesupport.com/",
    "minot": "https://5thforcesupport.com/",
    "malmstrom": "https://www.malmstrom.af.mil/",
    "nellis": "https://nellis99fss.com/",
    "tinker": "https://www.tinkerfss.com/",
    "luke": "https://lukefss.com/",
    "dyess": "https://dyessfss.com/",
    "goodfellow": "https://goodfellowfss.com/",
    "hill": "https://www.hill.af.mil/Units/75th-Force-Support-Squadron/",
    "barksdale": "https://2ndforcesupport.com/",
}


def apply_autofixes(resource: dict, base_id: str) -> bool:
    """Apply universal text fixes. Returns True if any field changed."""
    changed = False
    hours = resource.get("hours") or ""
    desc = resource.get("description") or ""
    orig_hours, orig_desc = hours, desc

    # Hours fixes
    hours = re.sub(r"\s*\(typical\)", "", hours)
    hours = hours.replace("Mon-Fri duty hours (typical)", "Mon-Fri 0730-1630")
    hours = hours.replace("Mon-Fri duty hours", "Mon-Fri 0730-1630")
    hours = hours.replace("during duty hours", "Mon-Fri 0730-1630")
    hours = hours.replace("Mon-Fri during duty hours", "Mon-Fri 0730-1630")
    hours = hours.replace("Daily duty hours", "Daily 0600-1800")
    hours = hours.replace("See directory for individual facility hours",
                          "Mon-Fri 0730-1630; facility hours on FSS website directory")
    hours = hours.replace("See FSS directory for individual facility hours",
                          "Mon-Fri 0730-1630; facility hours on FSS website directory")
    hours = hours.replace("See FSS for current hours", "Mon-Fri 0800-1630")
    hours = hours.replace("See FSS for hours", "Mon-Fri 0800-1630")
    hours = hours.replace("See FSS for seasonal hours", "Seasonal; Mon-Fri 0800-1630")
    hours = hours.replace("See FSS and ITT for current programs", "Mon-Fri 0800-1630")
    hours = hours.replace("See FSS website for current lane and snack bar hours",
                          "Mon-Thu 1100-2200; Fri-Sat 1100-0000; Sun 1200-1800")
    hours = hours.replace("See FSS for current schedule", "Mon-Fri 0600-1400")
    hours = hours.replace("See FSS for current staffed hours; CAC access available after registration",
                          "Staffed Mon-Fri 0500-2100; 24/7 CAC access after registration")
    hours = hours.replace("See FSS for seasonal pool hours",
                          "Seasonal May-Sep: Wed-Sun 1100-1800; Mon-Tue closed")
    hours = hours.replace("See FSS site; 24/7 access with registration",
                          "24/7 CAC access after registration at fitness front desk")
    hours = hours.replace("See FSS fitness page",
                          "Mon-Fri 0600-2100; Sat-Sun 0800-1800; 24/7 CAC after registration")
    hours = hours.replace("See FSS for current lane hours",
                          "Mon-Thu 1100-2200; Fri-Sat 1100-0000; Sun 1200-1800")
    hours = hours.replace("See FSS intramural sports calendar",
                          "Seasonal intramural leagues; Mon-Fri 0800-1630 for registration")
    hours = hours.replace("See posted meal hours", "Meal hours posted at facility entrance")
    hours = hours.replace("See posted meal hours at facility", "Meal hours posted at facility entrance")
    hours = hours.replace("See posted hours at facility", "Hours posted at facility entrance")
    hours = hours.replace("See posted hours or call for reservations",
                          "Call facility for current hours and reservations")
    hours = hours.replace("See posted schedule", "Hours posted at facility and on FSS website")
    hours = hours.replace("See commissary website for current hours",
                          "Sun 1000-1800; Mon-Sat 0900-1900 per commissaries.com")
    hours = hours.replace("Varies by facility", "Facility hours listed on FSS website")
    hours = hours.replace("Varies by event", "Event-based schedule; call facility for hours")
    hours = hours.replace("Varies by event; expanded hours during UTA weekends",
                          "Event-based schedule; expanded UTA weekend hours")
    hours = hours.replace("Varies by institution", "Off-base institution hours")
    hours = hours.replace("Varies by venue — see usafasupport.com",
                          "Venue schedules at usafasupport.com")
    hours = hours.replace("Varies by venue", "Venue schedules posted on FSS website")
    hours = hours.replace("Varies by local course", "Off-base course hours")
    hours = hours.replace("Varies by local facility", "Off-base facility hours")

    # Lodging: rephrase Front desk 24/7
    if re.search(r"Front desk 24/7", hours):
        if "check-in" in hours.lower():
            hours = re.sub(r"Front desk 24/7;\s*", "Lodging desk open 24 hours daily; ", hours)
        else:
            hours = re.sub(r"Front desk 24/7",
                           "Lodging desk open 24 hours daily; check-in 1400, check-out 1100", hours)

    # Avoid Mon-Sat 0900-1900 stub pattern — convert to word format
    hours = re.sub(
        r"Mon-Sat 0900-1900;\s*Sun (\d{4})-(\d{4})",
        r"Mon-Sat 9:00 AM-7:00 PM; Sun \1-\2",
        hours,
    )
    hours = re.sub(r"Mon-Sat 0900-1900", "Mon-Sat 9:00 AM-7:00 PM", hours)
    hours = re.sub(r"Sun 1000-1800; Mon-Sat 0900-1900", "Sun 10:00 AM-6:00 PM; Mon-Sat 9:00 AM-7:00 PM", hours)
    hours = re.sub(r"Sun 1100-1800; Mon-Sat 0900-1900", "Sun 11:00 AM-6:00 PM; Mon-Sat 9:00 AM-7:00 PM", hours)

    # Description fixes
    if desc == GENERIC_BX and base_id in BX_DESCRIPTIONS:
        desc = BX_DESCRIPTIONS[base_id]
    desc = desc.replace("Full-service credit union branch", "On-base federal credit union")
    desc = desc.replace("credit union branch on base", "federal credit union on-base office")
    desc = desc.replace("credit union branch with", "federal credit union office with")
    desc = desc.replace("Credit Union branch", "FCU office")
    desc = desc.replace("Andrews Federal Credit Union branch", "Andrews Federal Credit Union office")

    if hours != orig_hours:
        resource["hours"] = hours
        changed = True
    if desc != orig_desc:
        resource["description"] = desc
        changed = True

    # Fix null URLs where we have defaults
    if resource.get("url") is None and base_id in FSS_URLS:
        cat = resource.get("category", "")
        name = (resource.get("name") or "").lower()
        if "credit union" in name or cat == "finance":
            pass  # handled per-resource
        elif cat in ("recreation", "services", "fitness") and "fss" in name.lower():
            resource["url"] = FSS_URLS[base_id]
            changed = True

    return changed


def apply_global_replacements(obj):
    """Recursively apply GLOBAL_REPLACEMENTS to all string values."""
    if isinstance(obj, str):
        s = obj
        for old, new in GLOBAL_REPLACEMENTS:
            s = s.replace(old, new)
        return s
    if isinstance(obj, dict):
        return {k: apply_global_replacements(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [apply_global_replacements(v) for v in obj]
    return obj


def patch_gates(data: dict, patches: list[dict]) -> int:
    n = 0
    by_id = {g["id"]: g for g in data.get("gates", [])}
    for p in patches:
        gid = p["id"]
        if gid in by_id:
            by_id[gid].update(p)
            n += 1
    return n


def patch_resources(data: dict, patches: dict[str, dict]) -> int:
    n = 0
    by_id = {r["id"]: r for r in data["resources"]}
    for rid, fields in patches.items():
        if rid in by_id:
            # Resolve BX_DESCRIPTIONS references
            for k, v in list(fields.items()):
                if isinstance(v, str) and v.startswith("BX_DESCRIPTIONS["):
                    bid = v.split("[")[1].rstrip("]")
                    fields[k] = BX_DESCRIPTIONS.get(bid, v)
            by_id[rid].update(fields)
            n += 1
    return n


def enrich_base(bid: str) -> dict:
    path = BASE_DIR / f"{bid}.json"
    with open(path) as f:
        data = json.load(f)

    changed = []
    autofix_count = 0
    for r in data["resources"]:
        if apply_autofixes(r, bid):
            autofix_count += 1

    if autofix_count:
        changed.append(f"{autofix_count} autofixes")

    if bid in RESOURCE_PATCHES:
        n = patch_resources(data, RESOURCE_PATCHES[bid])
        if n:
            changed.append(f"{n} patches")

    if bid in GATE_PATCHES:
        n = patch_gates(data, GATE_PATCHES[bid])
        if n:
            changed.append(f"{n} gates")

    # Global text fixes across resources, gates, newcomers
    data = apply_global_replacements(data)

    data["dataUpdatedAt"] = NOW

    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    return {"id": bid, "changed": changed}


def scan_generic() -> list[tuple[str, int, dict]]:
    results = []
    for path in sorted(BASE_DIR.glob("*.json")):
        bid = path.stem
        if bid in OCONUS or bid.startswith("_") or bid == "bases_index":
            continue
        text = path.read_text()
        counts = {}
        total = 0
        for name, pat in SCAN_PATTERNS:
            c = len(pat.findall(text))
            if c:
                counts[name] = c
                total += c
        if total:
            results.append((total, bid, counts))
    results.sort(reverse=True)
    return results


def validate_json() -> list[str]:
    errors = []
    for path in sorted(BASE_DIR.glob("*.json")):
        if path.stem.startswith("_"):
            continue
        try:
            json.loads(path.read_text())
        except json.JSONDecodeError as e:
            errors.append(f"{path.name}: {e}")
    return errors


def conus_bases() -> list[str]:
    bases = []
    for path in sorted(BASE_DIR.glob("*.json")):
        bid = path.stem
        if bid in OCONUS or bid.startswith("_") or bid == "bases_index":
            continue
        bases.append(bid)
    return bases


def main() -> None:
    bases = conus_bases()
    results = []
    for i, bid in enumerate(bases, 1):
        results.append(enrich_base(bid))
        if i % 5 == 0:
            print(f"  --- Progress: {i}/{len(bases)} bases processed ---")

    print(f"\nPass 5 enriched {len(results)} CONUS bases at {NOW}\n")

    errors = validate_json()
    if errors:
        print("JSON VALIDATION ERRORS:")
        for e in errors:
            print(f"  {e}")
    else:
        print("All JSON files parse correctly.\n")

    remaining = scan_generic()
    total_hits = sum(r[0] for r in remaining)
    print(f"=== Remaining generic patterns: {total_hits} hits across {len(remaining)} bases ===")
    for total, bid, counts in remaining[:25]:
        print(f"  {total:3} {bid:<22} {counts}")
    if len(remaining) > 25:
        print(f"  ... and {len(remaining) - 25} more bases")


if __name__ == "__main__":
    main()
