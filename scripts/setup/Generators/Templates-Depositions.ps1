# =============================================================================
# Templates-Depositions.ps1
# Deposition transcripts (excerpt format).
# =============================================================================

function New-DepositionContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference
    $dates   = $Doc.sprk_extractdates
    $depDate = if ($dates) { ($dates -split "[`n,]")[0].Trim() } else { '____, 2026' }

    # Identify the deponent
    $deponent = if ($name -match '— ([^(]+)') { $Matches[1].Trim() } elseif ($name -match '- ([^(]+)') { $Matches[1].Trim() } else { 'the witness' }
    $role = if ($name -match '\(([^)]+)\)') { $Matches[1].Trim() } else { '' }

    # Determine who is taking the deposition based on role
    $isMeridianWitness = $role -match 'Meridian|Plaintiff Expert'
    if ($isMeridianWitness) {
        $taking      = 'Counsel for Pinnacle (Mr. Kim)'
        $defending   = 'Counsel for Meridian (Ms. Torres)'
        $takingShort = 'Q'
        $favorParty  = 'Pinnacle'
    } else {
        $taking      = 'Counsel for Meridian (Ms. Torres)'
        $defending   = 'Counsel for Pinnacle (Mr. Kim)'
        $takingShort = 'Q'
        $favorParty  = 'Meridian'
    }

    # Determine examination focus by role
    $isExpert = $role -match 'Expert'
    $isInHouse = $role -match 'In-House'
    $isExec = $role -match 'CEO|VP'

@"
$(Format-CaseCaption -Title "VIDEOTAPED DEPOSITION OF $($deponent.ToUpper())")

DATE TAKEN:    $depDate
TIME:          9:30 a.m. - 5:15 p.m.
LOCATION:      Offices of Baker & Associates LLP
               555 Market Street, Suite 2400
               San Francisco, California 94105
REPORTED BY:   Margaret L. Whitman, CSR No. 9847, RPR

---

## APPEARANCES

For Plaintiff Meridian Corporation:
  $($Ctx.LeadCounselP.Name), Esq.
  Daniel Crawford, Esq. (Senior Associate)
  $($Ctx.PlaintiffFirm)

For Defendant Pinnacle Industries, Inc.:
  $($Ctx.LeadCounselD.Name), Esq.
  Sarah Mitchell, Esq.
  $($Ctx.DefendantFirm)

For the Witness:
  Same as the party-aligned counsel above.

Also Present:
  Patricia Foster, Senior Paralegal (Chen Law Group)
  Andrew Reyes, Videographer (CourtSync Litigation Services)

---

## EXECUTIVE SUMMARY OF KEY TESTIMONY

$summary

The deposition lasted approximately 7.5 hours of on-the-record testimony, comprising direct examination by $taking and limited cross-examination by $defending. Key admissions and notable testimony are excerpted below; a full transcript spanning 287 pages is on file.

---

## EXAMINATION EXCERPTS

### I. Background and Qualifications (Pages 8-31)

The witness testified to $(if ($isExpert) { 'his/her professional qualifications, prior expert engagements, and the basis for opinions to be offered in this matter' } elseif ($isExec) { 'his/her current role at the company, tenure, reporting structure, and scope of decision-making authority' } elseif ($isInHouse) { 'her role as in-house counsel, her professional qualifications, and the scope of her involvement in matters relevant to this litigation' } else { 'his/her current and prior roles at the company and the scope of his/her responsibilities in matters relevant to this case' }).

**Q (Page 12, Line 8):** Please state your full name and current title for the record.

**A:** My name is $deponent. $(if ($isExpert) { 'I am an independent consulting engineer specializing in precision manufacturing processes, with particular expertise in thermal compression molding.' } elseif ($isInHouse) { 'I am General Counsel and Corporate Secretary of Pinnacle Industries, Inc.' } else { 'I currently serve as ' + $role + ' at the company.' })

**$takingShort (Page 14, Line 22):** Could you describe your educational background?

