# =============================================================================
# Templates-Pleadings.ps1
# Court-filed pleadings: Answer, Motion, Brief.
# =============================================================================

function New-AnswerContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr

@"
$(Format-CaseCaption -Title 'ANSWER, AFFIRMATIVE DEFENSES, AND COUNTERCLAIMS')

Defendant Pinnacle Industries, Inc. ("Pinnacle" or "Defendant"), by and through its undersigned counsel, hereby submits its Answer, Affirmative Defenses, and Counterclaims to the Complaint filed by Plaintiff Meridian Corporation ("Meridian" or "Plaintiff"), and in support thereof states as follows:

## INTRODUCTION

$summary

Pinnacle denies that it has infringed any valid claim of $($Ctx.Patent) ("the '543 Patent") and denies that Meridian is entitled to any of the relief requested in the Complaint. The AutoForge Multi-Stage Compression Platform ("AutoForge") is the product of Pinnacle's own substantial, independent engineering investment, undertaken outside the scope of any license or technology transfer from Meridian. Pinnacle further asserts that the asserted claims of the '543 Patent are invalid and unenforceable.

## ANSWER

### Parties

1. Pinnacle is without sufficient knowledge or information to admit or deny the allegations of paragraph 1 of the Complaint regarding Meridian's corporate organization, and on that basis denies them.

2. Pinnacle admits the allegations of paragraph 2 of the Complaint regarding its own corporate organization and principal place of business.

### Jurisdiction and Venue

3. Pinnacle admits that this action purports to arise under the patent laws of the United States and that this Court has subject-matter jurisdiction under 28 U.S.C. §§ 1331 and 1338(a). Pinnacle admits that venue is proper in this District for purposes of this action only.

### Factual Allegations

4. With respect to paragraphs 4 through 18 of the Complaint, Pinnacle admits only that the parties entered into the Master Services Agreement dated January 15, 2023 (the "MSA") and the Technology License Agreement dated March 8, 2023 (the "TLA"), each of which speaks for itself. Pinnacle denies any characterization of those agreements set forth in the Complaint that is inconsistent with the agreements' actual terms. Pinnacle denies all remaining allegations in paragraphs 4 through 18.

5. With respect to paragraphs 19 through 35 of the Complaint, which describe the AutoForge product, Pinnacle admits only that Pinnacle developed and markets the AutoForge Multi-Stage Compression Platform. Pinnacle denies that the AutoForge incorporates, uses, or relies upon any technology, information, or know-how that Meridian provided to Pinnacle under the MSA or the TLA. Pinnacle further denies that the AutoForge practices any claim of the '543 Patent. Pinnacle denies all remaining allegations in paragraphs 19 through 35.

6. With respect to the patent infringement allegations in paragraphs 36 through 60 of the Complaint, Pinnacle denies that the AutoForge — whether literally or under the doctrine of equivalents — practices any limitation of any asserted claim of the '543 Patent. The AutoForge employs a different process architecture, different process parameters, and different control methodology than what is claimed in the '543 Patent.

7. Pinnacle denies the allegations of paragraphs 61 through 78 of the Complaint regarding alleged willfulness. Pinnacle obtained a written opinion of patent counsel before launching the AutoForge product line, on which it has reasonably and in good faith relied.

8. Pinnacle denies all allegations of the Complaint not specifically admitted or otherwise responded to above.

## AFFIRMATIVE DEFENSES

Without admitting any allegation not specifically admitted above, and without assuming any burden of proof or persuasion that it would not otherwise bear, Pinnacle asserts the following affirmative defenses:

### First Affirmative Defense — Non-Infringement

The AutoForge Multi-Stage Compression Platform does not infringe, directly or indirectly, literally or under the doctrine of equivalents, any valid and enforceable claim of the '543 Patent.

### Second Affirmative Defense — Invalidity

Each asserted claim of the '543 Patent is invalid for failure to comply with one or more of the conditions and requirements for patentability set forth in Title 35 of the United States Code, including without limitation 35 U.S.C. §§ 101, 102, 103, and 112. Among other things, the asserted claims are anticipated by, and rendered obvious in light of, prior art known to Pinnacle, including U.S. Patent Nos. 8,234,567 and 7,891,234, the published doctoral thesis of Dr. Jonathan H. Reeves (Stanford University, 2014), and the public disclosures made by Meridian's predecessor-in-interest at the SAMPE Conference in 2017.

### Third Affirmative Defense — License and Authorization

