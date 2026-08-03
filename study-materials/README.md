# MyPromotion PFE Study Materials

## Purpose and status

This directory contains original study content for Airmen preparing for the Promotion Fitness Examination (PFE) for promotion to Staff Sergeant (E-5) and Technical Sergeant (E-6).

The current material is a **provisional 27E5/27E6 foundation** derived from the public 15 February 2025 edition of *Air Force Handbook 1, Airman*. It must not be advertised as final 2027-cycle content until the Air Force publishes the applicable 27E5 and 27E6 WAPS Catalogs and MyPromotion completes a documented source comparison.

No material in this directory is:

- an official Department of the Air Force product;
- affiliated with, endorsed by, or approved by the Department of Defense or Department of the Air Force;
- copied from PDG PROmote, AFH 1 GOLD/PDG GOLD, or another commercial study product;
- based on recalled, disclosed, or otherwise compromised test questions; or
- a substitute for the official WAPS Catalog, AFH 1, or current operational guidance.

## Scope

The planned product covers only the common PFE material:

1. AFH 1 knowledge content identified by the Airman Development and Testing Chart (ADTC).
2. Original preparation for the Situational Judgment Test (SJT) portion of the PFE.
3. Separate SSgt and TSgt learning paths based on their respective ADTC comprehension levels.

It excludes all AFSC-specific Specialty Knowledge Test material.

## Source of truth

Content must be checked against sources in this order:

1. The WAPS Catalog for the exact promotion grade and cycle.
2. The AFH 1 edition and revision named in that catalog.
3. The ADTC embedded in that AFH 1 edition.
4. Official SJT instructions and public sample-item guidance.
5. Other official publications only when they clarify a concept already contained in the cycle-controlled AFH 1.

Current baseline:

- **Handbook:** AFH 1, *Airman*, 15 February 2025
- **26E5 reference record:** AFPT 00035, revision 76
- **26E6 reference record:** AFPT 00036, revision 76
- **2027 status:** Catalogs not yet incorporated; all content remains provisional

Operational policy can change after a WAPS source edition is frozen. Study explanations must clearly distinguish the cycle-controlled exam source from current duty guidance. Airmen must follow current policy when performing official duties.

## Content model

Each learning item should carry enough metadata to support both rank-specific study and later app import.

| Field | Meaning |
|---|---|
| `content_id` | Stable MyPromotion identifier |
| `source_edition` | Controlling AFH 1 date |
| `source_paragraphs` | Exact AFH paragraph number or range |
| `chapter` / `section` | AFH chapter and ADTC section |
| `rank_tags` | `SSgt`, `TSgt`, or both |
| `adtc_level` | A Remembering, B Understanding, C Applying, or D Analyzing |
| `content_type` | Lesson, summary, flashcard, knowledge item, or SJT scenario |
| `difficulty` | Foundational, standard, or challenge |
| `status` | Draft, citation-verified, human-reviewed, or cycle-validated |
| `revalidation_note` | Change or uncertainty requiring review |

## Required lesson components

Every testable section should eventually include:

- rank-specific learning objectives;
- an original explanation of every testable concept;
- important relationships and distinctions;
- examples that do not purport to be actual test situations;
- common misconceptions;
- memory aids where they improve understanding;
- a concise section summary;
- source citations at the paragraph level;
- flashcards;
- multiple-choice practice with four plausible options;
- a rationale for the correct response and each distractor; and
- revalidation flags for time-sensitive facts or policies.

## Assessment standards

Knowledge questions must:

- measure the section's assigned ADTC level;
- have one defensible best answer;
- use plausible, source-grounded distractors;
- avoid trivia outside the controlling source;
- avoid negative wording unless the objective requires it;
- avoid “all of the above” and “none of the above”;
- avoid grammatical or length cues;
- explain why every option is correct or incorrect;
- cite the exact source paragraph; and
- never claim to reproduce the style, wording, distribution, or content of an operational WAPS test.

SJT scenarios must:

- be wholly original;
- use four credible response options;
- ask separately for the most and least effective response;
- evaluate behavior rather than obscure policy recall;
- explain the tradeoffs among all four responses;
- align with public Air Force foundational competencies, leadership qualities, core values, and professional standards; and
- state that the scoring rationale is educational judgment, not an official WAPS scoring key.

## Quality gates

Content is not ready for sale merely because it has been generated.

1. **Citation verification:** Every factual assertion and answer is checked against the cited source.
2. **Internal consistency:** Terminology, ranks, dates, lists, and cross-references agree across lessons and assessments.
3. **Item-quality review:** Questions are checked for ambiguity, duplication, cueing, and unsupported distractors.
4. **Human review:** A qualified reviewer checks educational clarity and Air Force context without using or soliciting controlled test information.
5. **Cycle validation:** The released 27E5 and 27E6 catalogs and named AFH edition are compared against this baseline.
6. **Legal and ethics clearance:** MyPromotion completes appropriate intellectual-property, trademark, test-security, and RegAF off-duty-employment review before commercial release.

## Individual-study safeguards

AFH 1 states that WAPS preparation is an individual responsibility, prohibits group study for promotion-testing purposes, and prohibits Airmen from sharing personal or commercial study materials with other individuals. MyPromotion should therefore:

- license access to one individual user;
- prohibit account and content sharing;
- disable public or collaborative WAPS decks and notes;
- reject any submission described as an actual or recalled test item;
- avoid unit, classroom, or group-study modes for PFE preparation;
- keep commercial content and personal notes off government computers; and
- display clear test-security and individual-use notices.

## Non-affiliation language

Recommended working disclaimer pending legal review:

> MyPromotion is an independent educational product. It is not affiliated with, endorsed by, sponsored by, or approved by the United States Air Force, the Department of the Air Force, the Department of Defense, or any other government agency. Official study requirements are published by the Department of the Air Force at studyguides.af.mil.

