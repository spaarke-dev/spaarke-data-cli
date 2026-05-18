# =============================================================================
# Templates-Memos.ps1
# Internal memoranda — litigation hold, budget review.
# =============================================================================

function New-LitigationHoldContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# MERIDIAN CORPORATION — INTERNAL MEMORANDUM

**TO:**     All Designated Custodians (List Attached as Exhibit A)
**FROM:**   $($Ctx.ClientContact.Name), General Counsel
**CC:**     $($Ctx.LeadCounselP.Name), $($Ctx.PlaintiffFirm); Information Technology Department
**DATE:**   September 12, 2025
**RE:**     **LITIGATION HOLD — CONTEMPLATED LITIGATION AGAINST PINNACLE INDUSTRIES, INC. — IMMEDIATE PRESERVATION REQUIRED**

---

## ATTORNEY-CLIENT PRIVILEGED AND CONFIDENTIAL — DO NOT DISCLOSE

This memorandum issues a formal **Litigation Hold** in connection with contemplated patent infringement and breach of contract litigation against Pinnacle Industries, Inc. ("Pinnacle"). Each recipient of this memorandum has an immediate and continuing legal duty to preserve, and not destroy or alter, all documents and electronically stored information ("ESI") within their custody or control that may be relevant to the contemplated litigation.

**This Litigation Hold takes effect immediately and supersedes all routine document destruction, archive purging, and email retention policies that would otherwise apply.**

## 1. BACKGROUND

$summary

The legal team has determined that litigation against Pinnacle is reasonably anticipated. As of the date of this memorandum, the Company has not yet filed suit; however, our duty to preserve evidence has attached.

## 2. SCOPE OF PRESERVATION

You must preserve all documents and ESI within your possession, custody, or control that relate to **any** of the following subject matters (the "Preserved Subjects"):

(a) **Pinnacle Industries, Inc.** — All communications with, agreements with, or references to Pinnacle, including all of Pinnacle's officers, directors, employees, agents, suppliers, customers, and affiliates.

(b) **The Master Services Agreement and Technology License Agreement** — The MSA dated January 15, 2023, the TLA dated March 8, 2023, all amendments, all SOWs entered thereunder, all related communications, and all materials produced or exchanged in connection with those agreements.

(c) **The Technical Package and Licensed Technology** — All documents, drawings, simulations, test data, process parameters, communications, and other materials concerning the Technical Package, the Licensed Technology, and the underlying intellectual property.

(d) **United States Patent No. 9,876,543** — All documents concerning the conception, reduction to practice, prosecution, maintenance, licensing, enforcement, marking, or commercialization of the '543 Patent, including the inventor file, prosecution history, and any related opinions of counsel.

(e) **The AutoForge Multi-Stage Compression Platform** — All communications, internal analyses, observations, market intelligence, customer feedback, competitive intelligence, photographs, samples, and any other materials concerning Pinnacle's AutoForge product.

(f) **The Cease-and-Desist Process** — All communications, drafts, internal discussions, and documents relating to the cease-and-desist letter sent to Pinnacle on July 22, 2025, and all responses, follow-up communications, and internal deliberations regarding next steps.

(g) **Damages Information** — All financial information bearing on Meridian's lost sales, lost profits, price erosion, and reasonable royalty analyses with respect to the AutoForge product, including sales records, customer communications, pricing data, manufacturing capacity records, and budget materials.

## 3. CATEGORIES OF DOCUMENTS AND ESI

The preservation duty extends to all forms of documents and ESI, including without limitation:

- **Email** — All email messages (sent, received, draft, deleted, archived) on Company servers, on Outlook .OST/.PST files, on mobile devices, on personal devices used for work purposes, and in any cloud-based email service.
- **Instant Messages and Chat** — Microsoft Teams chats, Slack messages, WhatsApp messages, SMS/MMS, and any other electronic communications platforms used for work purposes.
- **Documents** — Microsoft Word documents, PowerPoint presentations, Excel spreadsheets, PDF files, OneNote notebooks, technical drawings (CAD, PLM systems), engineering simulation files, test data files, photographs, audio and video recordings.
- **Cloud Storage** — All files stored in OneDrive, SharePoint, Box, Dropbox, Google Drive, or any other cloud-storage service used for work purposes.
- **Source Code and Engineering Files** — All software repositories, version-control histories, build artifacts, test results, and engineering simulation outputs.
- **Calendar Entries and Meeting Notes** — Meeting invitations, agendas, notes, and recordings (Teams, Zoom, etc.).
- **Voicemails** — Voicemail recordings, voicemail transcriptions.
- **Hard-Copy Documents** — Paper files, notebooks, post-it notes, sticky notes, whiteboards, and any other physical materials.
- **Mobile Device Data** — All work-related data on Company-issued and BYOD mobile devices, including text messages, photographs, contacts, location data, and app data.
- **Backup Tapes and Archives** — All backup tapes, archived email, and any other historical media.

## 4. PROHIBITED ACTIONS — IMMEDIATE EFFECT

As of receipt of this memorandum, you are **prohibited** from taking any of the following actions with respect to potentially Preserved Documents and ESI:

1. **Do not delete** any documents or ESI from your computer, mobile device, email account, cloud-storage account, voicemail, or any other source.

2. **Do not allow** any documents or ESI to be deleted by automatic policies, including the Company's standard email retention rules. The IT Department is being instructed to suspend automatic deletion of email and ESI for all Preserved Custodians effective immediately.

3. **Do not modify** any documents or ESI, including metadata.

4. **Do not destroy** any hard-copy documents, including by routine office cleanup, file disposal, or printer/scanner queue clearing.

5. **Do not transfer** any documents or ESI from Company systems to personal devices, personal email accounts, or personal cloud storage.

6. **Do not discuss** the contemplated litigation, this Litigation Hold, or any communications with counsel regarding the contemplated litigation, with anyone other than (a) other Designated Custodians who have themselves received this Hold, (b) Meridian's General Counsel, (c) outside counsel at Baker & Associates LLP, or (d) IT personnel acting under direction of counsel for purposes of implementing this Hold.

## 5. AFFIRMATIVE OBLIGATIONS

You must:

1. **Acknowledge receipt** of this Litigation Hold by replying to this email within forty-eight (48) hours, confirming that you have read and understood the obligations set forth herein.

2. **Identify potentially responsive materials** in your custody or control. Within fifteen (15) business days, you must complete the attached Custodian Questionnaire (Exhibit B) and return it to General Counsel.

3. **Cooperate with IT** in the imaging or collection of relevant data sources from your computer, mobile devices, and any other systems within your control.

4. **Notify Counsel** if you become aware of any potentially responsive materials that may be at risk of loss or destruction (for example, materials held by departing employees, materials subject to third-party retention controls, or materials that may be subject to upcoming system migrations or decommissioning).

5. **Suspend personal-device deletions** if any work-related materials are stored on personal devices, until those devices have been properly imaged or the relevant materials have been transferred to Company systems.

## 6. DURATION

This Litigation Hold remains in effect until the General Counsel issues a written notice releasing the Hold. **Do not assume the Hold is no longer in effect; you will be notified in writing.**

## 7. CONSEQUENCES OF NON-COMPLIANCE

Failure to comply with this Litigation Hold may result in:
- Disciplinary action up to and including termination of employment;
- Personal exposure to monetary sanctions or contempt findings imposed by the court;
- Adverse evidentiary inferences against the Company in the contemplated litigation; and
- Personal liability for spoliation under applicable law.

## 8. QUESTIONS

Direct any questions regarding this Litigation Hold to:

$($Ctx.ClientContact.Name), General Counsel
$($Ctx.ClientContact.Phone)
$($Ctx.ClientContact.Email)

— or to outside counsel:

$($Ctx.LeadCounselP.Name), Esq.
$($Ctx.LeadCounselP.Title)
$($Ctx.LeadCounselP.Firm)
$($Ctx.LeadCounselP.Phone)
$($Ctx.LeadCounselP.Email)

---

## ACKNOWLEDGMENT

