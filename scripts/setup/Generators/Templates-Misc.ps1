# =============================================================================
# Templates-Misc.ps1
# Invoice, case timeline, exhibit list, generic fallback.
# =============================================================================

function New-InvoiceContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference
    $dates   = $Doc.sprk_extractdates
    $invDate = if ($dates) { ($dates -split "[`n,]")[0].Trim() } else { 'February 1, 2026' }

    # Determine vendor and client
    $vendorName = if ($name -match 'Nakamura') { 'Nakamura Engineering Consulting LLC' }
                  elseif ($name -match 'Patel') { 'Patel Manufacturing Analysis, Inc.' }
                  else { 'Expert Witness Services' }

    $invNumber = if ($refs -match '([A-Z]+-\d{4}-\d{3,})') { $Matches[1] } else { 'NAKAMURA-2026-001' }

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# INVOICE

**Vendor:**       $vendorName
**Vendor ID:**    Nakamura-FED-EIN-XX-XXXXXXX
**Address:**      750 University Avenue, Suite 300, Palo Alto, CA 94301

**Bill To:**      $($Ctx.DefendantFirm) (counsel for Pinnacle Industries, Inc.)
**Attention:**    $($Ctx.LeadCounselD.Name), Esq.
**Address:**      $($Ctx.LeadCounselD.Address)

**Invoice No.:**  $invNumber
**Invoice Date:** $invDate
**Matter Reference:** $($Ctx.Caption); Case No. $($Ctx.CaseNumber)
**Engagement:**   Expert Witness Services — Patent Validity Opinion

---

## SUMMARY OF SERVICES

$summary

This invoice covers professional services rendered during the period December 15, 2025 through January 31, 2026, in connection with the above-referenced matter, including review of materials, analysis, expert report preparation, and related work.

---

## TIME ENTRIES — LEDES 1998B FORMAT

