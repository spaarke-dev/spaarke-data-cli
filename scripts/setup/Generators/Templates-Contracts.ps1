# =============================================================================
# Templates-Contracts.ps1
# Document templates for: contracts, SOWs, amendments, NDAs, terminations.
# Each template returns a markdown string; the orchestrator (Generate-StubFiles)
# converts to PDF/DOCX downstream via pandoc.
# =============================================================================

function New-SowContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name      = $Doc.sprk_documentname
    $summary   = $Doc.sprk_filesummary
    $tldr      = $Doc.sprk_filetldr
    $refs      = $Doc.sprk_extractreference
    $dates     = $Doc.sprk_extractdates
    $orgs      = $Doc.sprk_extractorganization
    $people    = $Doc.sprk_extractpeople
    $keywords  = $Doc.sprk_filekeywords

    # Pull SOW number from filename if present
    $sowNumber = if ($Doc.sprk_filename -match 'sow-(\d+)') { "SOW-{0:D3}" -f [int]$Matches[1] } else { 'SOW-000' }
    # Pull effective date from extractdates (first date)
    $effectiveDate = if ($dates) { ($dates -split "[`n,]")[0].Trim() } else { 'the date last signed below' }

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# STATEMENT OF WORK

**Statement of Work No.:** $sowNumber
**Effective Date:** $effectiveDate
**Master Services Agreement:** MSA-2023-0147 dated January 15, 2023

---

## PARTIES

This Statement of Work ("SOW") is entered into pursuant to and governed by the Master Services Agreement ("MSA") dated January 15, 2023 (the "MSA") between **MERIDIAN CORPORATION** ("Meridian" or "Client"), a Delaware corporation, and **PINNACLE INDUSTRIES, INC.** ("Pinnacle" or "Service Provider"), a California corporation.

This SOW is incorporated into and made a part of the MSA. Capitalized terms used but not defined in this SOW have the meanings given to them in the MSA. To the extent of any conflict between this SOW and the MSA, the MSA controls except where this SOW expressly states otherwise.

---

## 1. SCOPE OF SERVICES

### 1.1 Background and Purpose

$summary

The Services to be performed under this SOW are intended to support Meridian's ongoing precision manufacturing program in the field of advanced thermal compression molding processes covered, in part, by $($Ctx.Patent) ("the '543 Patent") and related know-how (collectively, the "Licensed Technology").

### 1.2 Description of Services

Pinnacle shall provide the following Services to Meridian:

(a) **Engineering and Process Development.** Pinnacle shall perform engineering analysis, process development, and tooling-design services as reasonably required to manufacture the Components described in Section 1.3, in accordance with the technical specifications, design drawings, and process parameters provided by Meridian (collectively, the "Technical Package").

(b) **Manufacturing.** Pinnacle shall manufacture the quantities of Components specified in Section 1.3 using only the Licensed Technology described in the Technical Package, and only at Pinnacle's facility located at 1200 Innovation Boulevard, Fremont, California 94538 (the "Authorized Facility").

(c) **Quality Assurance and Documentation.** Pinnacle shall perform incoming material inspection, in-process quality inspection, and final outgoing inspection in accordance with the Quality Plan attached as Exhibit B, and shall maintain records of all inspections, deviations, corrective actions, and process parameter adjustments for a period of not less than seven (7) years following completion of this SOW.

(d) **Reporting.** Pinnacle shall deliver weekly written status reports to Meridian's program manager identifying production volumes, quality metrics, schedule status, identified risks, and any deviations from the Technical Package.

### 1.3 Components and Quantities

$tldr

Specific volume targets, ramp schedule, and acceptance criteria are set forth in Exhibit A (Technical Specifications) and Exhibit C (Acceptance and Delivery Schedule).

### 1.4 Out of Scope

The following are expressly excluded from this SOW unless added by written change order signed by both parties:

(a) Development, optimization, or any modification of the Licensed Technology, the Technical Package, or any process parameters not expressly authorized by Meridian in writing.

(b) Manufacturing of any product, component, or assembly intended for use in any system or product line other than Meridian's authorized program identified in Section 1.1.