By replying to this email, I confirm that I have read and understood this Litigation Hold and agree to comply with the obligations set forth herein.

Name (Print): __________________________
Title:        __________________________
Date:         __________________________
Signature:    __________________________

---

**ATTACHMENTS:**
- Exhibit A — List of Designated Custodians (52 individuals)
- Exhibit B — Custodian Questionnaire
- Exhibit C — Glossary of ESI Sources and Locations
- Exhibit D — IT Department Implementation Plan (separate distribution)

---

*$tldr*
*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-BudgetMemoContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# $($Ctx.PlaintiffFirm.ToUpper()) — INTERNAL CLIENT MEMORANDUM

**TO:**     $($Ctx.ClientContact.Name), General Counsel, Meridian Corporation
**FROM:**   $($Ctx.LeadCounselP.Name), Lead Partner; Daniel Crawford, Senior Associate
**CC:**     Sarah Chen, CFO, Meridian Corporation; Catherine Liu, Director of Legal Operations, Meridian
**DATE:**   December 18, 2025
**RE:**     **Q4 2025 Litigation Budget Review and 2026 Forecast — Meridian v. Pinnacle (Case No. $($Ctx.CaseNumber))**

---

## ATTORNEY-CLIENT PRIVILEGED AND ATTORNEY WORK PRODUCT

This memorandum provides a year-end review of the litigation budget for Q4 2025 and a forecast of expected fees and expenses for 2026 in connection with $($Ctx.Caption). This information is provided to assist Meridian's financial planning and to support the upcoming budget review with Meridian's Board of Directors.

## I. EXECUTIVE SUMMARY

$summary

**Q4 2025 Actual vs. Budget**

| Category               | Q4 2025 Budget | Q4 2025 Actual | Variance | % of Budget |
|------------------------|---------------:|---------------:|---------:|-------------|
| Attorney Fees          | \$ 285,000     | \$ 312,400     | (\$ 27,400) |  +10%      |
| Paralegal Fees         | \$  72,000     | \$  78,200     | (\$  6,200) |   +9%      |
| Expert Witness Fees    | \$ 145,000     | \$ 168,750     | (\$ 23,750) |  +16%      |
| Document Review/eDiscovery | \$  88,000 | \$  94,300     | (\$  6,300) |   +7%      |
| Court Reporter / Depo. | \$  42,000     | \$  47,800     | (\$  5,800) |  +14%      |
| Travel and Lodging     | \$  18,000     | \$  21,400     | (\$  3,400) |  +19%      |
| Filing Fees and Costs  | \$   8,500     | \$   7,200     |  \$  1,300  |  -15%      |
| Other Expenses         | \$  15,000     | \$  12,400     |  \$  2,600  |  -17%      |
| **TOTAL Q4 2025**      | **\$ 673,500** | **\$ 742,450** | **(\$ 68,950)** | **+10%** |

**YTD 2025 Actuals (Inception Q3 2025 through Q4 2025):**

- Total Fees and Costs: **\$1,094,200**
- vs. Inception-to-Date Budget: **\$1,038,000** (+5.4%)

The over-budget variance in Q4 is driven primarily by (a) accelerated expert work in connection with the upcoming Markman hearing (expert fees +16% of budget), (b) additional deposition activity following Pinnacle's Q4 production (depo costs +14%), and (c) related travel for in-person depositions taken on the East Coast (travel +19%). Document review and eDiscovery costs were modestly over budget due to the volume of Pinnacle's December 22 production, but are within an acceptable variance band.

$tldr

## II. 2026 BUDGET FORECAST

The forecasted 2026 budget is built around the case schedule entered by Judge Alsup on November 15, 2025 (Dkt. 92). Key milestones driving 2026 fees:

- **Q1 2026:** Markman hearing (March 18-19); fact discovery cutoff (March 31); final infringement and invalidity contentions; expert reports.
- **Q2 2026:** Expert depositions; Daubert motions; summary judgment briefing.
- **Q3 2026:** Summary judgment hearing (estimated July); pretrial preparation; motions in limine; jury instructions.
- **Q4 2026:** Trial (3-4 weeks, currently scheduled to begin October 14, 2026, subject to confirmation).