To the extent that Pinnacle's accused activities fall within any claim of the '543 Patent (which Pinnacle denies), such activities were licensed and authorized by the TLA and the express written approvals provided by Meridian during the parties' contractual relationship, including, without limitation, the approvals to develop derivative process improvements set forth in Amendment No. 2 to the TLA dated September 3, 2024.

### Fourth Affirmative Defense — Equitable Estoppel

Meridian is estopped from asserting infringement of the '543 Patent against the AutoForge product based on (a) Meridian's actual or constructive knowledge of Pinnacle's development of the AutoForge product line, beginning no later than Q3 2024; (b) Meridian's failure to object to such development in a timely manner; and (c) Pinnacle's reasonable and substantial investment in the AutoForge product in reliance on Meridian's silence and acquiescence.

### Fifth Affirmative Defense — Patent Misuse

Meridian has engaged in patent misuse by attempting to extend the scope of the '543 Patent beyond its lawful claims through the use restrictions imposed in the TLA and Pinnacle's various Statements of Work, including by purporting to restrict Pinnacle's use of unpatented background know-how and Pinnacle's independently-developed manufacturing improvements.

### Sixth Affirmative Defense — Failure to Mark

Meridian has failed to comply with the marking and notice requirements of 35 U.S.C. § 287, and accordingly Meridian's recovery of damages, if any, is limited to the period after Pinnacle received actual notice of the alleged infringement.

### Seventh Affirmative Defense — Limitation of Damages

Any damages to which Meridian might be entitled (which Pinnacle denies) are limited by 35 U.S.C. §§ 286 and 287 and by Meridian's own conduct, including its failure to mitigate.

## COUNTERCLAIMS

Counterclaim-Plaintiff Pinnacle Industries, Inc. ("Pinnacle"), by way of counterclaim against Counterclaim-Defendant Meridian Corporation ("Meridian"), alleges as follows:

### Jurisdiction and Venue

9. This Court has subject-matter jurisdiction over these counterclaims under 28 U.S.C. §§ 1331, 1338(a), and 2201 (declaratory judgment), and under 28 U.S.C. § 1367(a) (supplemental jurisdiction).

### Count I — Declaratory Judgment of Non-Infringement

10. An actual case or controversy exists between Pinnacle and Meridian regarding whether the AutoForge product infringes any valid claim of the '543 Patent.

11. Pinnacle is entitled to a declaration that the AutoForge does not infringe, directly or indirectly, literally or under the doctrine of equivalents, any valid and enforceable claim of the '543 Patent.

### Count II — Declaratory Judgment of Invalidity

12. An actual case or controversy exists regarding whether the asserted claims of the '543 Patent are valid.

13. Pinnacle is entitled to a declaration that each asserted claim of the '543 Patent is invalid for failure to comply with the conditions and requirements of patentability under 35 U.S.C. §§ 101, 102, 103, and/or 112.

### Count III — Breach of Contract (TLA Amendment No. 2)

14. Meridian materially breached the TLA, as amended by Amendment No. 2 dated September 3, 2024, by purporting to terminate the TLA without complying with the cure-period and notice procedures set forth therein, and by attempting to retroactively restrict the scope of activities expressly authorized by Amendment No. 2.

15. Pinnacle has been damaged by Meridian's breach in an amount to be proven at trial, including without limitation lost development investment, lost revenue, and the cost of being required to defend against the unjustified infringement claims asserted in the Complaint.

## PRAYER FOR RELIEF

WHEREFORE, Pinnacle respectfully requests that this Court enter judgment as follows:

(a) Dismissing the Complaint in its entirety with prejudice;

(b) Declaring that the AutoForge Multi-Stage Compression Platform does not infringe any valid claim of the '543 Patent;

(c) Declaring that each asserted claim of the '543 Patent is invalid;

(d) Awarding Pinnacle damages on its breach-of-contract counterclaim in an amount to be proven at trial;

(e) Declaring this case to be exceptional under 35 U.S.C. § 285 and awarding Pinnacle its reasonable attorneys' fees and costs;

(f) Awarding Pinnacle its costs of suit; and

(g) Granting such further relief as the Court deems just and proper.

## DEMAND FOR JURY TRIAL

Pinnacle hereby demands a trial by jury on all issues so triable.

---

Dated: November 18, 2025

Respectfully submitted,

$($Ctx.DefendantFirm.ToUpper())

