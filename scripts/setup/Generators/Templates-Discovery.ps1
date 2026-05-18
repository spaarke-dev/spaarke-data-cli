# =============================================================================
# Templates-Discovery.ps1
# Discovery: Interrogatories, RFPs, Privilege Logs, Production Cover Letters.
# =============================================================================

function New-InterrogatoriesContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference

    # Determine which side is propounding
    $isPlaintiff = $Doc.sprk_filename -match 'plaintiff'
    if ($isPlaintiff) {
        $propParty   = 'PLAINTIFF MERIDIAN CORPORATION'
        $respParty   = 'DEFENDANT PINNACLE INDUSTRIES, INC.'
        $propFirm    = $Ctx.PlaintiffFirm.ToUpper()
        $propCounsel = $Ctx.LeadCounselP
        $accusedProd = "the AutoForge Multi-Stage Compression Platform (the ""AutoForge"")"
        $perspective = 'Plaintiff'
    } else {
        $propParty   = 'DEFENDANT PINNACLE INDUSTRIES, INC.'
        $respParty   = 'PLAINTIFF MERIDIAN CORPORATION'
        $propFirm    = $Ctx.DefendantFirm.ToUpper()
        $propCounsel = $Ctx.LeadCounselD
        $accusedProd = $Ctx.Patent
        $perspective = 'Defendant'
    }

@"
$(Format-CaseCaption -Title "$perspective'S FIRST SET OF INTERROGATORIES TO $respParty")

PROPOUNDING PARTY: $propParty
RESPONDING PARTY:  $respParty
SET NUMBER:        ONE (1)

Pursuant to Federal Rules of Civil Procedure 26 and 33, $propParty ("$perspective") hereby propounds the following interrogatories to $respParty, to be answered separately and fully, in writing and under oath, within thirty (30) days of service.

## DEFINITIONS AND INSTRUCTIONS

The Definitions and Instructions set forth in $perspective's First Request for Production of Documents, served concurrently herewith, are incorporated by reference and apply with equal force to these Interrogatories.

For purposes of these Interrogatories:

**"You"** and **"Your"** refer to $respParty, including its officers, directors, employees, agents, attorneys, accountants, consultants, predecessors, successors, parents, subsidiaries, and affiliates.

**"Identify"** when used in reference to a person means to state the person's full name, last known address, last known telephone number, and current or most recent position and employer. **"Identify"** when used in reference to a document means to state the document's date, author, recipient(s), title or subject, and bates number (if produced).

**"Communication"** means any transmission of information, in any form (oral, written, electronic, or otherwise), between two or more persons.

## INTERROGATORIES

### INTERROGATORY NO. 1

Identify each person who has knowledge of the facts and circumstances surrounding the design, development, engineering, testing, manufacture, marketing, or sale of $accusedProd, and for each such person, state in detail the subject matter of that person's knowledge.

### INTERROGATORY NO. 2

Identify all documents reflecting communications between You and any third party regarding $accusedProd between January 1, 2024 and the present, including without limitation communications with current or prospective customers, suppliers, distributors, sales representatives, contractors, and consultants.

### INTERROGATORY NO. 3

State in complete detail the design history of $accusedProd, identifying for each design or engineering decision: (a) the date the decision was made; (b) the persons involved in making the decision; (c) the substance of the decision; (d) the technical or business basis for the decision; and (e) all documents reflecting the decision.

### INTERROGATORY NO. 4

Identify all individuals (whether or not currently employed by You) who, during the period from January 1, 2023 to the present, contributed to the design, development, or engineering of $accusedProd, and for each such individual, state: (a) the period of contribution; (b) the nature of the contribution; (c) the position the individual held during that period; and (d) whether the individual signed any agreement governing intellectual property, confidentiality, or assignment of inventions.

### INTERROGATORY NO. 5

Describe in complete detail the process control system used in the manufacture of $accusedProd, including but not limited to: (a) all process parameters that are monitored or controlled; (b) all sensor types and locations; (c) the control algorithm or strategy employed; and (d) any feedback or feedforward control mechanisms.

### INTERROGATORY NO. 6

Identify each instance during the period January 1, 2023 to the present in which You accessed, reviewed, or otherwise made use of any document, drawing, specification, model, simulation, or other technical material that originated with or was provided by Meridian, including the date of access, the persons involved, the purpose of access, and the disposition of the material.