(c) Use of the Licensed Technology for the benefit of any third party or in connection with any product not designed by or for Meridian.

(d) Any reverse engineering, decompilation, derivation, or analysis of the Licensed Technology for purposes other than the limited internal use necessary to perform the Services.

---

## 2. PROJECT SCHEDULE AND MILESTONES

The Services will be performed in accordance with the following milestone schedule:

| Milestone | Target Date | Acceptance Criteria |
|-----------|-------------|---------------------|
| M1 — Tooling Design Approval | within 30 days of Effective Date | Meridian written approval of tooling design package |
| M2 — Process Qualification | within 60 days of M1 | First-article inspection passes per Exhibit B |
| M3 — Initial Production Lot | within 30 days of M2 | First lot delivered and accepted per Exhibit C |
| M4 — Full Production Ramp | within 90 days of M3 | Sustained run rate ≥ 90% of target volume |
| M5 — SOW Completion | per Exhibit C delivery schedule | All quantities delivered and accepted |

Pinnacle shall notify Meridian immediately of any condition that is reasonably expected to delay any milestone by more than five (5) business days.

---

## 3. FEES AND PAYMENT

### 3.1 Total SOW Value

The total fees payable to Pinnacle for performance of the Services described in this SOW shall not exceed the amount set forth in Exhibit D (Pricing), which is incorporated by reference. Pinnacle shall not perform any work outside the agreed scope without a signed change order specifying the additional cost.

### 3.2 Invoicing

Pinnacle shall invoice Meridian monthly in arrears based on milestones achieved and quantities delivered and accepted in accordance with Exhibit C. Each invoice shall reference $sowNumber and the MSA.

### 3.3 Payment Terms

Payment terms are net thirty (30) days from receipt of an undisputed invoice, in accordance with Section 7 of the MSA.

---

## 4. INTELLECTUAL PROPERTY

### 4.1 Background IP

Meridian retains all right, title, and interest in and to the Licensed Technology, the Technical Package, all Background IP (as defined in the MSA), and all improvements, modifications, derivatives, or refinements to any of the foregoing made by Pinnacle in the performance of the Services. Pinnacle hereby assigns to Meridian all such rights to the maximum extent permitted by law.

### 4.2 No License Beyond Scope

Nothing in this SOW grants to Pinnacle any license, express or implied, to the Licensed Technology or any Background IP for any purpose other than the limited internal use necessary to perform the Services described in this SOW for the exclusive benefit of Meridian. Any use of the Licensed Technology by Pinnacle outside the express scope of this SOW shall constitute a material breach of the MSA.

### 4.3 Acknowledgement

Pinnacle acknowledges that the Licensed Technology embodies inventions claimed in the '543 Patent and other Meridian intellectual property, that Meridian has invested substantial resources in developing the Licensed Technology, and that any unauthorized use, disclosure, transfer, or incorporation of the Licensed Technology into any other product, process, or program would cause irreparable harm to Meridian.

---

## 5. CONFIDENTIALITY

The terms of Section 9 (Confidentiality) of the MSA apply to all information exchanged in the performance of this SOW. The Technical Package, all process parameters, all engineering drawings, and all Deliverables constitute Confidential Information of Meridian.

---

## 6. AUDIT AND COMPLIANCE

Meridian and its representatives shall have the right, upon reasonable notice and not more than once per calendar quarter, to inspect Pinnacle's Authorized Facility, manufacturing records, and quality records relating to the Services for the purpose of verifying Pinnacle's compliance with this SOW, the Technical Package, and the use restrictions in Section 4.2. Pinnacle shall cooperate fully with such inspections and shall provide reasonable assistance.

---

## 7. NOTICES

Notices under this SOW shall be delivered as provided in Section 13 of the MSA.

For Meridian:
$($Ctx.ClientContact.Name), $($Ctx.ClientContact.Title)
$($Ctx.ClientContact.Org)
$($Ctx.ClientContact.Address)
$($Ctx.ClientContact.Email)

For Pinnacle:
General Counsel
PINNACLE INDUSTRIES, INC.
1200 Innovation Boulevard, Fremont, CA 94538
legal@example.com