By: ______________________________
$($Ctx.LeadCounselD.Name), Esq.
$($Ctx.LeadCounselD.Title)
$($Ctx.LeadCounselD.Address)
$($Ctx.LeadCounselD.Phone)
$($Ctx.LeadCounselD.Email)

*Counsel for Defendant and Counterclaim-Plaintiff Pinnacle Industries, Inc.*

---

*$tldr*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-MotionContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference
    $dates   = $Doc.sprk_extractdates

    $isCompel = $name -match 'Compel'

@"
$(Format-CaseCaption -Title $name.ToUpper())

## NOTICE OF MOTION

PLEASE TAKE NOTICE that on a date and at a time to be set by the Court, before the Honorable $($Ctx.JudgeName), United States District Judge, in Courtroom 12, 19th Floor, of the above-entitled Court, located at 450 Golden Gate Avenue, San Francisco, California, Plaintiff Meridian Corporation ("Meridian") will and hereby does move for an order $(if ($isCompel) { 'compelling Defendant Pinnacle Industries, Inc. ("Pinnacle") to produce documents responsive to Meridian''s First Request for Production of Documents and to provide complete responses to Meridian''s First Set of Interrogatories' } else { 'granting the relief described below' }).

This Motion is based on this Notice of Motion, the accompanying Memorandum of Points and Authorities, the Declaration of $($Ctx.LeadCounselP.Name) filed concurrently herewith, the proposed order submitted herewith, the pleadings and records on file in this action, and such further evidence and argument as may be presented at or before the hearing on this Motion.

## MEMORANDUM OF POINTS AND AUTHORITIES

### I. INTRODUCTION

$summary

### II. STATEMENT OF FACTS

A. The Discovery Requests at Issue

On September 3, 2025, Meridian served its First Request for Production of Documents (75 requests) and First Set of Interrogatories (15 interrogatories) on Pinnacle. Pinnacle's responses, served October 17, 2025, comprised principally of boilerplate objections, refusals to produce on the basis of privilege without identifying the documents withheld, and improperly narrow constructions of the requests' plain terms.

B. The Meet-and-Confer Process

In accordance with this Court's Standing Order and Local Rule 37-1, undersigned counsel met and conferred with counsel for Pinnacle on November 4 and November 11, 2025, in good-faith efforts to resolve the disputed objections and refusals without court intervention. Despite these efforts, the parties were unable to resolve the disputes addressed in this Motion. Specifically:

1. Pinnacle's refusal to produce documents responsive to RFP Nos. 12, 18, 22-27, 31, 38-42, 49, 53-58, 65, and 67 (relating to design and development of the AutoForge product, supplier and customer communications regarding the Licensed Technology, and financial information bearing on Meridian's damages);

2. Pinnacle's refusal to provide complete responses to Interrogatory Nos. 3, 5, 7, 9, and 11; and

3. Pinnacle's failure to provide a privilege log identifying any of the documents withheld on the basis of attorney-client privilege or work-product doctrine.

### III. LEGAL STANDARD

A party may serve on any other party a request to produce documents that are within the scope of Federal Rule of Civil Procedure 26(b). Fed. R. Civ. P. 34(a). The scope of discovery under Rule 26(b)(1) is broad and encompasses "any nonprivileged matter that is relevant to any party's claim or defense and proportional to the needs of the case." Where a party fails to produce responsive documents or to answer interrogatories, the requesting party may move to compel pursuant to Rule 37(a)(3)(B). The party resisting discovery bears the burden of demonstrating why a request is improper. Blankenship v. Hearst Corp., 519 F.2d 418, 429 (9th Cir. 1975).

### IV. ARGUMENT

#### A. The Withheld AutoForge Design Documents Are Plainly Relevant

The central allegation in this case is that Pinnacle's AutoForge product incorporates Meridian's Licensed Technology. Documents reflecting the design, development, and engineering of the AutoForge are unquestionably relevant to whether Pinnacle developed AutoForge independently or whether (as Meridian alleges) Pinnacle drew on the Technical Package and other confidential information provided under the MSA and TLA. Pinnacle's "burdensome" objection is unavailing — the relevant time period (Q1 2024 through present) is short, the universe of engineering documents is finite, and Pinnacle has substantial litigation-hold and document-management infrastructure in place.

#### B. The Supplier and Customer Communications Are Discoverable

