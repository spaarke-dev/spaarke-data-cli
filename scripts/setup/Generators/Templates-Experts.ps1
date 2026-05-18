# =============================================================================
# Templates-Experts.ps1
# Expert reports — initial, supplemental damages, rebuttal.
# =============================================================================

function New-ExpertReportContent {
    # Generic expert report template (fallback).
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference
    $expertName = if ($name -match 'Dr\.\s+([A-Za-z\.\s]+)') { "Dr. $(($Matches[1].Trim() -split '\s+')[0..1] -join ' ')" } else { 'the Expert' }
    $expertField = if ($Doc.sprk_filename -match 'damages|economic') { 'patent damages economics' } else { 'precision manufacturing technology' }

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# EXPERT REPORT OF $($expertName.ToUpper())

**Matter:** $($Ctx.Caption)
**Case No.:** $($Ctx.CaseNumber)
**Date of Report:** February 5, 2026

---

## I. INTRODUCTION AND ASSIGNMENT

I, $expertName, have been retained by counsel for $(if ($Doc.sprk_filename -match 'rebuttal|nakamura') { 'Defendant Pinnacle Industries, Inc.' } else { 'Plaintiff Meridian Corporation' }) to provide expert opinions in this matter regarding $expertField. The opinions expressed in this report are based on my education, training, and experience, my review of the materials listed in Exhibit B, and the analyses I have performed in this matter.

$summary

## II. QUALIFICATIONS

I am a [Ph.D. / M.S. / B.S.] in [field] from [institution] and have approximately [N] years of professional experience in $expertField. A complete curriculum vitae is attached as Exhibit A.

## III. SUMMARY OF OPINIONS

$tldr

## IV. ANALYSIS

[Detailed analysis omitted for brevity in this generated stub.]

## V. CONCLUSION

Based on the analyses set forth above, my opinions in this matter are as set forth in Section III above. I reserve the right to supplement or amend my opinions based on additional discovery, expert reports of opposing counsel's experts, or further analysis.

---

*Exhibit A: Curriculum Vitae*
*Exhibit B: Materials Reviewed*
*Exhibit C: Compensation Schedule*

*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-ExpertReportDamagesContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# SUPPLEMENTAL EXPERT REPORT OF DR. ROBERT PATEL — DAMAGES OPINIONS

**Matter:** $($Ctx.Caption)
**Case No.:** $($Ctx.CaseNumber)
**Date of Report:** January 15, 2026

---

## I. INTRODUCTION

I, Dr. Robert Patel, previously submitted my Initial Expert Report dated November 14, 2025 ("Initial Report"), in which I provided opinions regarding (a) the technical aspects of the AutoForge Multi-Stage Compression Platform manufactured and marketed by Defendant Pinnacle Industries, Inc., (b) the relationship between the AutoForge process and the claims of $($Ctx.Patent), and (c) the question of whether the AutoForge incorporates technology and information derived from the Technical Package and Confidential Information of Plaintiff Meridian Corporation.

This Supplemental Expert Report addresses the **damages opinions** that were not included in my Initial Report because the necessary financial discovery from Pinnacle had not yet been completed at the time of my Initial Report. With the production of Pinnacle's financial data on December 22, 2025 (Bates PIN-CONFIDENTIAL-018721 through PIN-CONFIDENTIAL-019648), I am now able to provide damages opinions.

$summary

## II. SUMMARY OF DAMAGES OPINIONS

It is my opinion that, in the event the trier of fact finds that the AutoForge product infringes one or more valid claims of the '543 Patent and/or that Pinnacle has breached the TLA in the manner alleged, Meridian's recoverable damages are as follows:

| Theory | Lower Bound | Mid-Range | Upper Bound |
|--------|-------------|-----------|-------------|
| Lost Profits — Lost Sales            | \$ 24,800,000 | \$ 31,200,000 | \$ 38,400,000 |
| Lost Profits — Price Erosion         | \$  6,200,000 | \$  9,400,000 | \$ 12,800,000 |
| Reasonable Royalty (Bookend)         | \$ 18,300,000 | \$ 22,750,000 | \$ 27,200,000 |
| **Pre-Judgment Interest (Estimate)** | \$  3,400,000 | \$  4,200,000 | \$  5,000,000 |
| **TOTAL — Mid-Range Damages**        |               | **\$ 67,550,000** |              |

These opinions assume infringement and validity. They do not double-count between the lost-profits and reasonable-royalty theories — for sales that satisfy the Panduit factors, lost profits are the appropriate measure; for the remaining infringing sales, a reasonable royalty applies.

$tldr

## III. METHODOLOGY

### A. Lost Profits — Panduit Analysis

For the period October 1, 2024 (the date of the first commercial AutoForge sale) through Q4 2025 (the most recent completed quarter for which Pinnacle has produced financial data), I have analyzed each of the four Panduit factors:

1. **Demand for the patented product.** The market for precision-manufactured components meeting the tolerance specifications enabled by the patented thermal compression process is substantial and growing. Both parties' products operate in this market.

2. **Absence of acceptable non-infringing substitutes.** During the relevant damages period, the only commercial alternatives were (a) the patented Meridian process (offered through Meridian's licensed partners) and (b) the accused AutoForge process. Other compression-molding alternatives suffer from materially inferior tolerance and density consistency. I therefore conclude that, but for the AutoForge product, the bulk of Pinnacle's customers would have purchased competing products from Meridian.

3. **Manufacturing and marketing capability to exploit the demand.** Meridian has both the manufacturing capacity and the established sales channels to have absorbed substantial additional volume. Through Q4 2025, Meridian's installed manufacturing capacity for Components meeting the relevant specifications was operating at approximately 71% utilization. The incremental volume corresponding to AutoForge sales (an estimated 29,400 units through Q4 2025) is well within Meridian's capacity envelope.

4. **Profit per unit.** Meridian's incremental profit per unit, calculated on the basis of variable cost only (since the relevant fixed costs would have been incurred regardless), is approximately \$1,063 per unit on average across the product mix. This figure is supported by Meridian's quarterly financial statements (MER-FINANCIAL-002841 through MER-FINANCIAL-003117) and the deposition testimony of Meridian's CFO, Catherine Liu (Liu Dep. 89:14-114:22).

Applying these factors, my lost-profits opinion derives from the unit volumes shown in Pinnacle's production at PIN-CONFIDENTIAL-019221 (29,400 units through Q4 2025) multiplied by Meridian's incremental profit per unit (\$1,063), with appropriate apportionment for the convoyed sales analysis described in Section IV.

### B. Price Erosion

The competitive entry of AutoForge has put downward pressure on Meridian's prices in this market segment. Based on (a) Meridian's pricing history through Q3 2024 (pre-AutoForge), (b) Meridian's actual pricing trajectory from Q4 2024 forward, and (c) reasonable assumptions regarding industry-wide price trends in the absence of AutoForge's competitive entry, I estimate that Meridian has experienced price erosion of approximately 4.6% to 9.4% on its competing product line, with a mid-range estimate of 7.0%. Applied to Meridian's actual sales in the relevant period, this yields the price-erosion damages shown in Section II.

### C. Reasonable Royalty (Bookend Analysis)

For sales that do not satisfy the Panduit factors (e.g., where a Pinnacle customer demonstrates that they would not have purchased from Meridian for reasons unrelated to product availability), a reasonable royalty applies. Applying a Georgia-Pacific hypothetical-negotiation analysis, with a hypothetical negotiation date of October 1, 2024 (the date of first AutoForge commercial sale), I conclude that the parties would have agreed to a royalty in the range of 18% to 24% of net selling price, with a mid-range estimate of 21%. This range is supported by:

- The royalty rate in the actual Technology License Agreement between the parties (15% royalty for the limited Authorized Field, plus a substantial fixed fee structure);
- The narrow set of comparable license agreements in the precision-manufacturing field disclosed in discovery;
- The disproportionate technical contribution of the patented technology to the value of the AutoForge product (described in my Initial Report, Section V);
- The absence of acceptable non-infringing alternatives at the time of the hypothetical negotiation; and
- The competitive position of Meridian as the patentee unwilling to license to a known competitor.

## IV. CONVOYED SALES AND APPORTIONMENT

I have considered whether to apply convoyed-sales reasoning to address ancillary product sales that benefited from the AutoForge core unit. Based on Pinnacle's product configurations (PIN-CONFIDENTIAL-019447), I conclude that approximately 12% of total AutoForge revenue derives from non-patented ancillary components and services. Applied apportionment, the patented portion of AutoForge sales is approximately 88% of gross revenue.

## V. ASSUMPTIONS AND LIMITATIONS

This Supplemental Report assumes (a) that the trier of fact finds Pinnacle has infringed one or more valid claims of the '543 Patent, (b) that the production of financial data from Pinnacle is substantially complete, and (c) that the projection methodology is consistent with controlling Federal Circuit case law. I reserve the right to supplement or amend this Report based on additional discovery, the rebuttal report of Pinnacle's damages expert, or further analysis. My opinions are subject to refinement based on data produced after the date of this Report.

## VI. COMPENSATION

I am being compensated at my standard hourly rate of \$725 per hour for analysis and report preparation, and \$925 per hour for trial and deposition testimony. My compensation is not contingent on the outcome of this matter.

---

*Exhibit A: Curriculum Vitae of Dr. Robert Patel*
*Exhibit B: Materials Reviewed*
*Exhibit C: Damages Calculation Worksheets*
*Exhibit D: Comparable License Agreement Summary*
*Exhibit E: Compensation Schedule*

---

*$tldr*
*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}

function New-ExpertReportRebuttalContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name    = $Doc.sprk_documentname
    $summary = $Doc.sprk_filesummary
    $tldr    = $Doc.sprk_filetldr
    $refs    = $Doc.sprk_extractreference

@"
<div style="font-size: 0.85em; color: #888;">SAMPLE DATA - FOR DEMO PURPOSES ONLY</div>

# REBUTTAL EXPERT REPORT OF DR. EMILY NAKAMURA — PATENT VALIDITY OPINIONS

**Matter:** $($Ctx.Caption)
**Case No.:** $($Ctx.CaseNumber)
**Date of Report:** February 12, 2026

---

## I. INTRODUCTION

I, Dr. Emily Nakamura, have been retained by counsel for Defendant Pinnacle Industries, Inc. to provide expert rebuttal opinions in this matter. This Rebuttal Report responds to the Initial Expert Report of Dr. Robert Patel, dated November 14, 2025, on issues of patent validity and infringement.

$summary

The opinions in this Rebuttal Report supplement, but do not replace, the opinions stated in my Initial Expert Report dated December 18, 2025 ("Initial Report"). I incorporate by reference the qualifications, materials reviewed, and methodology set forth in my Initial Report. A list of additional materials reviewed in connection with this Rebuttal Report is attached as Exhibit B-1.

## II. SUMMARY OF REBUTTAL OPINIONS

I disagree with each of the following opinions of Dr. Patel for the reasons explained in this Rebuttal Report:

**A.** I disagree with Dr. Patel's opinion (Patel Initial Report § VI) that each asserted claim of $($Ctx.Patent) is valid. In my opinion, claims 1, 8, and 14 of the '543 Patent are invalid as anticipated by U.S. Patent No. 8,234,567 ("Smith") and as obvious in light of Smith in combination with the published doctoral thesis of Dr. Jonathan H. Reeves (Stanford University, 2014, "Reeves Thesis").

**B.** I disagree with Dr. Patel's opinion (Patel Initial Report § VII) that the AutoForge Multi-Stage Compression Platform practices each limitation of claims 1, 8, and 14 of the '543 Patent. In my opinion, the AutoForge process does not satisfy at least the "feedback-modulated temperature profile" limitation of claims 8 and 14, nor the "controlled densification gradient" limitation of claims 1 and 14, under any reasonable construction of those terms.

**C.** I disagree with Dr. Patel's opinion (Patel Initial Report § VIII) that the AutoForge process derives from or incorporates the Licensed Technology described in the Technical Package. The AutoForge process implements substantively different process control logic, employs different sensor architecture, and uses different mathematical models than those disclosed in the Technical Package.

$tldr

## III. INVALIDITY — ANTICIPATION AND OBVIOUSNESS

### A. The Smith Patent (U.S. Patent No. 8,234,567)

Smith was filed on June 17, 2007 and issued on August 7, 2012. Smith therefore qualifies as prior art to the '543 Patent under 35 U.S.C. § 102(a)(1). Smith discloses a "two-stage compression-molding process" involving (i) an initial low-pressure compression at elevated temperature, (ii) a controlled hold period, and (iii) a second compression at higher pressure and elevated temperature. *See* Smith at 4:18-7:42. These steps correspond directly to the "thermal compression cycle" recited in claim 1 of the '543 Patent.

Dr. Patel's Initial Report dismisses Smith on the basis that Smith does not disclose "feedback control" of the temperature profile. Initial Report at ¶ 117. That observation is correct as to Smith standing alone, but it is irrelevant to anticipation of claim 1, which does not require feedback control. (The "feedback-modulated temperature profile" limitation appears only in claims 8 and 14.) For claim 1, Smith discloses every limitation, and the claim is anticipated.

### B. The Reeves Thesis

The Reeves Thesis was publicly available from the Stanford University library in May 2014 and was indexed in the ProQuest Dissertations & Theses database in June 2014, more than four years before the '543 Patent's earliest priority date. The Reeves Thesis discloses, at Chapter 4, a process-control system using real-time sensor feedback (specifically, in-mold temperature and centerline-flow viscosity sensors) to dynamically modulate the temperature profile during compression molding of polymer composites.

A person of ordinary skill in the art at the relevant time would have been motivated to combine Smith's two-stage compression-molding process with the Reeves Thesis's feedback-control approach, because (i) Smith expressly identifies process variability as a limitation of its disclosed process and suggests the use of "advanced process control techniques" (Smith at 8:44-9:12), and (ii) the Reeves Thesis specifically presents its feedback-control system as a solution to the problem of process variability in compression molding.

The combination of Smith and the Reeves Thesis renders claims 8 and 14 of the '543 Patent obvious under 35 U.S.C. § 103.

### C. Secondary Considerations

Dr. Patel relies on commercial success and copying as secondary considerations supporting nonobviousness. (Patel Initial Report at ¶ 134.) These considerations are entitled to little weight in this case because:

1. The commercial success of products embodying the '543 Patent (Meridian's licensed-partner products) is attributable substantially to factors other than the claimed invention, including Meridian's pre-existing market position, manufacturing capacity, and customer relationships.