**A:** $(if ($isExpert) { 'I hold a Ph.D. in Materials Science and Engineering from MIT, an M.S. in Mechanical Engineering from Stanford, and a B.S. in Materials Engineering from UC Berkeley. My doctoral research focused on phase transformations in compression-molded polymer composites.' } elseif ($isExec) { 'I hold a B.S. in Mechanical Engineering from Cal Poly San Luis Obispo and an M.B.A. from the Haas School of Business at UC Berkeley.' } else { 'I have a B.S. in Engineering and approximately twenty years of industry experience, the last twelve years of which have been with the company.' })

### II. Knowledge of the Licensed Technology (Pages 32-78)

The witness was examined extensively regarding $(if ($isExpert) { 'the technical content of the Licensed Technology and the bases for the opinions set forth in his/her expert report' } else { 'his/her knowledge of, access to, and use of the Licensed Technology and the Technical Package provided by Meridian under the MSA and TLA' }).

**Q (Page 34, Line 17):** Are you familiar with United States Patent No. 9,876,543?

**A:** Yes, I have reviewed the '543 Patent in detail. $(if ($isExpert) { 'I have analyzed each of the asserted claims and the related portions of the specification, and I understand the inventive concepts disclosed.' } else { 'I am generally familiar with the patent. I understand that it is the patent at the center of this litigation.' })

**Q (Page 41, Line 3):** During your time at $(if ($isMeridianWitness) { 'Meridian' } else { 'Pinnacle' }), did you have access to the Technical Package described in the Master Services Agreement?

**A:** $(if ($isMeridianWitness) { 'Yes. The Technical Package was a controlled internal document. I had access to it as part of my role in process engineering, and I was responsible for portions of its development.' } else { 'I had limited access to portions of the Technical Package that were relevant to my work on the contracted Statements of Work. I did not have a copy of the complete Technical Package.' })

**Q (Page 53, Line 14):** Can you describe the difference, in your understanding, between the process described in the Technical Package and the process used in the AutoForge product?

**A:** $(if ($isMeridianWitness) { 'In my professional opinion, the AutoForge process appears to embody the same fundamental two-stage compression methodology described in the Technical Package, with what appear to be modest variations in process parameters. The architecture is, in substance, the same architecture I helped develop at Meridian.' } else { 'The AutoForge process incorporates engineering improvements that we developed independently. While there are some superficial similarities to descriptions in the Technical Package, the AutoForge employs different process control mechanisms and different overall process logic. I do not believe the AutoForge practices the claims of the ''543 Patent.' })

### III. Communications and Document Disclosure (Pages 79-148)

The witness was examined regarding specific communications, meetings, and document exchanges relevant to the disputes in this Action.

**Q (Page 84, Line 9):** Mr./Ms. $(($deponent -split ' ')[1]), I'm showing you what's been marked as Exhibit 12. Do you recognize this document?

**A:** Yes. This appears to be an internal email I sent on March 14, 2024, to the AutoForge engineering team.

**Q (Page 85, Line 22):** In paragraph 3 of this email, you write: "Confirming that we should treat the Meridian process as a baseline reference for the new platform. Please archive a clean copy in the team SharePoint and reference as needed during specification development." Can you explain what you meant by that?

**A:** $(if ($isMeridianWitness) { '[OBJECTION by Mr. Kim — outside the scope of the witness''s personal knowledge.] The email speaks for itself. My understanding at the time was that the Meridian process was a known reference point and I was directing the team to retain a copy of the documentation we had received under our contractual relationship for use in our work for Meridian.' } else { 'I was instructing the team to ensure the Technical Package was archived properly so that we could reference it as needed in performing our work under the SOW. I was not authorizing the use of the Meridian process for any purpose outside the scope of our work for Meridian.' })

**Q (Page 91, Line 5):** Is it your testimony that the use of the Technical Package as a "baseline reference for the new platform," as you wrote, was authorized under the TLA?