### INTERROGATORY NO. 7

State in detail the basis for each affirmative defense You assert in this Action, including the factual basis, the documents that support each defense, and the persons with knowledge of facts supporting each defense.

### INTERROGATORY NO. 8

For each invention claim of $accusedProd that You contend was independently developed without use of any Confidential Information of Meridian, identify: (a) the originator of the inventive concept; (b) the date of conception; (c) all documents corroborating the date and circumstances of conception; (d) the date of reduction to practice; and (e) all documents corroborating the date and circumstances of reduction to practice.

### INTERROGATORY NO. 9

Identify all communications between You and any of Your employees, agents, or representatives regarding the use of any Meridian intellectual property, including but not limited to communications interpreting the scope of the Technology License Agreement (TLA-2023-0032) or the Statements of Work entered thereunder.

### INTERROGATORY NO. 10

State Your gross revenue, net revenue, profits (gross and net), and unit volumes for $accusedProd for each calendar quarter from Q1 2024 through the most recent completed quarter, and identify all documents reflecting such information.

### INTERROGATORY NO. 11

Identify each customer or prospective customer to whom You have marketed, demonstrated, sold, or proposed to sell $accusedProd, including for each: (a) the customer name; (b) the date(s) of contact; (c) the substance of communications; and (d) the disposition (closed sale, lost sale, pending, etc.).

### INTERROGATORY NO. 12

Describe in detail any analyses, evaluations, opinions, or assessments You commissioned, prepared, or received regarding whether $accusedProd practices any claim of $($Ctx.Patent) or any other Meridian patent, including the dates, authors, conclusions, and disposition of each such analysis. (For the avoidance of doubt, this Interrogatory does not seek information protected by the attorney-client privilege; please identify any responsive communications and produce a privilege log.)

### INTERROGATORY NO. 13

Identify all licenses, royalty agreements, supply agreements, joint development agreements, and other commercial agreements relating to $accusedProd or the technology incorporated therein, between You and any third party, since January 1, 2023.

### INTERROGATORY NO. 14

Describe Your document retention and litigation hold policies, including: (a) the date Your litigation hold relating to this Action was issued; (b) the custodians to whom the hold was distributed; (c) the categories of documents subject to the hold; and (d) all steps taken to preserve documents and electronically stored information ("ESI") relating to this Action.

### INTERROGATORY NO. 15

Identify each expert witness You currently anticipate calling at trial in this Action, and for each expert: (a) the expert's name and qualifications; (b) the subject matter on which the expert is expected to testify; (c) the date the expert was retained; and (d) the nature and amount of the expert's compensation.

---

## REQUEST FOR ANSWERS UNDER OATH

You are required to answer each of the foregoing Interrogatories separately and fully in writing under oath, within thirty (30) days after service. If you object to any Interrogatory, in whole or in part, you must state with specificity the grounds for the objection and answer the Interrogatory to the extent it is not objectionable.

---

Dated: October 1, 2025

Respectfully submitted,

$propFirm

By: ______________________________
$($propCounsel.Name), Esq.
$($propCounsel.Title)
$($propCounsel.Address)
$($propCounsel.Phone)
$($propCounsel.Email)

*Attorneys for $propParty*

---

## CERTIFICATE OF SERVICE

I hereby certify that on October 1, 2025, I caused a true and correct copy of the foregoing $perspective's First Set of Interrogatories to be served on counsel for the responding party by electronic mail.

______________________________
$($propCounsel.Name)

---

*$tldr*
*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-RequestForProductionContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference

    $isPlaintiff = $Doc.sprk_filename -match 'plaintiff'
    if ($isPlaintiff) {
        $propParty   = 'PLAINTIFF MERIDIAN CORPORATION'
        $respParty   = 'DEFENDANT PINNACLE INDUSTRIES, INC.'
        $propFirm    = $Ctx.PlaintiffFirm.ToUpper()
        $propCounsel = $Ctx.LeadCounselP
        $perspective = 'Plaintiff'
    } else {
        $propParty   = 'DEFENDANT PINNACLE INDUSTRIES, INC.'
        $respParty   = 'PLAINTIFF MERIDIAN CORPORATION'
        $propFirm    = $Ctx.DefendantFirm.ToUpper()
        $propCounsel = $Ctx.LeadCounselD
        $perspective = 'Defendant'
    }

