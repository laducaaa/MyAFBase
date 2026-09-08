# MyPromotion PFE Study Materials

## Purpose and status

This directory contains original study content for Airmen preparing for the Promotion Fitness Examination (PFE) for promotion to Staff Sergeant (E-5) and Technical Sergeant (E-6).

The current material is a **provisional 27E5/27E6 foundation** derived from the public 15 February 2025 edition of *Air Force Handbook 1, Airman*. As of 3 August 2026, no official 27E5 or 27E6 WAPS Catalog is published on studyguides.af.mil. This material is not validated for either cycle and must not be advertised as final 2027 content until MyPromotion completes a documented comparison with both catalogs.

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
4. Official SJT instructions and public sample-item guidance, treated as informational until the cycle format is confirmed.
5. AFH 36-2647 as the public competency framework referenced by the SJT guide, not as a cycle-controlled PFE source unless the applicable catalog says otherwise.
6. Other official publications only when they clarify a concept already contained in the cycle-controlled AFH 1.

Current baseline:

- **Handbook:** AFH 1, *Airman*, 15 February 2025
- **26E5 historical record:** AFPT 00035, 1 April 2026, revision 76; Chapters 1, 5, 7–9, 11–12, 14–15, 17–20, 22, and 24
- **26E6 historical record:** AFPT 00036, 1 February 2026, revision 76; Chapters 1, 5, 7–9, 11–20, 22, and 24
- **2027 status as of 3 August 2026:** no catalogs published; all scope and format remain provisional

Operational policy can change after a WAPS source edition is frozen. Study explanations must clearly distinguish the cycle-controlled exam source from current duty guidance. Airmen must follow current policy when performing official duties.

## Content model

Each learning item should carry enough metadata to support both rank-specific study and later app import.

| Field | Meaning |
|---|---|
| `content_id` | Stable MyPromotion identifier |
| `cycle` | Promotion cycle for which the item was validated |
| `catalog_publication_date` | First-publication date on the controlling catalog |
| `catalog_revision_date` | Revision date of the catalog actually reviewed |
| `afpt_number` / `afpt_revision` | Grade-specific PFE source record |
| `catalog_scope` | Exact included chapters or other source limits |
| `source_edition` | Controlling AFH 1 date |
| `source_paragraphs` | Exact AFH paragraph number or range |
| `chapter` / `section` | AFH chapter and ADTC section |
| `rank_tags` | `SSgt`, `TSgt`, or both |
| `adtc_level` | A Remembering, B Understanding, C Applying, or D Analyzing |
| `content_type` | Lesson, summary, flashcard, knowledge item, or SJT scenario |
| `difficulty` | Foundational, standard, or challenge |
| `status` | Draft, citation-verified, human-reviewed, or cycle-validated |
| `revalidation_note` | Change or uncertainty requiring review |
| `contributor_test_access_status` | Whether any contributor has accessed the relevant category of personnel test |

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

The app should randomize option order on each attempt. Static review copies must still avoid length, grammar, position, and absolute-word cues.

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
6. **Written compensation determination:** Pending an ethics counselor's written determination under 5 C.F.R. §2635.807 and other applicable rules, do not sell, advertise, accrue or defer payment, enter a compensation agreement, receive affiliate or royalty income, or route value through an owned entity or third party. A determination cannot waive a prohibition that applies.
7. **Off-duty-employment determination:** Complete DAF Form 3902 only if 5 C.F.R. § 3601.106 or applicable command or installation policy requires it. Form approval does not waive separate ethics, test-security, public-affairs, or trademark requirements.
8. **Security and policy review:** Submit the proposed public product through the DAFI 35-101/DoDI 5230.09 process and retain the clearance record.
9. **Trademark and public-use review:** Obtain a written determination before using Air Force names or marks; a disclaimer does not authorize trademark use.
10. **Testing-policy interpretation:** Obtain written TCO/JAG or responsible testing-policy guidance on development before and after relevant test access.

## Individual-study safeguards

AFH 1, §§9.10–9.11, gives a broad summary of individual-study restrictions. The current DAFMAN 36-2664, §4.12, is controlling and applies different provisions by status:

- §4.12.4 applies to examinees and potential examinees;
- §4.12.5 is headed “Examinees,” although one subparagraph separately mentions potential examinees; and
- §4.12.6 applies to members who have accessed personnel tests; §4.12.6.1 ties the development prohibition to the accessed test category, while §4.12.6.2's commercial-guide sharing rule is not expressly category-limited.

The owner is already a DAFMAN-defined **potential examinee** because an enlisted Airman who may become eligible for promotion testing falls within that definition. MyPromotion adopts one-user, non-collaborative use as a conservative product safeguard for a mixed-status audience, not as a claim that every provision applies identically to every user.

Product safeguards:

- license access to one individual user;
- prohibit account and content sharing;
- disable public or collaborative WAPS decks and notes;
- do not provide free-text test-experience or item-upload features;
- if actual or suspected test material is received, block further access and dissemination and immediately report it to both the supervisor and TCO as DAFMAN 36-2664, §4.14.1 requires;
- do not inspect, copy, analyze, forward, retain, or delete suspected material except as directed by authorized testing officials;
- avoid unit, classroom, or group-study modes for PFE preparation;
- keep commercial content and personal notes off government computers; and
- display clear test-security and individual-use notices.

## Developer test-access rule

DAFMAN 36-2664, §4.12.6.1, prohibits a member who has accessed a category of personnel test from participating **in any way** in developing a commercial study guide or pretest for that test category, whether or not the product contains actual test material. The practice-question content also falls close to the manual's broad definition of a “pretest.”

Accordingly:

- establish a documented register of any personnel-test access and the specific test category for every contributor;
- establish a handoff and recusal process before the owner receives relevant PFE access;
- stop the owner's content development and review at the access trigger; and
- obtain written guidance before assuming that ownership, passive revenue, support, moderation, or business administration remains permissible after access.

## Non-affiliation language

Use both statements below pending final legal and public-affairs review. The first addresses non-affiliation; the second is the personal-capacity disclaimer identified in DAFI 35-101 guidance.

> MyPromotion is an independent educational product. It is not affiliated with, endorsed by, sponsored by, or approved by the United States Air Force, the Department of the Air Force, the Department of Defense, or any other government agency. Official study requirements are published by the Department of the Air Force at studyguides.af.mil.

> The views expressed are those of the author and do not necessarily reflect the official policy or position of the Department of the Air Force, the Department of Defense, or the U.S. Government.

If military rank or title is used and the material significantly concerns an ongoing agency program, make the personal-capacity disclaimer reasonably prominent as required by 5 C.F.R. §3601.105.