Communications between Pinnacle and its third-party suppliers and customers regarding the AutoForge product, including the disclosure of process parameters, tooling specifications, and other technical information that Meridian alleges to be derivative of the Licensed Technology, are directly relevant to (a) Pinnacle's affirmative defenses of independent development and equitable estoppel, and (b) Meridian's claims for breach of confidentiality, misappropriation, and patent infringement. Pinnacle's invocation of "third party confidentiality" is not a basis for refusing to produce. The Stipulated Protective Order entered in this case is designed precisely to protect such interests.

#### C. The Financial Information Is Discoverable for Damages

Meridian seeks both lost-profits damages and a reasonable royalty. Pinnacle's revenues, profits, and unit-volume figures for the AutoForge product line are required to calculate either measure. Pinnacle's objection that "financial information is sensitive" is not a discovery objection — it is, again, a Protective Order matter, and the Protective Order's "Outside Attorneys' Eyes Only" tier is more than sufficient to address it.

#### D. Pinnacle Must Produce a Privilege Log

A party who withholds documents on the basis of privilege "must . . . expressly make the claim" and "describe the nature of the documents, communications, or tangible things not produced or disclosed . . . in a manner that, without revealing information itself privileged or protected, will enable other parties to assess the claim." Fed. R. Civ. P. 26(b)(5)(A). Pinnacle's failure to provide any privilege log waives the privilege as to all withheld documents. United States v. Construction Prods. Research, Inc., 73 F.3d 464, 473 (2d Cir. 1996).

### V. RELIEF REQUESTED

For the reasons stated above, Meridian respectfully requests that the Court:

1. Compel Pinnacle to produce all documents responsive to RFP Nos. 12, 18, 22-27, 31, 38-42, 49, 53-58, 65, and 67 within fourteen (14) days of the order;

2. Compel Pinnacle to provide complete responses to Interrogatory Nos. 3, 5, 7, 9, and 11 within fourteen (14) days of the order;

3. Compel Pinnacle to produce a privilege log meeting the requirements of Federal Rule of Civil Procedure 26(b)(5)(A) within fourteen (14) days of the order;

4. Award Meridian its reasonable expenses, including attorneys' fees, incurred in bringing this Motion pursuant to Federal Rule of Civil Procedure 37(a)(5)(A); and

5. Grant such further relief as the Court deems just and proper.

---

Dated: November 18, 2025

Respectfully submitted,

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
*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-ClaimConstructionBriefContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference

@"
$(Format-CaseCaption -Title 'PLAINTIFF MERIDIAN CORPORATION''S OPENING CLAIM CONSTRUCTION BRIEF')

## I. INTRODUCTION

This brief is submitted on behalf of Plaintiff Meridian Corporation ("Meridian") in support of Meridian's proposed constructions of the disputed claim terms in $($Ctx.Patent), entitled "$($Ctx.PatentTitle)" (the "'543 Patent"). $summary

The twelve disputed claim terms identified by the parties for construction are set forth in the Joint Claim Construction and Prehearing Statement filed January 30, 2026 (Dkt. 87). For each disputed term, Meridian respectfully requests that the Court adopt Meridian's proposed construction, which is supported by the intrinsic record (the claims, the specification, and the prosecution history) and confirmed by the relevant extrinsic evidence (the technical literature and expert testimony).

## II. LEGAL STANDARD

Claim construction is a matter of law for the Court. Markman v. Westview Instruments, Inc., 517 U.S. 370, 372 (1996). The bedrock principle of claim construction is that "[t]he words of a claim are generally given their ordinary and customary meaning . . . [as] the meaning that the term would have to a person of ordinary skill in the art in question at the time of the invention." Phillips v. AWH Corp., 415 F.3d 1303, 1312-13 (Fed. Cir. 2005) (en banc). The intrinsic record is paramount: claims are read in light of the specification, of which they are part, and the prosecution history. Id. at 1315-17. Extrinsic evidence may be used, but is "less significant than the intrinsic record in determining the legally operative meaning of claim language." Id. at 1317.

The specification is "the single best guide to the meaning of a disputed term." Vitronics Corp. v. Conceptronic, Inc., 90 F.3d 1576, 1582 (Fed. Cir. 1996). Where the specification reveals a "special definition given to a claim term by the patentee that differs from the meaning it would otherwise possess," that special definition controls. Phillips, 415 F.3d at 1316. The court must also consider any disclaimer of claim scope made during prosecution. Id. at 1317.

## III. THE TECHNOLOGY AND THE '543 PATENT