---

## 8. SIGNATURES

The parties have executed this Statement of Work as of the Effective Date.

**MERIDIAN CORPORATION**

By: ______________________________
Name: $($Ctx.ClientContact.Name)
Title: $($Ctx.ClientContact.Title)
Date: ____________________________


**PINNACLE INDUSTRIES, INC.**

By: ______________________________
Name: Michael R. Whitfield
Title: Chief Operating Officer
Date: ____________________________

---

**EXHIBITS**

- Exhibit A: Technical Specifications
- Exhibit B: Quality Plan
- Exhibit C: Acceptance and Delivery Schedule
- Exhibit D: Pricing
- Exhibit E: Authorized Facility Description

---

*Document keywords: $keywords*
*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-AmendmentContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference
    $dates   = $Doc.sprk_extractdates
    $effectiveDate = if ($dates) { ($dates -split "[`n,]")[0].Trim() } else { 'the date last signed below' }

    $isMsa = $Doc.sprk_filename -match 'msa-amend'
    $parentTitle = if ($isMsa) { 'Master Services Agreement dated January 15, 2023' }
                   else { 'Technology License Agreement dated March 8, 2023 (TLA-2023-0032)' }
    $amendmentNumber = if ($Doc.sprk_filename -match 'amendment-(\d+)|amendment-no-(\d+)') {
        if ($Matches[1]) { "Amendment No. $($Matches[1])" } else { "Amendment No. $($Matches[2])" }
    } else { 'Amendment' }

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# $amendmentNumber TO $($parentTitle.ToUpper())

**Amendment Effective Date:** $effectiveDate

---

## PARTIES

This $amendmentNumber (this "Amendment") is entered into as of the Amendment Effective Date by and between **MERIDIAN CORPORATION**, a Delaware corporation ("Meridian"), and **PINNACLE INDUSTRIES, INC.**, a California corporation ("Pinnacle"). Meridian and Pinnacle are each referred to herein individually as a "Party" and collectively as the "Parties."

---

## RECITALS

WHEREAS, the Parties entered into that certain $parentTitle (as the same may have been amended or modified from time to time prior to the date hereof, the "Agreement");

WHEREAS, the Parties desire to amend the Agreement on the terms and conditions set forth in this Amendment;

WHEREAS, $tldr;

NOW, THEREFORE, in consideration of the mutual covenants and agreements set forth herein and in the Agreement, and for other good and valuable consideration, the receipt and sufficiency of which are hereby acknowledged, the Parties hereby agree as follows:

---

## AGREEMENT

### 1. Definitions

Capitalized terms used but not otherwise defined in this Amendment have the meanings given to them in the Agreement.

### 2. Amendments to the Agreement

$summary

Effective as of the Amendment Effective Date, the Agreement is hereby amended as follows:

**(a)** *Term Extension.* Section 3.1 (Term) of the Agreement is hereby deleted in its entirety and replaced with the following:

> "**3.1 Term.** This Agreement shall be effective as of the Effective Date and shall continue in full force and effect until December 31, 2026, unless earlier terminated in accordance with Section 10 of this Agreement (the 'Term'). The Term may be extended only by a written amendment signed by both Parties."

**(b)** *Field of Use Clarification.* Section 4.3 (Field of Use) of the Agreement is hereby amended by inserting at the end of the existing text the following new sentences:

> "For the avoidance of doubt, the license granted under Section 4.1 does not extend to any product, system, or process that (i) is not the subject of a then-active Statement of Work signed by both Parties, or (ii) is intended for use outside the Authorized Field defined in Exhibit A. The Parties acknowledge that the use restrictions in this Section 4.3 are material to Meridian's grant of the license and that any use outside the Authorized Field shall constitute a material breach of this Agreement."

**(c)** *IP Provisions; Improvements.* Section 5.4 (Improvements) of the Agreement is hereby deleted in its entirety and replaced with the following:

> "**5.4 Improvements.** All improvements, modifications, derivatives, refinements, optimizations, or enhancements to the Licensed Technology developed, conceived, or reduced to practice by either Party (whether independently or jointly) during the Term, and whether or not patentable, shall be the sole and exclusive property of Meridian. Pinnacle hereby assigns to Meridian all right, title, and interest in and to all such improvements and shall, at Meridian's request and expense, execute and deliver such further documents and take such further actions as Meridian may reasonably require to perfect or evidence such assignment."

**(d)** *Audit Rights.* A new Section 9.6 is hereby added to the Agreement as follows:

> "**9.6 Audit.** Upon not less than ten (10) business days' prior written notice and not more than twice per calendar year, Meridian or its representatives shall have the right to inspect Pinnacle's facilities, manufacturing records, supplier records, and product samples relating to the Licensed Technology for purposes of verifying compliance with the use restrictions, field-of-use limitations, and reporting obligations under this Agreement."

### 3. No Other Modifications

Except as expressly modified by this Amendment, all terms, conditions, covenants, and obligations of the Agreement remain in full force and effect and are hereby ratified and confirmed by the Parties. In the event of any conflict between the terms of this Amendment and the terms of the Agreement, the terms of this Amendment shall control with respect to the subject matter addressed herein.

### 4. Reservation of Rights

Nothing in this Amendment shall be construed as a waiver, release, or modification of any right, claim, defense, or remedy that either Party may have arising out of or relating to events, acts, or omissions occurring prior to the Amendment Effective Date. Each Party expressly reserves all such rights, claims, defenses, and remedies.

### 5. Governing Law

This Amendment shall be governed by and construed in accordance with the laws of the State of California without regard to its conflicts-of-law principles, consistent with Section 14 of the Agreement.

### 6. Counterparts

This Amendment may be executed in counterparts, each of which shall constitute an original and all of which together shall constitute one and the same instrument. Signatures delivered electronically (including by PDF) shall be deemed valid and binding to the same extent as original signatures.

---

## SIGNATURES

IN WITNESS WHEREOF, the Parties have executed this Amendment as of the Amendment Effective Date.

**MERIDIAN CORPORATION**

By: ______________________________
Name: $($Ctx.ClientContact.Name)
Title: $($Ctx.ClientContact.Title)
Date: ____________________________


**PINNACLE INDUSTRIES, INC.**

By: ______________________________
Name: Thomas R. Wright
Title: Chief Executive Officer
Date: ____________________________

---

*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-NdaContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference
    $dates   = $Doc.sprk_extractdates
    $people  = $Doc.sprk_extractpeople
    $effectiveDate = if ($dates) { ($dates -split "[`n,]")[0].Trim() } else { 'the date last signed below' }

    # Identify expert from name/people
    $expertName = if ($people) { ($people -split "[`n,]")[0].Trim() } else { 'the Expert' }
    if ($name -match 'Dr\.\s+([A-Za-z\.\s]+)') { $expertName = "Dr. $($Matches[1].Trim())" }
    $isExpertNda = $name -match 'Expert'

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# EXPERT WITNESS CONFIDENTIALITY AND NON-DISCLOSURE AGREEMENT

**Effective Date:** $effectiveDate
**Matter:** $($Ctx.Caption); Case No. $($Ctx.CaseNumber)

---

## PARTIES

This Expert Witness Confidentiality and Non-Disclosure Agreement (this "Agreement") is entered into as of the Effective Date by and among:

**MERIDIAN CORPORATION**, a Delaware corporation, with its principal place of business at 4500 Technology Drive, Suite 300, San Jose, California 95134 ("**Meridian**" or "**Client**");

**$($Ctx.PlaintiffFirm.ToUpper())**, a California limited liability partnership, with offices at 555 Market Street, Suite 2400, San Francisco, California 94105 ("**Counsel**"); and

**$($expertName.ToUpper())**, an individual residing in the United States ("**Expert**").

Each of Meridian, Counsel, and Expert is referred to herein individually as a "**Party**" and collectively as the "**Parties**." Meridian and Counsel are sometimes referred to collectively as the "**Disclosing Parties**."

---

## RECITALS