@"
$(Format-CaseCaption -Title "$perspective'S FIRST REQUEST FOR PRODUCTION OF DOCUMENTS TO $respParty")

PROPOUNDING PARTY: $propParty
RESPONDING PARTY:  $respParty
SET NUMBER:        ONE (1)

Pursuant to Federal Rules of Civil Procedure 26 and 34, $propParty ("$perspective") hereby requests that $respParty produce the documents and electronically stored information ("ESI") described below for inspection and copying within thirty (30) days of service, at the offices of undersigned counsel or by such other means as the parties may agree.

## DEFINITIONS

**"Document"** means any written, recorded, or graphic matter, however produced or reproduced, of any kind or description, including without limitation electronic mail, text messages, instant messages, voicemails, slide decks, spreadsheets, drawings, schematics, source code, design files, simulation files, photographs, audio and video recordings, and metadata.

**"You"** and **"Your"** refer to $respParty, including all officers, directors, employees, agents, attorneys, consultants, predecessors, successors, parents, subsidiaries, and affiliates.

**"Communication"** means any transmission of information.

**"Concerning"** means relating to, referring to, regarding, mentioning, evidencing, or having any connection to.

**"AutoForge"** refers to the AutoForge Multi-Stage Compression Platform marketed by Pinnacle Industries, Inc., and any predecessor or successor product designated by a different name but embodying substantially similar technology.

**"Licensed Technology"** has the meaning given in the Technology License Agreement dated March 8, 2023.

**"Technical Package"** has the meaning given in the Master Services Agreement dated January 15, 2023, including all exhibits and updates thereto.

**"Relevant Period"** means January 1, 2022 through the date of production, unless a particular Request specifies a different period.

## INSTRUCTIONS

1. These Requests are continuing in nature. Documents responsive to these Requests but not yet in existence at the time of initial production must be produced when they come into existence or come into Your possession, custody, or control.

2. ESI must be produced in single-page TIFF format with extracted text, metadata, and load files in industry-standard format (Concordance / Opticon), unless the parties agree otherwise. Native files must be produced for spreadsheets, presentations, and any document for which TIFF is unsuitable.

3. Hard-copy documents must be produced as searchable PDFs.

4. If You withhold any responsive document on the basis of attorney-client privilege, work-product doctrine, or any other privilege or immunity, You must produce a privilege log identifying each document withheld in accordance with Federal Rule of Civil Procedure 26(b)(5)(A).

5. If You contend that any Request is objectionable, You must state with specificity the grounds for the objection and produce all documents to which the objection does not apply.

## REQUESTS FOR PRODUCTION

**Request No. 1.** All documents identified in or used in preparing Your responses to $perspective's First Set of Interrogatories.

**Request No. 2.** Each version of any document setting forth the technical specifications of AutoForge or any of its predecessor designs, including all engineering drawings, CAD files, simulation files, materials specifications, process parameters, and tolerance specifications.

**Request No. 3.** All documents concerning the conception, design, or development of AutoForge from initial concept through commercial release, including all design notebooks, engineering meeting minutes, design review presentations, prototype test results, and decision memoranda.

**Request No. 4.** All documents concerning Your access to, use of, copying of, or reference to the Licensed Technology, the Technical Package, or any other Confidential Information of Meridian.

**Request No. 5.** All communications, internal or external, concerning AutoForge during the Relevant Period, including emails, text messages, chat messages (Slack, Teams, etc.), and meeting notes.

**Request No. 6.** All communications between You and any of Your suppliers concerning AutoForge or the manufacture thereof, including specifications, drawings, or process information provided to such suppliers.

**Request No. 7.** All communications between You and any current or prospective customer concerning AutoForge.

**Request No. 8.** All sales, marketing, and promotional materials concerning AutoForge, including data sheets, white papers, product brochures, presentations, advertisements, conference papers, and trade-show materials.

**Request No. 9.** Documents sufficient to show, by month, the unit volumes manufactured, the unit volumes sold, the gross revenue, the cost of goods sold, the gross profit, and the net profit attributable to AutoForge from Q1 2024 through the date of production.

**Request No. 10.** Each customer purchase order, invoice, contract, or quotation issued in connection with AutoForge.