The '543 Patent claims a process for thermal compression molding of precision components. The invention solves a long-felt problem in the precision-manufacturing field: prior-art compression-molding processes suffered from inconsistent through-thickness density and microstructural variability that limited their use in high-tolerance applications. The '543 Patent achieves substantially improved consistency and density uniformity through a two-stage compression process with feedback-controlled temperature ramp profiles, as further described in claims 1-19.

The named inventor, Dr. Marcus J. Hendricks, conceived of the invention in 2017 while serving as Senior Director of Process Engineering at Meridian. The application was filed October 14, 2018 (Application No. 16/162,471) and issued December 14, 2021 as the '543 Patent. The invention is the foundational IP for Meridian's commercial precision-manufacturing program.

## IV. THE DISPUTED CLAIM TERMS

The parties dispute the construction of twelve claim terms appearing in independent claims 1, 8, and 14. Three of the disputed terms — "thermal compression cycle," "controlled densification gradient," and "feedback-modulated temperature profile" — are dispositive of the parties' infringement and invalidity disputes. Meridian addresses these three terms first, followed by the remaining terms in the order they appear in claim 1.

### A. "thermal compression cycle" (claims 1, 8, 14)

**Meridian's Construction:** "a sequence of compression and heating steps applied to a workpiece to achieve molecular flow and consolidation, characterized by at least one increase in compressive force concurrent with or following the application of heat."

**Pinnacle's Construction:** "a single application of compressive force during the application of heat."

The intrinsic record overwhelmingly supports Meridian's construction. The specification describes the "thermal compression cycle" as encompassing multiple compression steps applied at different points during the heating profile. *See* '543 Patent at 4:32-5:18 ("The thermal compression cycle of the present invention may comprise an initial compression at temperature T1, a hold period, and a subsequent compression at elevated temperature T2 . . . ."). Claims 8 and 14 expressly recite multi-step embodiments of the cycle. Pinnacle's narrow construction would read out preferred embodiments of the invention — a result the law disfavors. *See* Vitronics, 90 F.3d at 1583.

### B. "controlled densification gradient" (claims 1, 14)

**Meridian's Construction:** "a profile of material density across the thickness dimension of the workpiece that varies in a predetermined manner from one surface to the other, achieved by controlling temperature, pressure, and time during the compression cycle."

**Pinnacle's Construction:** "a uniform material density across the workpiece."

Pinnacle's proposed construction is incorrect because it equates "gradient" with "uniformity" — the opposite of the term's plain meaning. The specification describes the controlled densification gradient as enabling "non-uniform but predictable" through-thickness density profiles tailored to specific structural requirements. '543 Patent at 6:14-7:8. The prosecution history confirms this: in response to an Office Action dated April 11, 2020, the applicant amended the claims and explained that "the present invention's controlled densification gradient is distinguished from the prior art Smith (US 8,234,567), which produced uniform densification across the workpiece."

### C. "feedback-modulated temperature profile" (claims 8, 14)

**Meridian's Construction:** "a time-varying temperature profile that is adjusted during the compression cycle in response to one or more sensor measurements of process variables."

**Pinnacle's Construction:** "a predetermined temperature profile programmed before the compression cycle begins."

Pinnacle's construction reads "feedback" out of the claim term entirely. The specification is unambiguous: "The temperature profile is modulated in real-time based on signals from process sensors monitoring melt-flow viscosity, compressive load, and workpiece centerline temperature." '543 Patent at 8:22-9:5. The use of "feedback" in the claim language carries its ordinary meaning in process control engineering: control responses based on measured process state, not pre-programmed open-loop control. Pinnacle's expert (Dr. Nakamura) does not appear to dispute this in her report; she simply argues that Pinnacle's accused process implements something other than feedback control. That is an infringement argument, not a claim construction argument, and is properly addressed at summary judgment or trial — not in the construction of the term.

### D. Remaining Disputed Terms (Terms 4-12)

For the remaining nine disputed terms, Meridian's constructions follow directly from the plain meaning of the claim language as informed by the specification. Meridian addresses each in the chart attached as Exhibit A and in the supporting Declaration of Dr. Robert Patel filed concurrently. For brevity, this brief does not repeat the per-term analysis here.

## V. CONCLUSION

For the reasons stated above, Meridian respectfully requests that the Court adopt Meridian's proposed constructions for each of the twelve disputed claim terms.

---

Dated: February 14, 2026

Respectfully submitted,

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
*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}