WHEREAS, Meridian is the plaintiff in $($Ctx.Caption), pending in the $($Ctx.Court), Case No. $($Ctx.CaseNumber) (the "**Litigation**");

WHEREAS, Counsel represents Meridian in the Litigation;

WHEREAS, $tldr;

WHEREAS, in connection with such retention, the Disclosing Parties may disclose to Expert certain confidential, proprietary, and trade secret information of Meridian, including without limitation technical information relating to $($Ctx.Patent) and the Licensed Technology, manufacturing processes, supplier relationships, financial information, and litigation strategy (collectively, "**Confidential Information**");

WHEREAS, the Disclosing Parties require, as a condition of providing access to Confidential Information, that Expert agree to the confidentiality obligations and use restrictions set forth herein;

NOW, THEREFORE, in consideration of the mutual covenants set forth herein and other good and valuable consideration, the Parties hereby agree as follows:

---

## 1. CONFIDENTIAL INFORMATION

### 1.1 Definition

"**Confidential Information**" means all non-public information disclosed by either Disclosing Party to Expert, whether disclosed orally, in writing, electronically, by inspection of tangible objects, or by any other means, and whether or not marked or otherwise designated as confidential. Confidential Information includes, without limitation:

(a) The Technical Package, all engineering drawings, process parameters, formulations, simulation data, test results, and inspection records relating to the Licensed Technology and the '543 Patent;

(b) All non-public communications, work product, and analyses prepared by or for Counsel in connection with the Litigation, including expert work product, attorney mental impressions, and litigation strategy;

(c) All discovery materials produced in the Litigation by any party or non-party, including documents produced under the Stipulated Protective Order entered in the Litigation (the "**Protective Order**");

(d) The financial, commercial, and customer information of Meridian, including pricing, supplier identities, manufacturing volumes, and revenue figures;

(e) The fact, terms, scope, and substance of Expert's engagement and Expert's communications with Counsel.

### 1.2 Exclusions

Confidential Information does not include information that Expert can demonstrate by competent written evidence: (a) was lawfully in Expert's possession without restriction prior to disclosure by a Disclosing Party; (b) is or becomes generally available to the public through no act or omission of Expert; (c) is rightfully received by Expert from a third party who has the right to disclose it without restriction; or (d) is independently developed by Expert without use of or reference to any Confidential Information.

---

## 2. USE AND DISCLOSURE RESTRICTIONS

### 2.1 Permitted Use

Expert shall use Confidential Information solely for the purpose of providing expert consulting and testimony services to Counsel in connection with the Litigation, and for no other purpose whatsoever. Without limiting the foregoing, Expert shall not use Confidential Information:

(a) for the benefit of Expert or any third party;
(b) in connection with any consulting, expert witness, or advisory engagement other than this engagement;
(c) in connection with any current or future litigation, administrative proceeding, or commercial dispute, other than the Litigation;
(d) to advise, counsel, or assist any competitor of Meridian, including Pinnacle Industries, Inc. or any of its affiliates;
(e) to develop, design, manufacture, market, sell, or commercialize any product, process, or service that uses or incorporates any Confidential Information.

### 2.2 No Disclosure

Expert shall not disclose Confidential Information to any person or entity other than (a) the Disclosing Parties, (b) attorneys, paralegals, and staff of Counsel actively engaged in the Litigation, and (c) with the prior written consent of Counsel and subject to the Protective Order, qualified individuals working under Expert's direct supervision who have a demonstrable need to know such information for purposes of supporting Expert's work in the Litigation. Each such individual shall, prior to receiving any Confidential Information, execute the Acknowledgment attached as **Exhibit A** and Counsel shall maintain a list of all such individuals.

### 2.3 Standard of Care

Expert shall protect the Confidential Information using the same degree of care that Expert uses to protect Expert's own most highly confidential information, but in no event less than reasonable care. Expert shall maintain Confidential Information in secure storage (whether physical or electronic), shall use industry-standard practices to prevent unauthorized access, and shall not transmit Confidential Information over any unsecured network.

### 2.4 Protective Order