**2026 Forecast (by quarter)**

| Category               | Q1 2026     | Q2 2026     | Q3 2026     | Q4 2026     | 2026 Total  |
|------------------------|------------:|------------:|------------:|------------:|------------:|
| Attorney Fees          | \$ 425,000  | \$ 538,000  | \$ 612,000  | \$ 1,150,000| \$ 2,725,000|
| Paralegal Fees         | \$  98,000  | \$ 112,000  | \$ 142,000  | \$   280,000| \$   632,000|
| Expert Witness Fees    | \$ 215,000  | \$ 285,000  | \$  95,000  | \$   325,000| \$   920,000|
| Document Review        | \$  78,000  | \$  62,000  | \$  48,000  | \$   125,000| \$   313,000|
| Court Reporter / Depo. | \$  68,000  | \$  72,000  | \$  18,000  | \$   215,000| \$   373,000|
| Travel and Lodging     | \$  42,000  | \$  56,000  | \$  35,000  | \$   165,000| \$   298,000|
| Trial Support          | \$  -       | \$  -       | \$  85,000  | \$   285,000| \$   370,000|
| Other Expenses         | \$  18,000  | \$  22,000  | \$  28,000  | \$    72,000| \$   140,000|
| **QUARTERLY TOTAL**    | **\$ 944,000** | **\$ 1,147,000** | **\$ 1,063,000** | **\$ 2,617,000** | **\$ 5,771,000** |

**Cumulative 2025 + 2026 forecast: approximately \$6.87 million.**

## III. KEY DRIVERS AND ASSUMPTIONS

The forecast assumes:

1. The case proceeds to trial on the current schedule (October 14, 2026). A delay of one quarter would shift approximately \$1.4 million in trial-related fees and costs.
2. No interlocutory appeals or extraordinary writs will be required. We do not currently anticipate any.
3. The current expert witness lineup remains stable. We have budgeted for Dr. Patel (technical liability), Dr. Patel (damages, supplemental), Catherine Liu deposition preparation (fact witness, no expert fees), and one additional rebuttal expert if needed.
4. Discovery is substantially complete by March 31, 2026. The forecast does not include any contingency for renewed merits discovery beyond that date.

## IV. POTENTIAL VARIANCE FACTORS

We identify the following factors that could cause the 2026 budget to vary from the forecast:

- **Settlement.** A settlement at any point would substantially reduce remaining fees. We will continue to monitor settlement opportunities and will report on any developments.
- **Daubert motions.** If Pinnacle moves to exclude Dr. Patel under Daubert, opposing such a motion could add \$120,000-\$180,000 to Q2 fees.
- **Summary judgment.** If either party files a motion for summary judgment of (or against) infringement, validity, or willfulness, the briefing and hearing could add up to \$250,000 in Q2-Q3.
- **Trial length.** The forecast assumes a 3-4 week trial. A longer trial (5-6 weeks) would add \$400,000-\$600,000.
- **Post-trial motions and appeal.** The forecast does not include post-trial motions, attorney's-fees motions, or any appeal. A typical Federal Circuit appeal would add \$600,000-\$900,000 in 2027.

## V. RECOMMENDATIONS

1. **Approve a 5-7% contingency** on top of the 2026 forecast to absorb minor schedule slips and unexpected motion practice.

2. **Reserve \$1.0-\$1.5 million for post-trial / appeal** in Meridian's 2027 budget planning (should not be charged to 2026).

3. **Consider settlement strategy.** As we approach the Markman hearing, the parties' relative positions on settlement may change materially. We recommend re-evaluating settlement posture in Q2 2026 after the claim construction order issues.

4. **Continued monthly billing reviews.** We will continue our practice of monthly invoice review with Meridian's Director of Legal Operations to ensure transparency and budget alignment.

We are happy to walk through any of these figures in more detail at your convenience. Please let us know if you would like a video conference to discuss the forecast prior to the Board meeting on January 14, 2026.

---

*Document ID: $($Doc.sprk_scenarioid)*
"@
}