2. Pinnacle did not "copy" the '543 Patent's claimed invention. As discussed in Section IV below, Pinnacle developed the AutoForge process independently and the AutoForge does not practice the asserted claims.

## IV. NON-INFRINGEMENT

[Detailed claim-by-claim analysis omitted in this excerpt; see full Rebuttal Report Sections IV.A through IV.E.]

In summary, the AutoForge process does not satisfy the following claim limitations:

- **"feedback-modulated temperature profile"** (claims 8, 14): The AutoForge process uses a pre-programmed temperature schedule that adjusts based on a fixed look-up table indexed by tooling identifier, not real-time feedback from process sensors. Real-time sensor data are recorded for quality-assurance purposes but are not used to modulate the temperature profile during the active compression cycle. This does not satisfy the "feedback-modulated" limitation under any reasonable construction of that term.

- **"controlled densification gradient"** (claims 1, 14): The AutoForge process targets a uniform through-thickness density rather than a controlled gradient. Process verification data produced by Pinnacle (PIN-019841 through PIN-020472) demonstrate density variability of less than 0.4% across the workpiece thickness — well within the band that the technical literature would characterize as "uniform" density.

## V. RESPONSE TO PATEL DAMAGES OPINIONS

I have reviewed Dr. Patel's Supplemental Report on damages, dated January 15, 2026. I do not undertake a damages rebuttal in this Report; that rebuttal is being prepared separately by Dr. Marcus J. Chen, Pinnacle's damages expert, whose rebuttal report is expected to be served on February 19, 2026.

I note, however, that Dr. Patel's damages opinions assume infringement and validity. To the extent the trier of fact accepts my opinions on either invalidity or non-infringement, Dr. Patel's damages opinions are without foundation.

## VI. CONCLUSION

For the reasons stated in this Rebuttal Report, I disagree with the opinions of Dr. Patel as set forth in Section II. My opinions on validity, infringement, and the relationship between the AutoForge process and the Licensed Technology are as set forth in my Initial Report and as supplemented herein.

I reserve the right to supplement or amend my opinions based on the deposition of Dr. Patel scheduled for February 24, 2026, or further analysis.

---

*Exhibit A: Curriculum Vitae of Dr. Emily Nakamura*
*Exhibit B-1: Additional Materials Reviewed for Rebuttal Report*
*Exhibit C-1: Updated Compensation Schedule*

---

*$tldr*
*Reference: $refs*
*Document ID: $($Doc.sprk_scenarioid)*
"@
}