Expert acknowledges receipt of and shall comply at all times with the Protective Order entered in the Litigation. To the extent of any conflict between this Agreement and the Protective Order, the more restrictive provision shall control.

---

## 3. CONFLICTS AND ENGAGEMENT RESTRICTIONS

### 3.1 No Adverse Engagements

During the Term and for a period of two (2) years thereafter, Expert shall not accept or perform any engagement, consulting arrangement, or expert witness role for or on behalf of Pinnacle Industries, Inc., any affiliate or subsidiary of Pinnacle, or any current or future opposing party in the Litigation, with respect to subject matter relating to the Licensed Technology, the '543 Patent, or the matters at issue in the Litigation.

### 3.2 Disclosure of Conflicts

Expert represents and warrants that Expert has disclosed to Counsel all current and prior consulting engagements, expert witness engagements, employment relationships, and financial interests that could reasonably be considered to create a conflict of interest with the engagement contemplated hereby. Expert shall promptly notify Counsel in writing of any new engagement or relationship that arises during the Term that could create such a conflict.

---

## 4. RETURN AND DESTRUCTION

Upon the earlier of (a) completion of Expert's services, (b) termination of this Agreement, or (c) Counsel's written request, Expert shall promptly: (i) return to Counsel all Confidential Information in tangible form (including all originals and copies); (ii) destroy all electronic copies of Confidential Information (including from email, cloud storage, and backup media); and (iii) certify such destruction in writing to Counsel. Expert may retain one archival copy of Expert's own work product solely for purposes of complying with applicable professional and legal-record-retention obligations, subject to Expert's continuing confidentiality obligations under this Agreement.

---

## 5. TERM AND SURVIVAL

This Agreement shall commence on the Effective Date and shall continue until the later of (a) final resolution of the Litigation (including any appeals) and (b) the date on which Expert has returned or destroyed all Confidential Information. Sections 1, 2, 3, 4, 5, 6, 7, and 8 shall survive any termination or expiration of this Agreement indefinitely.

---

## 6. EQUITABLE RELIEF

Expert acknowledges that any breach of this Agreement would cause Meridian and Counsel irreparable harm for which monetary damages would be an inadequate remedy. Accordingly, in the event of an actual or threatened breach of this Agreement, Meridian and Counsel shall be entitled to seek injunctive and other equitable relief, in addition to any other remedies available at law or in equity, without the requirement of posting a bond or proving actual damages.

---

## 7. MISCELLANEOUS

### 7.1 Governing Law

This Agreement shall be governed by and construed in accordance with the laws of the State of California, without regard to its conflicts-of-law principles. The Parties consent to the exclusive jurisdiction of the federal and state courts located in San Francisco County, California for any action arising under this Agreement.

### 7.2 Entire Agreement

This Agreement, together with the Protective Order and Expert's separate engagement letter with Counsel, constitutes the entire agreement among the Parties with respect to the subject matter hereof and supersedes all prior or contemporaneous understandings, whether oral or written.

### 7.3 Amendments

This Agreement may be amended only by a written instrument signed by all Parties.

### 7.4 No Implied Waiver

No failure or delay by any Party in exercising any right under this Agreement shall constitute a waiver of such right. No single or partial exercise of any right shall preclude any other or further exercise of such right.

### 7.5 Severability

If any provision of this Agreement is held invalid or unenforceable, the remainder shall continue in full force and effect, and the invalid or unenforceable provision shall be reformed to the minimum extent necessary to render it valid and enforceable while preserving the Parties' original intent.

### 7.6 Counterparts

This Agreement may be executed in counterparts, each of which shall constitute an original and all of which together shall constitute one and the same instrument. Electronic signatures shall be deemed valid and binding.

---

## SIGNATURES

IN WITNESS WHEREOF, the Parties have executed this Agreement as of the Effective Date.

**MERIDIAN CORPORATION**

By: ______________________________
Name: $($Ctx.ClientContact.Name)
Title: $($Ctx.ClientContact.Title)
Date: ____________________________


**$($Ctx.PlaintiffFirm.ToUpper())**