| Date       | Timekeeper       | Task Code | Activity Code | Description                                                                                          | Hours | Rate    | Amount     |
|------------|------------------|-----------|----------------|------------------------------------------------------------------------------------------------------|-------|---------|------------|
| 2025-12-15 | Dr. E. Nakamura  | E107      | A111           | Initial review of operative pleadings and complaint                                                  | 2.5   | \$650.00| \$1,625.00 |
| 2025-12-15 | Dr. E. Nakamura  | E107      | A101           | Initial review of '543 Patent and prosecution history                                                | 4.0   | \$650.00| \$2,600.00 |
| 2025-12-16 | Dr. E. Nakamura  | E107      | A101           | Review of MSA, TLA, and SOW agreements                                                                | 3.0   | \$650.00| \$1,950.00 |
| 2025-12-16 | Dr. E. Nakamura  | E107      | A101           | Review of Plaintiff's Initial Expert Report (Dr. Patel)                                              | 3.5   | \$650.00| \$2,275.00 |
| 2025-12-17 | Dr. E. Nakamura  | E107      | A101           | Review of AutoForge engineering documents (PIN-019841 - 020472)                                      | 4.5   | \$650.00| \$2,925.00 |
| 2025-12-18 | Dr. E. Nakamura  | E107      | A111           | Initial Expert Report — outline and methodology section                                              | 3.0   | \$650.00| \$1,950.00 |
| 2025-12-19 | Dr. E. Nakamura  | E107      | A111           | Initial Expert Report — opinions on infringement (claims 1, 8, 14)                                   | 5.5   | \$650.00| \$3,575.00 |
| 2025-12-22 | Dr. E. Nakamura  | E107      | A111           | Initial Expert Report — opinions on validity (anticipation/obviousness)                              | 6.0   | \$650.00| \$3,900.00 |
| 2025-12-23 | Dr. E. Nakamura  | E107      | A111           | Initial Expert Report — review and finalization                                                       | 3.0   | \$650.00| \$1,950.00 |
| 2025-12-23 | Dr. E. Nakamura  | E107      | A104           | Conference call with D. Kim (Chen Law Group) re: report finalization                                  | 1.0   | \$650.00| \$650.00   |
| 2026-01-08 | Dr. E. Nakamura  | E107      | A101           | Review of Defendant's Supplemental Damages Report (Dr. Patel)                                        | 4.0   | \$650.00| \$2,600.00 |
| 2026-01-12 | Dr. E. Nakamura  | E107      | A111           | Begin Rebuttal Report — outline and structure                                                         | 2.5   | \$650.00| \$1,625.00 |
| 2026-01-15 | Dr. E. Nakamura  | E107      | A101           | Additional review of Smith ('567 Patent) and Reeves Thesis prior art                                  | 3.0   | \$650.00| \$1,950.00 |
| 2026-01-19 | Dr. E. Nakamura  | E107      | A111           | Rebuttal Report — invalidity rebuttal section                                                         | 5.0   | \$650.00| \$3,250.00 |
| 2026-01-22 | Dr. E. Nakamura  | E107      | A111           | Rebuttal Report — non-infringement rebuttal section                                                   | 4.5   | \$650.00| \$2,925.00 |
| 2026-01-26 | Dr. E. Nakamura  | E107      | A104           | Conference call with D. Kim re: Rebuttal Report direction                                              | 1.0   | \$650.00| \$650.00   |
| 2026-01-29 | Dr. E. Nakamura  | E107      | A111           | Rebuttal Report — methodology and conclusions sections                                                | 3.5   | \$650.00| \$2,275.00 |
| 2026-01-30 | Dr. E. Nakamura  | E107      | A111           | Rebuttal Report — review and finalization                                                              | 2.5   | \$650.00| \$1,625.00 |
| **SUBTOTAL — Professional Services** | | | | | **61.0** | **\$650.00** | **\$39,650.00** |

---

## EXPENSES

| Date       | Description                                                              | Amount    |
|------------|--------------------------------------------------------------------------|-----------|
| 2025-12-22 | Materials reproduction (Dr. Patel report and exhibits)                   | \$184.50  |
| 2026-01-15 | Westlaw research charges (\$235.00 per session, 3 sessions)              | \$705.00  |
| 2026-01-22 | Materials reproduction (Pinnacle production materials excerpts)          | \$248.20  |
| 2026-01-30 | Final Rebuttal Report production and shipping (FedEx, certified delivery)| \$78.50   |
| **SUBTOTAL — Expenses** | | **\$1,216.20** |

---

## INVOICE TOTAL

| | |
|---|---|
| Professional Services Subtotal | \$ 39,650.00 |
| Expenses Subtotal              | \$  1,216.20 |
| **TOTAL DUE THIS INVOICE**     | **\$ 40,866.20** |

---

## PAYMENT TERMS

- Net 30 days from invoice date.
- Make checks payable to: Nakamura Engineering Consulting LLC
- Wire transfer instructions available upon request.
- All inquiries to: billing@nakamuraengineering.example.com or (650) 555-2187

## ENGAGEMENT REFERENCE

This invoice is rendered pursuant to the engagement letter between Dr. Emily Nakamura and Chen Law Group dated December 11, 2025. All work performed has been at the direction of counsel for Pinnacle Industries, Inc. in the above-captioned matter.

---

*$tldr*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-CaseTimelineContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# CASE TIMELINE — KEY EVENTS

**Matter:** $($Ctx.Caption)
**Case No.:** $($Ctx.CaseNumber)
**Prepared:** February 22, 2026 (current through Q1 2026)
**Prepared by:** $($Ctx.PlaintiffFirm) — Litigation Support Team

---

## OVERVIEW

$summary

This timeline captures the principal contractual, commercial, and procedural events relevant to the above-captioned matter, organized chronologically. It is intended to serve as a working reference for counsel, witnesses, and the trier of fact. Italicized entries denote internal Meridian or Pinnacle events that we have learned of through discovery; bold entries denote events at which a contemporaneous record exists in the parties' production.

---

## CONTRACT FORMATION AND COMMERCIAL RELATIONSHIP (2022 — 2024)

| Date       | Event                                                                                          | Source / Bates    |
|------------|------------------------------------------------------------------------------------------------|-------------------|
| 2018-10-14 | U.S. Patent Application No. 16/162,471 filed (Hendricks; Meridian assignee)                    | USPTO             |
| 2021-12-14 | **U.S. Patent No. 9,876,543 ("'543 Patent") issued**                                            | USPTO; MER-000001 |
| 2022-08-25 | First contact between Meridian (Sarah Chen) and Pinnacle (Thomas Wright) re: potential supplier | MER-014222        |
| 2022-11-04 | Initial commercial discussions — Meridian site visit to Pinnacle Fremont facility              | MER-014441        |
| 2022-12-19 | Mutual NDA signed (NDA-2022-038)                                                               | MER-000095; PIN-000018 |
| 2023-01-15 | **Master Services Agreement signed (MSA-2023-0147)**                                           | MER-000150        |
| 2023-03-08 | **Technology License Agreement signed (TLA-2023-0032)**                                         | MER-000350        |
| 2023-04-12 | Statement of Work No. 1 — Initial Component Manufacturing Run                                  | MER-001112        |
| 2023-09-22 | Statement of Work No. 2 — Expanded Production Line                                             | MER-001489        |
| 2024-01-08 | Statement of Work No. 3 — Specialty Alloy Components                                           | MER-001892        |
| 2024-04-15 | MSA Amendment No. 1 — Extended Term and Revised IP Provisions                                  | MER-002211        |
| 2024-09-03 | TLA Amendment No. 2 — Field of Use Clarification                                                | MER-002514        |

## DEVELOPMENT OF AUTOFORGE PRODUCT (2024)

| Date       | Event                                                                                          | Source / Bates    |
|------------|------------------------------------------------------------------------------------------------|-------------------|
| 2024-01    | *Pinnacle internal initiation of "AutoForge" product concept (per PIN witness Wright depo)*    | Wright Depo 78:14 |
| 2024-03-14 | **Internal Pinnacle email re: archiving Meridian process documentation**                       | PIN-016432        |
| 2024-06-20 | **Internal Pinnacle email re: AutoForge process parameter selection**                          | PIN-014892        |
| 2024-09    | *AutoForge engineering design review (Pinnacle internal)*                                      | PIN-021876        |
| 2024-10-01 | First commercial AutoForge sale (per Pinnacle financial production)                            | PIN-CONFIDENTIAL-019221 |
| 2024-12-15 | AutoForge Product Launch Press Release                                                          | Public            |

## EARLY DISPUTE PHASE (2025)

| Date       | Event                                                                                          | Source / Bates    |
|------------|------------------------------------------------------------------------------------------------|-------------------|
| 2025-02-11 | **AutoForge Customer Demonstration Notes (internal Pinnacle)**                                 | PIN-019234        |
| 2025-Q1-Q2 | Meridian internal investigation initiated; engineering review of AutoForge marketing materials | MER-016800-017200 |
| 2025-07-22 | **Meridian Cease-and-Desist Letter to Pinnacle**                                               | MER-018443        |
| 2025-08-05 | Meridian engagement of $($Ctx.PlaintiffFirm) confirmed                                          | MER-018511        |
| 2025-08-15 | Pinnacle engagement of $($Ctx.DefendantFirm) confirmed                                         | PIN-PRIV-000001   |
| 2025-08-20 | **Email: Engagement Confirmation — Baker & Associates LLP**                                     | mvp-doc-040       |
| 2025-08-25 | First settlement overture (Pinnacle proposes informal mediation)                                | MER-018612        |
| 2025-09-08 | **Pinnacle Litigation Hold Notice issued (privileged)**                                         | PIN-PRIV-000009   |
| 2025-09-12 | **Meridian Litigation Hold Notice issued (privileged)**                                         | mvp-doc-037       |
| 2025-09-15 | Pre-suit mediation declined by parties; complaint preparation finalized                         | MER-018844        |

## LITIGATION COMMENCED (2025-Q3 — 2026)

| Date       | Event                                                                                          | Source / Bates    |
|------------|------------------------------------------------------------------------------------------------|-------------------|
| 2025-09-22 | **Complaint filed (Dkt. 1)**                                                                    | mvp-doc-012       |
| 2025-10-01 | First discovery requests served — Plaintiff's First RFP and First Interrogatories               | mvp-doc-018, mvp-doc-020 |
| 2025-10-17 | Defendant's responses to discovery requests (containing principal disputed objections)          | (responses on file) |
| 2025-10-23 | **Stipulated Protective Order entered (Dkt. 64)**                                               | Court records     |
| 2025-11-04 | Meet-and-confer #1 (parties)                                                                   | MER-019100        |
| 2025-11-11 | Meet-and-confer #2 (parties)                                                                   | MER-019148        |
| 2025-11-15 | **Case Management Order entered (Dkt. 92) — sets schedule including March Markman, October trial** | Court records  |
| 2025-11-18 | **Defendant's Answer and Counterclaims filed (Dkt. 78)**                                        | mvp-doc-013       |
| 2025-11-18 | **Plaintiff's Motion to Compel Discovery filed (Dkt. 95)**                                      | mvp-doc-014       |
| 2025-12-15 | Discovery Order issued (Dkt. 102) — granting motion to compel in part                          | mvp-doc-060       |
| 2025-12-22 | **Defendant's first document production complete** (4,247 docs, 24,768 pages)                    | mvp-doc-029       |
| 2025-12-22 | **Plaintiff's first document production complete** (Bates MER-000001 - 022144)                    | mvp-doc-028       |
| 2026-01-09 | Plaintiff's deficiency letter regarding Defendant's first production                            | MER-019874        |
| 2026-01-15 | **Plaintiff's Supplemental Expert Report — Damages (Dr. Patel)**                                | mvp-doc-031       |
| 2026-01-22 | Defendant's response to deficiency letter                                                        | mvp-doc-049       |
| 2026-01-30 | **Joint Claim Construction and Prehearing Statement filed (Dkt. 87)**                            | Court records     |
| 2026-02-12 | **Defendant's Rebuttal Expert Report — Patent Validity (Dr. Nakamura)**                         | mvp-doc-033       |
| 2026-02-14 | **Plaintiff's Opening Claim Construction Brief filed (Dkt. 110)**                                | mvp-doc-017       |
| 2026-02-22 | Defendant's responsive Claim Construction Brief due                                              | (forthcoming)     |

## DEPOSITIONS COMPLETED OR SCHEDULED

| Date            | Deponent                                                                          | Status     |
|-----------------|-----------------------------------------------------------------------------------|------------|
| 2025-12-08      | James Morrison (Meridian VP Engineering)                                           | Completed  |
| 2025-12-15      | Thomas Wright (Pinnacle CEO)                                                      | Completed  |
| 2026-01-12      | Amanda Foster (Pinnacle In-House Counsel)                                          | Completed  |
| 2026-02-09      | Dr. Robert Patel (Plaintiff Expert)                                                | Completed  |
| 2026-02-24      | Dr. Emily Nakamura (Defense Expert)                                                | Scheduled  |
| Q2 2026         | Damages experts (Dr. Patel; Pinnacle expert TBD)                                   | Pending    |

## UPCOMING KEY DATES (per Case Management Order)

| Date       | Event                                                                                          |
|------------|------------------------------------------------------------------------------------------------|
| 2026-03-18 | Markman / Claim Construction Hearing — Day 1                                                   |
| 2026-03-19 | Markman / Claim Construction Hearing — Day 2                                                   |
| 2026-03-31 | Fact Discovery Cutoff                                                                          |
| 2026-04-30 | Claim Construction Order anticipated (estimated)                                                |
| 2026-05-31 | Expert Discovery Cutoff                                                                        |
| 2026-06-30 | Daubert and Summary Judgment Motions Due                                                       |
| 2026-08-15 | Hearing on Daubert and Summary Judgment Motions                                                |
| 2026-09-15 | Pretrial Conference                                                                            |
| 2026-10-14 | Trial begins (estimated 3-4 weeks)                                                              |

---

*$tldr*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-ExhibitListContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr

@"
$(Format-CaseCaption -Title 'PLAINTIFF MERIDIAN CORPORATION''S PROPOSED TRIAL EXHIBIT LIST')

Pursuant to the Court's Pretrial Order and Federal Rule of Civil Procedure 26(a)(3)(A)(iii), Plaintiff Meridian Corporation submits the following list of trial exhibits that it currently expects to offer in evidence at trial. Plaintiff reserves the right to offer additional exhibits in rebuttal, for impeachment, or as the trial proceeds.

$summary

This Exhibit List is preliminary and subject to revision based on the Court's rulings on the parties' motions in limine and other pretrial matters.

## EXHIBIT LIST

| Ex. No. | Description                                                                                          | Bates / Source                  | Date Produced | Anticipated Witness | Objections (if any) |
|---------|------------------------------------------------------------------------------------------------------|---------------------------------|---------------|---------------------|---------------------|
| P-001   | U.S. Patent No. 9,876,543 — Issued Patent                                                             | MER-000001 - MER-000067         | 2025-12-22    | Hendricks; Patel    | None                |
| P-002   | '543 Patent — Prosecution History (full)                                                              | MER-000068 - MER-000142         | 2025-12-22    | Hendricks; Patel    | None                |
| P-003   | Master Services Agreement (MSA-2023-0147), executed                                                  | MER-000150 - MER-000244         | 2025-12-22    | Chen; Wright        | None                |
| P-004   | Technology License Agreement (TLA-2023-0032), executed                                                | MER-000350 - MER-000423         | 2025-12-22    | Chen; Wright        | None                |
| P-005   | TLA Amendment No. 1, executed                                                                        | MER-000424 - MER-000437         | 2025-12-22    | Chen; Wright        | None                |
| P-006   | TLA Amendment No. 2 — Field of Use Clarification, executed                                           | MER-000438 - MER-000455         | 2025-12-22    | Chen; Wright        | Hearsay (subject)   |
| P-007   | Statement of Work No. 1 (SOW-001) and exhibits                                                       | MER-001112 - MER-001247         | 2025-12-22    | Morrison; Wright    | None                |
| P-008   | Statement of Work No. 2 (SOW-002) and exhibits                                                       | MER-001489 - MER-001621         | 2025-12-22    | Morrison; Wright    | None                |
| P-009   | Statement of Work No. 3 (SOW-003) and exhibits                                                       | MER-001892 - MER-002054         | 2025-12-22    | Morrison; Wright    | None                |
| P-010   | Technical Package — Original Disclosure to Pinnacle (Q1 2023)                                        | MER-002500 - MER-003280         | 2025-12-22    | Hendricks           | Confidentiality     |
| P-011   | Technical Package — Updated Disclosure (Q3 2024)                                                      | MER-003281 - MER-003644         | 2025-12-22    | Hendricks           | Confidentiality     |
| P-012   | Cease-and-Desist Letter, July 22, 2025                                                                | MER-018443                      | 2025-12-22    | Chen; Torres        | Hearsay (subject)   |
| P-013   | Pinnacle's Response to Cease-and-Desist Letter, August 15, 2025                                       | PIN-PRIV-000001 (cover only)    | 2025-12-22    | Wright              | Privileged content withheld |
| P-014   | AutoForge Product Launch Press Release, December 15, 2024                                             | Public                          | N/A (public)  | Wright              | None                |
| P-015   | AutoForge Marketing Datasheet v1.0                                                                    | PIN-022941                      | 2025-12-22    | Wright; Foster      | Authentication       |
| P-016   | AutoForge Engineering Design Review Slide Deck, Q4 2024                                              | PIN-021876                      | 2025-12-22    | Morrison; Wright    | None                |
| P-017   | Internal Pinnacle email re: AutoForge engineering team document handling, March 14, 2024              | PIN-016432                      | 2025-12-22    | Morrison            | None                |
| P-018   | Internal Pinnacle email re: AutoForge process parameter selection, June 20, 2024                      | PIN-014892                      | 2025-12-22    | Morrison            | None                |
| P-019   | AutoForge process control source code (excerpts)                                                      | PIN-CONFIDENTIAL-021482-022138  | 2025-12-31    | Patel               | Authentication       |
| P-020   | AutoForge customer purchase orders (representative sample, 50 docs)                                  | PIN-CONFIDENTIAL-022139-022871  | 2025-12-31    | Wright; Foster      | Confidentiality (HC-AEO) |
| P-021   | Pinnacle Financial Production — AutoForge revenue and unit volumes by quarter                         | PIN-CONFIDENTIAL-018721-019648  | 2025-12-22    | Patel; Foster       | Confidentiality (HC-AEO) |
| P-022   | Initial Expert Report of Dr. Robert Patel, November 14, 2025                                          | Counsel records                  | 2025-11-14    | Patel               | None                |
| P-023   | Supplemental Expert Report of Dr. Robert Patel — Damages, January 15, 2026                            | Counsel records                  | 2026-01-15    | Patel               | None                |
| P-024   | Initial Expert Report of Dr. Emily Nakamura, December 18, 2025                                        | Counsel records                  | 2025-12-18    | Nakamura            | Hearsay (subject)   |
| P-025   | Rebuttal Expert Report of Dr. Emily Nakamura, February 12, 2026                                       | Counsel records                  | 2026-02-12    | Nakamura            | Hearsay (subject)   |
| P-026   | Deposition of James Morrison, December 8, 2025 (designated portions)                                  | Counsel records                  | 2025-12-08    | Morrison            | (designations attached) |
| P-027   | Deposition of Thomas Wright, December 15, 2025 (designated portions)                                  | Counsel records                  | 2025-12-15    | Wright              | (designations attached) |
| P-028   | Deposition of Amanda Foster, January 12, 2026 (designated portions)                                  | Counsel records                  | 2026-01-12    | Foster              | (designations attached) |
| P-029   | Stipulated Protective Order (Dkt. 64)                                                                 | Court records                    | 2025-10-23    | (none — court doc)  | None                |
| P-030   | Discovery Order (Dkt. 102)                                                                            | Court records                    | 2025-12-15    | (none — court doc)  | None                |
| P-031   | Selected Customer Demonstration Notes (representative)                                                | PIN-019234                      | 2025-12-22    | Wright; Foster      | None                |
| P-032   | Selected Communications between Pinnacle and customers re: AutoForge                                  | PIN-CONFIDENTIAL-019712-020841  | 2025-12-31    | Wright              | Confidentiality (HC-AEO) |
| P-033   | Smith Patent (U.S. Patent No. 8,234,567) — for invalidity context                                     | Public                           | N/A (public)  | Patel; Nakamura     | None                |
| P-034   | Reeves Thesis (Stanford University, 2014) — for invalidity context                                    | Counsel records                  | 2025-11-14    | Patel; Nakamura     | None                |
| P-035   | Markman Hearing Transcript                                                                            | Court records                    | 2026-03-18/19 | (none — court doc)  | None                |
| P-036   | Hendricks Inventor Notebook (April 2017 - October 2018)                                              | MER-005000 - MER-005847         | 2025-12-22    | Hendricks           | None                |
| P-037   | Meridian Q4 2024 Sales by Customer (lost-sales analysis support)                                     | MER-FINANCIAL-002841-003117      | 2025-12-22    | Liu; Patel          | Confidentiality (HC-AEO) |
| P-038   | Meridian Pricing History 2022-2025 (price-erosion analysis support)                                  | MER-FINANCIAL-003118-003342      | 2025-12-22    | Liu; Patel          | Confidentiality (HC-AEO) |
| P-039   | Meridian Manufacturing Capacity Records 2024-2025                                                    | MER-OPERATIONS-001482-002211     | 2025-12-22    | Morrison            | None                |
| P-040   | Comparable License Agreements (Patel damages report exhibit)                                          | Counsel records                  | 2026-01-15    | Patel               | None                |
| P-041   | Joint Claim Construction Statement (Dkt. 87)                                                          | Court records                    | 2026-01-30    | (none — court doc)  | None                |
| P-042   | Plaintiff's Opening Claim Construction Brief (Dkt. 110)                                               | Court records                    | 2026-02-14    | (none — court doc)  | None                |

---

## RESERVATION OF RIGHTS

Plaintiff reserves the right to offer additional exhibits as may be required for rebuttal, impeachment, foundation for other exhibits, or in response to any defense theory developed during the course of trial. Plaintiff also reserves the right to offer demonstratives and summary exhibits prepared in accordance with Federal Rule of Evidence 1006.

## CERTIFICATE OF SERVICE

I hereby certify that on February 22, 2026, I caused a true and correct copy of the foregoing Plaintiff Meridian Corporation's Proposed Trial Exhibit List to be served on counsel for Pinnacle Industries, Inc. by electronic mail.

---

Dated: February 22, 2026

$($Ctx.PlaintiffFirm.ToUpper())

By: ______________________________
$($Ctx.LeadCounselP.Name), Esq.
$($Ctx.LeadCounselP.Title)
$($Ctx.LeadCounselP.Address)
$($Ctx.LeadCounselP.Phone)
$($Ctx.LeadCounselP.Email)

*Attorneys for Plaintiff Meridian Corporation*

---

*$tldr*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-GenericContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference
    $dates   = $Doc.sprk_extractdates
    $orgs    = $Doc.sprk_extractorganization
    $people  = $Doc.sprk_extractpeople

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# $name

**Matter:** $($Ctx.Caption)
**Case No.:** $($Ctx.CaseNumber)
**Date:** $(if ($dates) { ($dates -split "[`n,]")[0].Trim() } else { '' })
**Reference:** $refs

---

## Summary

$summary

## Overview

$tldr

## Parties

$(Format-EntityList $orgs)

## Key Persons

$(Format-EntityList $people)

## Key Reference Numbers

$(Format-EntityList $refs)

---

*Document ID: $($Doc.sprk_scenarioid)*
"@
}