**Request No. 11.** All documents concerning Your interpretation, internal communications about, or instructions to employees concerning the scope of authorized use of the Licensed Technology under the TLA, the MSA, or any SOW thereunder.

**Request No. 12.** All documents concerning analyses, opinions, or evaluations of whether AutoForge practices any claim of $($Ctx.Patent), including any opinion-of-counsel analysis (subject to a privilege log).

**Request No. 13.** All documents concerning Your litigation hold relating to this Action, including the hold notice itself, distribution lists, acknowledgments, and follow-up reminders.

**Request No. 14.** All documents reflecting any analysis, valuation, or projection of the financial impact of AutoForge on Your business, including business plans, strategic plans, board presentations, and budget materials.

**Request No. 15.** All non-privileged communications between You and any third party (including consultants, contractors, attorneys retained for non-litigation purposes, and accountants) concerning AutoForge, the Licensed Technology, or this Action.

**Request No. 16.** All documents concerning the qualifications, prior testimony, retention, compensation, and work product of any expert You have retained or anticipate calling in this Action.

**Request No. 17.** All documents concerning Your insurance coverage applicable to the claims and counterclaims in this Action.

[Requests 18 through 75 omitted in this excerpt; full set served on October 1, 2025.]

## CERTIFICATE OF SERVICE

I hereby certify that on October 1, 2025, I caused a true and correct copy of the foregoing $perspective's First Request for Production of Documents to be served on counsel for the responding party by electronic mail.

---

Dated: October 1, 2025

Respectfully submitted,

$propFirm

By: ______________________________
$($propCounsel.Name), Esq.
$($propCounsel.Title)
$($propCounsel.Address)
$($propCounsel.Phone)
$($propCounsel.Email)

*Attorneys for $propParty*

---

*$tldr*
*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-PrivilegeLogContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# PRIVILEGE LOG

**Matter:** $($Ctx.Caption)
**Case No.:** $($Ctx.CaseNumber)
**Producing Party:** Pinnacle Industries, Inc.
**Production Date:** December 22, 2025
**Bates Range Withheld:** PIN-PRIV-000001 through PIN-PRIV-000384

---

## INTRODUCTION

Pursuant to Federal Rule of Civil Procedure 26(b)(5)(A) and the Stipulated Protective Order entered in this action (Dkt. 64), Pinnacle Industries, Inc. ("Pinnacle") submits this Privilege Log identifying documents withheld from production on the basis of the attorney-client privilege, the attorney work-product doctrine, the common-interest privilege, and/or the joint-defense privilege.

$summary

This log covers documents withheld from Pinnacle's production responsive to Plaintiff's First Request for Production of Documents (served October 1, 2025) and Plaintiff's Second Request for Production of Documents (served November 7, 2025). Pinnacle reserves the right to supplement this log as additional responsive documents are identified.

## KEY FOR PRIVILEGE BASIS

- **AC** = Attorney-Client Privilege
- **WP** = Attorney Work Product
- **CI** = Common Interest Privilege
- **JD** = Joint Defense Privilege

## ABBREVIATIONS

- **PIN** = Pinnacle Industries, Inc.
- **CLG** = Chen Law Group (outside counsel for Pinnacle)
- **WD** = Wright/Defense Internal Counsel

## LOG ENTRIES

