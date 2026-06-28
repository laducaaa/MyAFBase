#!/usr/bin/env python3
"""Generate full base JSON files from af_installations seed data."""

from __future__ import annotations

import importlib.util
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE_DIR = ROOT / "MyAFBase/MyAFBase/Resources/Bases"
DATA_PATH = Path(__file__).resolve().parent / "data/af_installations.py"
EXISTING_IDS = {"eglin", "hill", "lackland", "randolph", "langley", "keesler", "sheppard", "travis"}

SUPPLEMENTAL_LINKS = [
    {
        "id": "link-mos",
        "title": "Military OneSource",
        "url": "https://www.militaryonesource.mil/",
    },
    {
        "id": "link-mil-base-guide",
        "title": "Military.com Base Guide",
        "url": "https://www.military.com/base-guide/browse-by-service/air-force",
    },
    {
        "id": "link-base-directory",
        "title": "BaseDirectory.com",
        "url": "https://www.basedirectory.com/#air-force",
    },
]


def load_installations() -> list[dict]:
    spec = importlib.util.spec_from_file_location("af_installations", DATA_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module.INSTALLATIONS


def slugify_gate(name: str, index: int) -> str:
    cleaned = "".join(ch if ch.isalnum() else "-" for ch in name.lower())
    while "--" in cleaned:
        cleaned = cleaned.replace("--", "-")
    return f"gate-{cleaned.strip('-') or index}"


def resource(
    base_id: str,
    suffix: str,
    name: str,
    category: str,
    description: str,
    *,
    hours: str | None = "See facility website for current hours",
    address: str | None = None,
    phone: str | None = None,
    url: str | None = None,
    building: str | None = None,
) -> dict:
    item = {
        "id": f"res-{base_id}-{suffix}",
        "name": name,
        "category": category,
        "description": description,
        "hours": hours,
        "address": address,
        "phone": phone,
        "url": url,
        "building": building,
    }
    return item


def build_resources(inst: dict) -> list[dict]:
    bid = inst["id"]
    name = inst["name"]
    location = inst["location"]
    fss = inst.get("fssSite") or inst["officialSite"]
    default_address = f"{name}, {location}"
    resources: list[dict] = []

    dfac = inst.get("dfac")
    if dfac:
        resources.append(
            resource(
                bid,
                "dfac",
                dfac["name"],
                "dining",
                f"Main dining facility at {name}.",
                hours=dfac.get("hours"),
                address=dfac.get("address", default_address),
                phone=dfac.get("phone"),
                url=dfac.get("url", fss),
            )
        )
    else:
        resources.append(
            resource(
                bid,
                "dfac",
                "Main Dining Facility (DFAC)",
                "dining",
                f"Main dining facility serving {name}.",
                url=fss,
                address=default_address,
                phone=inst.get("baseOperatorPhone"),
            )
        )

    bx = inst.get("bx")
    if bx:
        resources.append(
            resource(
                bid,
                "bx",
                bx["name"],
                "shopping",
                f"Main Exchange at {name}.",
                hours=bx.get("hours"),
                address=bx.get("address", default_address),
                phone=bx.get("phone"),
                url=bx.get("url", "https://www.shopmyexchange.com/"),
            )
        )
    else:
        resources.append(
            resource(
                bid,
                "bx",
                f"{name} Exchange",
                "shopping",
                f"Army & Air Force Exchange main store.",
                url="https://www.shopmyexchange.com/",
                address=default_address,
            )
        )

    commissary = inst.get("commissary")
    if commissary:
        resources.append(
            resource(
                bid,
                "commissary",
                commissary["name"],
                "shopping",
                "Defense Commissary Agency grocery.",
                hours=commissary.get("hours"),
                address=commissary.get("address", default_address),
                phone=commissary.get("phone"),
                url=commissary.get("url", "https://shop.commissaries.com/"),
            )
        )
    else:
        resources.append(
            resource(
                bid,
                "commissary",
                f"{name} Commissary",
                "shopping",
                "Defense Commissary Agency grocery.",
                url="https://shop.commissaries.com/",
                address=default_address,
            )
        )

    medical = inst["medical"]
    resources.append(
        resource(
            bid,
            "medical",
            medical["name"],
            "medical",
            f"Primary medical facility for {name}. TRICARE appointments and emergency care.",
            hours="Appointments during duty hours; emergency care 24/7 where offered",
            address=default_address,
            phone=medical.get("phone"),
            url=medical.get("url"),
        )
    )

    fitness_items = inst.get("fitness") or [
        {"name": "Fitness Center", "phone": inst.get("baseOperatorPhone"), "url": fss}
    ]
    for index, fit in enumerate(fitness_items, start=1):
        resources.append(
            resource(
                bid,
                f"fitness-{index}",
                fit["name"],
                "fitness",
                f"Fitness and wellness facility at {name}.",
                hours=fit.get("hours", "See FSS for current hours"),
                address=fit.get("address", default_address),
                phone=fit.get("phone"),
                url=fit.get("url", fss),
            )
        )

    finance = inst.get("finance")
    resources.append(
        resource(
            bid,
            "finance",
            finance["name"] if finance else "Finance / Comptroller",
            "finance",
            "Military pay, travel vouchers, and finance customer service.",
            hours="Mon-Fri during duty hours",
            address=default_address,
            phone=(finance or {}).get("phone", inst.get("baseOperatorPhone")),
            url=(finance or {}).get("url", inst["officialSite"]),
        )
    )

    resources.append(
        resource(
            bid,
            "mpf",
            "Military Personnel Flight (MPF)",
            "services",
            "ID cards, DEERS, assignments, promotions, and personnel actions.",
            hours="Mon-Fri during duty hours; use RAPIDS for ID card appointments",
            address=default_address,
            phone=inst.get("baseOperatorPhone"),
            url=fss,
        )
    )

    resources.append(
        resource(
            bid,
            "fss",
            f"{inst['wing']} Force Support Squadron",
            "services",
            "MWR, dining, fitness, recreation, and family programs.",
            url=fss,
            address=default_address,
            phone=inst.get("baseOperatorPhone"),
        )
    )

    resources.append(
        resource(
            bid,
            "housing",
            "Housing Office",
            "housing",
            "On-base housing assignments and off-base housing referrals.",
            hours="Mon-Fri during duty hours",
            address=default_address,
            phone=inst.get("baseOperatorPhone"),
            url=inst.get("housingUrl", inst["officialSite"]),
        )
    )

    recreation_items = inst.get("recreation") or [
        {"name": "Outdoor Recreation", "url": fss, "phone": inst.get("baseOperatorPhone")}
    ]
    for index, rec in enumerate(recreation_items, start=1):
        resources.append(
            resource(
                bid,
                f"recreation-{index}",
                rec["name"],
                "recreation",
                f"Recreation and leisure programs at {name}.",
                hours=rec.get("hours", "See FSS for current hours"),
                address=rec.get("address", default_address),
                phone=rec.get("phone"),
                url=rec.get("url", fss),
            )
        )

    visitor = inst["visitorCenter"]
    resources.append(
        resource(
            bid,
            "visitor-center",
            visitor["title"],
            "safety",
            "Visitor passes, pass and registration, and base access information.",
            hours="See official visitor information for current hours",
            address=visitor.get("address", default_address),
            phone=visitor.get("phone"),
            url=inst.get("newcomersUrl", inst["officialSite"]),
        )
    )

    resources.append(
        resource(
            bid,
            "security-forces",
            "Security Forces / Base Defense",
            "safety",
            "Security Forces operations and law enforcement.",
            hours="24/7",
            address=default_address,
            phone=inst.get("securityPhone", inst.get("baseOperatorPhone")),
            url=inst["officialSite"],
        )
    )

    return resources


def build_gates(inst: dict) -> list[dict]:
    gates = []
    for index, gate in enumerate(inst.get("gates", []), start=1):
        gates.append(
            {
                "id": slugify_gate(gate["name"], index),
                "name": gate["name"],
                "status": gate.get("status", "open"),
                "hours": gate.get("hours", "See official gate hours"),
                "notes": gate.get("notes"),
                "traffic": gate.get("traffic", "moderate"),
                "address": gate.get("address"),
                "latitude": gate.get("latitude"),
                "longitude": gate.get("longitude"),
            }
        )
    return gates


def build_newcomers(inst: dict) -> dict:
    visitor = inst["visitorCenter"]
    official = inst["officialSite"]
    fss = inst.get("fssSite") or official
    mil_slug = inst["id"].replace("-", "-")
    base_guide_url = f"https://www.military.com/base-guide/{mil_slug}"

    links = [
        {"id": "link-official", "title": f"{inst['name']} Official Site", "url": official},
        {"id": "link-newcomers", "title": "Official Newcomers Page", "url": inst.get("newcomersUrl", official)},
        {"id": "link-fss", "title": "Force Support Squadron", "url": fss},
        {"id": "link-housing", "title": "Housing Information", "url": inst.get("housingUrl", official)},
        {"id": "link-mil-guide", "title": "Military.com Base Guide", "url": base_guide_url},
        *SUPPLEMENTAL_LINKS,
    ]

    return {
        "primaryAction": {
            "title": visitor["title"],
            "url": inst.get("newcomersUrl", official),
            "phone": visitor.get("phone"),
            "address": visitor.get("address"),
        },
        "moreInfoURL": inst.get("newcomersUrl", official),
        "sections": [
            {
                "id": "nc-1",
                "title": "Required Documents",
                "body": "Bring PCS orders, CAC, medical and dental records, and marriage or birth certificates if applicable. Carry finance and travel receipts for settlement.",
                "links": None,
            },
            {
                "id": "nc-2",
                "title": "In-Processing Schedule",
                "body": f"Report to your gaining unit upon arrival and visit the Military Personnel Flight within required timelines. Use the official newcomers page for {inst['name']} reporting instructions.",
                "links": [{"id": "link-inprocess", "title": "Newcomers & In-Processing", "url": inst.get("newcomersUrl", official)}],
            },
            {
                "id": "nc-3",
                "title": "Housing",
                "body": "Contact the Housing Office before arrival for on-base waitlists and off-base referrals. Temporary lodging is available through the base lodging office where offered.",
                "links": [{"id": "link-housing-sec", "title": "Housing Office", "url": inst.get("housingUrl", official)}],
            },
            {
                "id": "nc-4",
                "title": "Sponsor Program",
                "body": "Your sponsor should meet you upon arrival and assist with base orientation. Contact your gaining unit if no sponsor is assigned before departure.",
                "links": None,
            },
            {
                "id": "nc-5",
                "title": "Quick Resources",
                "body": f"Official installation resources plus Military OneSource, Military.com, and BaseDirectory for relocation support.",
                "links": links,
            },
        ],
    }


def build_events(inst: dict) -> list[dict]:
    bid = inst["id"]
    return [
        {
            "id": f"{bid}-evt-newcomers",
            "title": "Newcomers Briefing",
            "date": "2026-07-15T14:00:00Z",
            "endDate": "2026-07-15T16:00:00Z",
            "location": "Force Support Squadron",
            "address": f"{inst['name']}, {inst['location']}",
            "description": "Orientation for incoming personnel and families. Bring orders and ID cards.",
            "category": "community",
        },
        {
            "id": f"{bid}-evt-fss",
            "title": "Community Event",
            "date": "2026-08-22T16:00:00Z",
            "endDate": "2026-08-22T22:00:00Z",
            "location": "Force Support Squadron",
            "address": f"{inst['name']}, {inst['location']}",
            "description": "Check the FSS calendar for current community events, holiday activities, and family programs.",
            "category": "family",
        },
    ]


def build_base_json(inst: dict) -> dict:
    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    bid = inst["id"]
    return {
        "id": bid,
        "name": inst["name"],
        "fullName": inst["fullName"],
        "location": inst["location"],
        "description": inst["description"],
        "wing": inst["wing"],
        "latitude": inst["latitude"],
        "longitude": inst["longitude"],
        "dataUpdatedAt": now,
        "currentNotifications": [
            {
                "id": f"{bid}-notif-real-id",
                "title": "REAL ID Required for Base Access",
                "body": "A REAL ID-compliant driver's license or equivalent is required for base access per DHS mandate.",
                "type": "alert",
                "postedAt": now,
                "expiresAt": None,
            }
        ],
        "emergencyNumbers": [
            {
                "id": "em-1",
                "label": f"{inst['name']} Security Forces",
                "number": inst.get("securityPhone", inst.get("baseOperatorPhone", "911")),
            },
            {"id": "em-2", "label": "911 Emergency", "number": "911"},
            *(
                [{"id": "em-3", "label": "Base Operator", "number": inst["baseOperatorPhone"]}]
                if inst.get("baseOperatorPhone")
                else []
            ),
        ],
        "gates": build_gates(inst),
        "resources": build_resources(inst),
        "events": build_events(inst),
        "newcomers": build_newcomers(inst),
    }


def patch_existing_newcomers(base_id: str) -> None:
    path = BASE_DIR / f"{base_id}.json"
    if not path.exists():
        return
    with open(path) as f:
        data = json.load(f)

    newcomers = data.get("newcomers", {})
    sections = newcomers.get("sections", [])
    for section in sections:
        if section.get("id") != "nc-5":
            continue
        links = section.get("links") or []
        existing_urls = {link["url"] for link in links if link.get("url")}
        for supplemental in SUPPLEMENTAL_LINKS:
            if supplemental["url"] not in existing_urls:
                links.append(supplemental)
        mil_link = {
            "id": f"link-mil-{base_id}",
            "title": "Military.com Base Guide",
            "url": f"https://www.military.com/base-guide/{base_id}",
        }
        if mil_link["url"] not in existing_urls:
            links.append(mil_link)
        section["links"] = links
        section["body"] = (
            section.get("body", "")
            + " See Military OneSource, Military.com, and BaseDirectory for additional relocation resources."
        ).strip()

    newcomers["sections"] = sections
    data["newcomers"] = newcomers
    data["dataUpdatedAt"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


CONUS_STATES = {
    "AL", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "ID", "IL", "IN", "IA",
    "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV",
    "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD",
    "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY", "DC",
}


def infer_region(location: str) -> str:
    if ", " not in location:
        return "oconus"
    suffix = location.rsplit(", ", 1)[-1].strip()
    return "conus" if suffix in CONUS_STATES else "oconus"


def write_bases_index(all_ids: list[dict]) -> None:
    index = sorted(all_ids, key=lambda item: item["name"].lower())
    path = BASE_DIR / "bases_index.json"
    with open(path, "w") as f:
        json.dump(index, f, indent=2)
        f.write("\n")


def main() -> None:
    installations = load_installations()
    generated = 0

    for inst in installations:
        path = BASE_DIR / f"{inst['id']}.json"
        data = build_base_json(inst)
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        generated += 1
        print(f"Generated {inst['id']}.json ({len(data['resources'])} resources)")

    for base_id in sorted(EXISTING_IDS):
        patch_existing_newcomers(base_id)
        print(f"Patched newcomers links: {base_id}")

    index_entries = []
    for path in sorted(BASE_DIR.glob("*.json")):
        if path.name in {"bases_index.json", "_base_template.json"}:
            continue
        with open(path) as f:
            base = json.load(f)
        index_entries.append(
            {
                "id": base["id"],
                "name": base["name"],
                "location": base["location"],
                "wing": base["wing"],
                "region": infer_region(base["location"]),
            }
        )

    write_bases_index(index_entries)
    print(f"\nDone: generated {generated} new bases, index now has {len(index_entries)} installations")


if __name__ == "__main__":
    main()