By: ______________________________
Name: $($Ctx.LeadCounselP.Name)
Title: $($Ctx.LeadCounselP.Title)
Date: ____________________________


**$($expertName.ToUpper())**

By: ______________________________
Name: $expertName
Date: ____________________________

---

**EXHIBIT A — Acknowledgment of Subordinate Personnel**

The undersigned hereby acknowledges receipt of a copy of this Expert Witness Confidentiality and Non-Disclosure Agreement, has read and understood the obligations set forth herein, and agrees to be bound by the same in connection with any work performed in support of Expert's engagement.

Signature: ______________________________
Name: __________________________________
Date: ___________________________________

---

*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-TerminationNoticeContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference
    $dates   = $Doc.sprk_extractdates
    $effectiveDate = if ($dates) { ($dates -split "[`n,]")[0].Trim() } else { 'the date of this notice' }

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# NOTICE OF TERMINATION OF MASTER SERVICES AGREEMENT

**Date:** $effectiveDate

**By Hand Delivery and Email**

Mr. Thomas R. Wright
Chief Executive Officer
PINNACLE INDUSTRIES, INC.
1200 Innovation Boulevard
Fremont, California 94538
Email: thomas.wright@example.com

cc: General Counsel, Pinnacle Industries, Inc.
    Chen Law Group (counsel for Pinnacle)

---

**Re:** Termination of Master Services Agreement dated January 15, 2023 (MSA-2023-0147), as amended; Termination of Technology License Agreement dated March 8, 2023 (TLA-2023-0032), as amended; Cease and Desist Demand

Dear Mr. Wright:

This letter constitutes formal written notice from Meridian Corporation ("**Meridian**") to Pinnacle Industries, Inc. ("**Pinnacle**") of Meridian's termination of the Master Services Agreement dated January 15, 2023 between Meridian and Pinnacle, as amended (the "**MSA**"), and the Technology License Agreement dated March 8, 2023 between Meridian and Pinnacle, as amended (the "**TLA**"), in each case for material breach. This letter further constitutes a formal demand that Pinnacle immediately cease and desist all activities described below.

## 1. Background

$summary

## 2. Material Breaches by Pinnacle

Meridian terminates the MSA pursuant to Section 10.2(a) thereof, and the TLA pursuant to Section 10.2(a) thereof, each based on the following material, uncured breaches:

**(a) Unauthorized Use of Licensed Technology Outside the Authorized Field.** Pinnacle has incorporated the Licensed Technology, including process parameters and tooling-design know-how exclusive to Meridian's precision-manufacturing program, into its commercial "AutoForge Multi-Stage Compression Platform" product line, which Pinnacle is marketing and selling to third-party customers. This use is plainly outside the limited Authorized Field defined in Section 4.3 of the TLA (as clarified in the Amendment thereto dated September 3, 2024) and is in direct violation of the use restrictions set forth in Section 4.3 of the TLA and Section 4.2 of the SOWs entered into thereunder.

**(b) Failure to Cease Use After Notice.** By letter dated July 22, 2025, Meridian notified Pinnacle in writing of the foregoing unauthorized use and demanded that Pinnacle immediately cease all unauthorized use of the Licensed Technology, in accordance with the cure-period provisions of Section 10.1 of the TLA. The cure period expired without Pinnacle ceasing such use, declining to suspend marketing of the AutoForge product, declining to recall units already in the field, and declining to provide an audit-supported accounting of unauthorized sales.

**(c) Refusal of Audit Rights.** Meridian's representatives requested, in writing on August 14, 2025 and again on August 28, 2025, to exercise the audit rights set forth in Section 9.6 of the TLA (added by Amendment dated September 3, 2024) for the limited purpose of inspecting Pinnacle's manufacturing records and product samples. Pinnacle refused to permit such audit, in further breach of its obligations.

**(d) Disclosure of Confidential Information to Third Parties.** Pinnacle has disclosed Meridian's Confidential Information, including elements of the Technical Package and proprietary process parameters, to its supply-chain partners and OEM customers in connection with the manufacture and marketing of the AutoForge product, in breach of Section 9 (Confidentiality) of each of the MSA and the TLA.