| Bates No.        | Date       | Author                  | Recipient(s)                   | Type   | Subject / Description                                                                                              | Privilege |
|------------------|------------|-------------------------|--------------------------------|--------|--------------------------------------------------------------------------------------------------------------------|-----------|
| PIN-PRIV-000001  | 2025-08-15 | David Kim (CLG)         | Thomas Wright (PIN)            | Email  | Legal advice regarding Meridian cease-and-desist letter dated July 22, 2025                                        | AC, WP    |
| PIN-PRIV-000002  | 2025-08-16 | Thomas Wright (PIN)     | David Kim (CLG)                | Email  | Request for legal advice on response strategy to Meridian cease-and-desist                                         | AC        |
| PIN-PRIV-000003  | 2025-08-18 | Sarah Mitchell (CLG)    | Thomas Wright (PIN)            | Email  | Memorandum regarding TLA scope of license interpretation                                                            | AC, WP    |
| PIN-PRIV-000004  | 2025-08-22 | Thomas Wright (PIN)     | Robert Chang (PIN, GC)         | Email  | Forwarding outside counsel advice; internal counsel impressions                                                     | AC, WP    |
| PIN-PRIV-000005  | 2025-08-25 | David Kim (CLG)         | Robert Chang (PIN, GC)         | Email  | Discussion of preliminary defense strategy and possible counterclaims                                               | AC, WP    |
| PIN-PRIV-000006  | 2025-09-02 | Sarah Mitchell (CLG)    | David Kim (CLG)                | Memo   | Internal CLG analysis of patent invalidity defenses                                                                 | WP        |
| PIN-PRIV-000007  | 2025-09-04 | Robert Chang (PIN, GC)  | David Kim (CLG); CLG team      | Email  | Confidential settlement analysis prepared at request of counsel                                                     | AC, WP    |
| PIN-PRIV-000008  | 2025-09-08 | David Kim (CLG)         | Thomas Wright (PIN); R. Chang  | Memo   | Litigation hold instructions and document preservation recommendations                                              | AC, WP    |
| PIN-PRIV-000009  | 2025-09-10 | Robert Chang (PIN, GC)  | All Pinnacle department heads  | Email  | Litigation hold notice issued at direction of counsel                                                               | AC, WP    |
| PIN-PRIV-000010  | 2025-09-12 | David Kim (CLG)         | Robert Chang (PIN, GC)         | Email  | Confidential analysis of damages exposure                                                                            | AC, WP    |
| PIN-PRIV-000011  | 2025-09-15 | Sarah Mitchell (CLG)    | David Kim (CLG); CLG associate | Memo   | Draft answer and counterclaim outline                                                                                | WP        |
| PIN-PRIV-000012  | 2025-09-18 | David Kim (CLG)         | Thomas Wright (PIN)            | Memo   | Strategic recommendations regarding response to complaint                                                            | AC, WP    |
| PIN-PRIV-000013  | 2025-09-20 | Robert Chang (PIN, GC)  | Thomas Wright (PIN)            | Email  | Internal counsel review of outside counsel strategic recommendations                                                 | AC, WP    |
| PIN-PRIV-000014  | 2025-09-22 | David Kim (CLG)         | Patricia Foster (CLG, paralegal)| Email | Direction to begin assembly of prior art for invalidity defense                                                      | WP        |
| PIN-PRIV-000015  | 2025-09-25 | Patricia Foster (CLG)   | David Kim (CLG)                | Email  | Compilation of prior art search results and preliminary analysis                                                     | WP        |
| PIN-PRIV-000016  | 2025-09-28 | David Kim (CLG)         | Thomas Wright (PIN); R. Chang  | Email  | Recommendations regarding possible expert witnesses and conflict screening                                           | AC, WP    |
| ...              | ...        | ...                     | ...                            | ...    | ...                                                                                                                  | ...       |
| PIN-PRIV-000384  | 2026-02-12 | Sarah Mitchell (CLG)    | David Kim (CLG)                | Memo   | Pre-claim-construction-hearing strategy assessment                                                                   | WP        |

(Entries 17-383 omitted from this excerpt; complete log produced concurrently in spreadsheet form.)

## NOTES

1. Communications among Chen Law Group attorneys reflecting their mental impressions, conclusions, opinions, and legal theories regarding this Action are withheld as attorney work product.

2. Communications between Pinnacle's in-house counsel and Pinnacle's outside counsel made for the purpose of obtaining or providing legal advice are withheld as attorney-client privileged.

3. Communications between Pinnacle's in-house counsel and Pinnacle's officers and employees concerning legal advice provided by counsel are withheld as attorney-client privileged.

4. No documents created prior to August 15, 2025 are withheld on the basis of any litigation-related privilege; communications with counsel regarding the underlying contractual relationships have been produced.

---

*$tldr*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-ProductionCoverLetterContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr

    $isMeridian = $Doc.sprk_filename -match 'meridian'
    if ($isMeridian) {
        $producingParty = 'Meridian Corporation'
        $producingFirm  = $Ctx.PlaintiffFirm
        $producingCounsel = $Ctx.LeadCounselP
        $receivingFirm  = $Ctx.DefendantFirm
        $receivingCounsel = $Ctx.LeadCounselD
        $batesPrefix    = 'MER'
        $perspective = "Plaintiff Meridian"
    } else {
        $producingParty = 'Pinnacle Industries, Inc.'
        $producingFirm  = $Ctx.DefendantFirm
        $producingCounsel = $Ctx.LeadCounselD
        $receivingFirm  = $Ctx.PlaintiffFirm
        $receivingCounsel = $Ctx.LeadCounselP
        $batesPrefix    = 'PIN'
        $perspective = "Defendant Pinnacle"
    }

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# $($producingFirm.ToUpper())
$($producingCounsel.Address)
$($producingCounsel.Phone)