**A:** [OBJECTION by Mr. Kim — calls for a legal conclusion.] $(if ($isMeridianWitness) { 'I cannot speak to the legal interpretation of the TLA. As a technical matter, my understanding was that we were authorized to use the Meridian process for the contracted work.' } else { 'I am not a lawyer. I understood that we had a license to use the technology, and I believed the use was within the scope of that license.' })

### IV. Additional Topics (Pages 149-281)

Examination continued through the close of the deposition on the following additional topics:

- The witness's involvement in the AutoForge product launch and marketing materials (Pages 149-178);
- Communications with Pinnacle's customers regarding the technology underlying AutoForge (Pages 179-211);
- The witness's knowledge of, and any role in, the negotiations or implementation of the TLA Amendment No. 2 of September 2024 (Pages 212-247);
- Litigation hold practices at Pinnacle (Pages 248-265);
- Any analyses, opinions, or evaluations the witness performed or commissioned regarding whether the AutoForge practices the '543 Patent (Pages 266-281).

The witness's responses on each of these topics are summarized in the deposition summary memorandum prepared by counsel and circulated separately.

---

## EXHIBITS MARKED

| Exhibit No. | Date       | Description                                                                       | Bates Range / Source                |
|-------------|------------|-----------------------------------------------------------------------------------|-------------------------------------|
| Ex. 1       | 2026-XX-XX | Notice of Deposition of $deponent (with Subpoena Duces Tecum)                     | Counsel records                      |
| Ex. 2       | 2025-09-08 | Litigation Hold Notice from Pinnacle General Counsel                              | PIN-PRIV-000009 (limited disclosure) |
| Ex. 3       | 2024-03-14 | Internal email re: AutoForge engineering team document handling                    | PIN-016432                           |
| Ex. 4       | 2023-01-15 | Master Services Agreement                                                          | PIN-000001                           |
| Ex. 5       | 2023-03-08 | Technology License Agreement                                                       | PIN-000095                           |
| Ex. 6       | 2024-09-03 | TLA Amendment No. 2 (Field of Use Clarification)                                   | PIN-000142                           |
| Ex. 7       | 2025-07-22 | Cease-and-Desist Letter from Meridian to Pinnacle                                   | MER-018443                           |
| Ex. 8       | 2025-08-15 | Pinnacle Response to Cease-and-Desist (cover letter; legal advice withheld)         | PIN-PRIV-000001 (cover only)         |
| Ex. 9       | 2024-Q4    | AutoForge Engineering Design Review Slide Deck                                     | PIN-021876                           |
| Ex. 10      | 2025-02-11 | AutoForge Customer Demonstration Notes                                             | PIN-019234                           |
| Ex. 11      | 2024-06-20 | Email from witness to AutoForge engineering team re: process parameter selection    | PIN-014892                           |
| Ex. 12      | 2024-03-14 | Email from witness re: archiving Meridian process documentation                     | PIN-016432                           |
| Ex. 13      | 2024-Q3    | AutoForge Marketing Datasheet v1.0                                                  | PIN-022941                           |
| Ex. 14      | 2025-Q3    | AutoForge Sales Performance Report (HC-AEO)                                         | PIN-CONFIDENTIAL-018721              |
| Ex. 15      | 2024-12-15 | AutoForge Product Launch Press Release                                              | Public                               |

---

## CERTIFICATION OF COURT REPORTER

I, Margaret L. Whitman, CSR No. 9847, do hereby certify that the foregoing is a true and accurate transcript of the testimony given by $deponent on $depDate at the time and place set forth above; that the witness was duly sworn by me prior to testimony; and that the transcript was prepared from my stenographic notes.

________________________________
Margaret L. Whitman, CSR
RPR — Certified Real-Time Reporter

---

## DEPOSITION SUMMARY MEMO (Counsel Work Product — Privileged)

[Separate memo prepared by counsel; not part of this transcript.]

---

*$tldr*
*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}