## 3. Effective Date of Termination

$tldr

The MSA and the TLA are each terminated effective immediately upon Pinnacle's receipt of this letter. All licenses granted to Pinnacle under the TLA are hereby revoked, and Pinnacle has no further right, license, or authorization to use the Licensed Technology, the Technical Package, the '543 Patent, or any other Meridian intellectual property for any purpose.

## 4. Cease and Desist; Demands

Meridian hereby demands that Pinnacle, within five (5) business days of receipt of this letter:

(i) cease and desist all manufacture, marketing, sale, distribution, and use of the AutoForge Multi-Stage Compression Platform and any other product, process, or service that incorporates, uses, or derives from the Licensed Technology;

(ii) recall all units of the AutoForge Multi-Stage Compression Platform that have been distributed to third parties and provide written confirmation of such recall;

(iii) provide a complete written accounting of all units of the AutoForge product manufactured, marketed, or sold by Pinnacle since January 1, 2024, including units, customers, prices, and revenue;

(iv) return to Meridian all originals and copies (whether tangible or electronic) of the Technical Package, the engineering drawings, the process parameters, and all other Confidential Information of Meridian in Pinnacle's possession or control, and certify destruction of all electronic copies that cannot be returned;

(v) provide written confirmation that Pinnacle has destroyed all tooling, fixtures, and equipment used in connection with the unauthorized use of the Licensed Technology, or has segregated and secured the same pending Meridian's instructions; and

(vi) preserve, and not destroy, alter, or modify, all documents, communications, electronic records, manufacturing records, financial records, supplier records, and customer records relating to the Licensed Technology and the AutoForge product, pending resolution of the disputes between the parties.

## 5. Reservation of Rights

Meridian expressly reserves all rights, claims, defenses, and remedies it has or may have against Pinnacle arising out of or relating to the breaches described above and any other breaches of the MSA, the TLA, or any related agreement, including without limitation claims for patent infringement, breach of contract, breach of confidentiality, misappropriation of trade secrets, unfair competition, and tortious interference. Meridian's election to terminate the MSA and the TLA shall not be construed as a waiver or release of any such rights, claims, defenses, or remedies, all of which are expressly preserved. Meridian intends to commence litigation if Pinnacle does not promptly comply with the demands set forth in Section 4 of this letter.

## 6. Provisions Surviving Termination

Notwithstanding termination of the MSA and the TLA, the provisions of those agreements that by their terms survive termination shall remain in full force and effect, including without limitation provisions relating to confidentiality, intellectual property ownership, indemnification, limitations of liability, audit rights, and dispute resolution.

## 7. Communications Going Forward

All further communications regarding this matter should be directed to Meridian's outside counsel:

$($Ctx.LeadCounselP.Name), Esq.
$($Ctx.LeadCounselP.Title)
$($Ctx.LeadCounselP.Firm)
$($Ctx.LeadCounselP.Address)
$($Ctx.LeadCounselP.Phone)
$($Ctx.LeadCounselP.Email)

Sincerely,

________________________________
$($Ctx.ClientContact.Name)
$($Ctx.ClientContact.Title)
MERIDIAN CORPORATION

---

*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-ContractContent {
    # Generic fallback for contracts not matching a more specific template.
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference
    $dates   = $Doc.sprk_extractdates
    $effectiveDate = if ($dates) { ($dates -split "[`n,]")[0].Trim() } else { 'the date last signed below' }

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# $name

**Effective Date:** $effectiveDate

---

## PARTIES

This agreement is entered into between **MERIDIAN CORPORATION** and **PINNACLE INDUSTRIES, INC.** as of the Effective Date.

## RECITALS

WHEREAS, $tldr;

NOW, THEREFORE, the parties agree as follows.

## TERMS

$summary

## SIGNATURES

**MERIDIAN CORPORATION**

By: ______________________________
Name: $($Ctx.ClientContact.Name)
Title: $($Ctx.ClientContact.Title)


**PINNACLE INDUSTRIES, INC.**

By: ______________________________
Name: Thomas R. Wright
Title: Chief Executive Officer

---

*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}