---

December 22, 2025

**By Federal Express and Email**

$($receivingCounsel.Name), Esq.
$receivingFirm
$($receivingCounsel.Address)
$($receivingCounsel.Email)

**Re:** $($Ctx.Caption); Case No. $($Ctx.CaseNumber); $producingParty's First Production of Documents

Dear $($receivingCounsel.Name.Split(' ')[1]):

Please find enclosed the first production of documents from $producingParty in the above-captioned matter, in response to $(if ($isMeridian) { 'Defendant Pinnacle Industries, Inc.' } else { 'Plaintiff Meridian Corporation' })'s First Request for Production of Documents served October 1, 2025.

## Production Details

- **Bates Range:** $batesPrefix-000001 through $batesPrefix-024,768
- **Total Documents Produced:** 4,247 documents (24,768 pages)
- **Format:** Single-page TIFF with extracted text, metadata, and Concordance / Opticon load files, on encrypted USB media (one copy each by FedEx; load files also transmitted via secure FTP)
- **Confidentiality Designations:** Documents are designated under the Stipulated Protective Order (Dkt. 64) as follows:
  - Public: 1,892 documents
  - Confidential: 1,876 documents
  - Highly Confidential — Attorneys' Eyes Only: 479 documents

## Subject Matter Coverage

$summary

This first production includes documents responsive to RFP Nos. 1-12, 16-21, 28-30, 33-37, 43-48, 50-52, 59-64, 66, and 68-75. Production responsive to RFP Nos. 13-15, 22-27, 31-32, 38-42, 49, 53-58, 65, and 67 is forthcoming and will be made on a rolling basis pursuant to the schedule we discussed on November 11, 2025, with substantial completion by January 30, 2026.

## Privilege Log

A privilege log identifying documents withheld from this production on the basis of the attorney-client privilege, attorney work-product doctrine, and other applicable privileges is enclosed as Attachment A. The log identifies $(if ($isMeridian) { '291' } else { '384' }) documents withheld in their entirety from this first production.

## Foundational and Authentication Documents

In addition to the documents responsive to specific Requests, the following foundational documents are produced as part of this first production:

1. The Master Services Agreement dated January 15, 2023, with all amendments (Bates $batesPrefix-000001 through $batesPrefix-000094);
2. The Technology License Agreement dated March 8, 2023, with all amendments (Bates $batesPrefix-000095 through $batesPrefix-000168);
3. The Statements of Work executed pursuant to the MSA, with all amendments (Bates $batesPrefix-000169 through $batesPrefix-000412);
4. Litigation hold notice issued by $producingParty (Bates $batesPrefix-000413 through $batesPrefix-000418, partially redacted on the basis of attorney-client privilege).

## Reservation of Objections

This production is made expressly subject to and without waiver of $producingParty's objections to the Requests, as set forth in $producingParty's written responses dated October 31, 2025. To the extent any document is produced that may be argued to be outside the scope of any Request, such production is not intended as and shall not constitute a waiver of any objection.

## Continuing Obligation

$producingParty acknowledges its continuing obligation to supplement this production as additional responsive documents come into its possession, custody, or control. $producingParty will provide rolling supplemental productions as additional responsive documents are identified, with the next supplemental production scheduled for January 9, 2026.

Please contact me if you have any questions regarding this production or wish to discuss the format, the privilege log, or the timing of forthcoming productions.

Sincerely,

________________________________
$($producingCounsel.Name), Esq.
$($producingCounsel.Title)
$producingFirm

cc: $(if ($isMeridian) { $Ctx.ClientContact.Name } else { 'Robert Chang, General Counsel, Pinnacle Industries, Inc.' })

---

**Enclosures:**
- Attachment A: Privilege Log
- Encrypted USB drive (by separate FedEx delivery)
- Decryption key (by separate secure email)

---

*$tldr*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}
