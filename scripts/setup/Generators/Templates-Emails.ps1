# =============================================================================
# Templates-Emails.ps1
# RFC 5322 EML format. Each function returns a complete email message.
# =============================================================================

function New-EmailContent {
    param([Parameter(Mandatory)] $Doc, [Parameter(Mandatory)] $Ctx)

    $name      = $Doc.sprk_documentname
    $summary   = $Doc.sprk_filesummary
    $tldr      = $Doc.sprk_filetldr
    $dates     = $Doc.sprk_extractdates
    $people    = $Doc.sprk_extractpeople
    $sid       = $Doc.sprk_scenarioid
    $fname     = $Doc.sprk_filename

    $emailDate = if ($dates) { ($dates -split "[`n,]")[0].Trim() } else { 'November 1, 2025' }

    # Try to parse a sensible RFC 2822 date
    try { $dt = [DateTime]::Parse($emailDate); $rfcDate = $dt.ToString("ddd, d MMM yyyy HH:mm:ss") + ' -0800' }
    catch { $rfcDate = 'Wed, 1 Nov 2025 14:30:00 -0800' }

    # Determine sender / recipient based on filename pattern
    $from    = 'rachel.torres@example.com'
    $fromNm  = 'Rachel M. Torres'
    $to      = 'sarah.chen@example.com'
    $toNm    = 'Sarah Chen'
    $subject = $name

    # Filename like "email-{sender}-{recipient}-{topic}-{date}.eml"
    if ($fname -match 'chen-torres')         { $from='sarah.chen@example.com';   $fromNm='Sarah Chen';     $to='rachel.torres@example.com'; $toNm='Rachel M. Torres' }
    elseif ($fname -match 'torres-chen')     { $from='rachel.torres@example.com';$fromNm='Rachel M. Torres';$to='sarah.chen@example.com';   $toNm='Sarah Chen' }
    elseif ($fname -match 'kim-torres')      { $from='david.kim@example.com';    $fromNm='David Kim';      $to='rachel.torres@example.com'; $toNm='Rachel M. Torres' }
    elseif ($fname -match 'torres-kim')      { $from='rachel.torres@example.com';$fromNm='Rachel M. Torres';$to='david.kim@example.com';    $toNm='David Kim' }
    elseif ($fname -match 'kim-nakamura')    { $from='david.kim@example.com';    $fromNm='David Kim';      $to='emily.nakamura@example.com';$toNm='Dr. Emily Nakamura' }
    elseif ($fname -match 'patel-park')      { $from='robert.patel@example.com'; $fromNm='Dr. Robert Patel'; $to='michael.park@example.com';$toNm='Michael Park' }
    elseif ($fname -match 'chen-park')       { $from='sarah.chen@example.com';   $fromNm='Sarah Chen';     $to='michael.park@example.com';  $toNm='Michael Park' }
    elseif ($fname -match 'park-chen')       { $from='michael.park@example.com'; $fromNm='Michael Park';   $to='sarah.chen@example.com';    $toNm='Sarah Chen' }
    elseif ($fname -match 'park-patel')      { $from='michael.park@example.com'; $fromNm='Michael Park';   $to='robert.patel@example.com';  $toNm='Dr. Robert Patel' }

    # Body builders by topic — choose by filename hints
    $body = if ($fname -match 'budget-approved') {
@"
Rachel —

Confirming the Board's approval of the supplemental expert budget you requested in your November 18 memo. The approved figures are as follows:

  - Dr. Patel — Damages supplement: up to \$185,000 (covering work through trial)
  - Dr. Patel — Trial testimony: up to \$95,000 (covering preparation and 5 days of trial testimony)
  - Dr. Patel — Pretrial deposition preparation: up to \$45,000

Total: \$325,000, against the previously-approved damages-expert budget line.

The Board did push back briefly on the trial-testimony figure but accepted our recommendation that we hold to your firm's expert pricing rather than try to renegotiate at this stage. The Board emphasized that they want substantive monthly invoice detail going forward — particularly any work outside the budgeted scope. Please ensure Dr. Patel's invoices identify (a) hours by task category, (b) any non-routine activities, and (c) any planned scope changes before they occur.

A couple of things from the Board discussion you should know:

  1. The Board asked about settlement posture. I gave them the answer we discussed — that settlement is unlikely until after Markman, but we should reassess based on the construction order. The Board agreed.

  2. The CFO (Catherine Liu) flagged the damages forecast. She'd like a working session with Dr. Patel before his supplemental report is finalized to make sure his lost-profits methodology is consistent with our internal gross-margin analysis. Can you set that up for the first week of December?

  3. The Board reaffirmed the litigation hold and asked whether IT's automatic suspension of email retention has been verified end-to-end. I'm scheduling a check with our IT director this week — but if your team is aware of any custodians where email retention might still be live, please flag.

Thanks for the detailed memo and the clean budget tables — they made the Board discussion much easier than the prior round.

Sarah

$summary

— Original Message —
From: Rachel M. Torres <rachel.torres@example.com>
Sent: Tuesday, November 18, 2025 4:42 PM
To: Sarah Chen <sarah.chen@example.com>
Cc: Daniel Crawford <daniel.crawford@example.com>
Subject: Supplemental Expert Budget Request — Q4 2025 / Q1 2026

[Original message: budget request memo, 4 pages, attached as PDF.]
"@
    }
    elseif ($fname -match 'settlement-strategy') {
@"
Sarah —

Following up on our call yesterday regarding settlement posture. Putting the analysis in writing so you have a clean record for the Board (this email is privileged and intended only for distribution to internal counsel).

$summary

**Where we are.** Markman is March 18-19. The current draft order from Pinnacle's most recent claim construction brief reads on a substantially narrower construction of "feedback-modulated temperature profile" than we proposed. If Judge Alsup adopts Pinnacle's construction, our infringement case on claims 8 and 14 narrows materially — we may be limited to claim 1 only, which Pinnacle has stronger invalidity arguments on.

**Settlement timing.** Three sensible windows:

  1. **Pre-Markman (now through March 17).** Maximum leverage if we believe our constructions will prevail. Less leverage if we believe Pinnacle's constructions will prevail. Our internal assessment (developed with Dr. Patel) is that we win on at least 8 of the 12 disputed terms, including "feedback-modulated" and "controlled densification gradient." But the case-by-case nature of Markman means we can never be certain, and a single adverse construction can swing the case.

  2. **Post-Markman (April-May 2026).** Both sides will have substantially better information about the strength of their positions. Settlement values typically converge significantly post-Markman. The downside is that if we lose key constructions, our settlement leverage is diminished — but if we win, it's enhanced.

  3. **Post-summary judgment (Q3 2026).** Last realistic settlement window before trial. Many cases settle here when the prospect of a 4-week trial focuses both sides' minds.

**My recommendation.** Hold settlement discussions until after the Markman order. Pinnacle has not made a settlement overture; if they do, we should listen and respond, but we should not be the first to initiate. The exception is if their counsel signals genuine willingness to discuss damages-only resolution (i.e., conceding infringement and validity in exchange for capped damages); that would be unusual but worth exploring.

**Range to anticipate.** Based on Dr. Patel's mid-range damages opinions of approximately \$67.5 million, plus our willfulness/exceptional-case enhancement potential and equitable considerations, a reasonable settlement range — assuming we hold our infringement and validity positions — is \$45-65 million plus a perpetual injunction (or, alternatively, a fully-paid-up royalty bearing license for the AutoForge product). I would not recommend settling below \$40 million absent a material adverse Markman ruling.

Let's plan to revisit this after the Markman hearing. In the meantime, please brief the Board at the January meeting on the settlement framework so we are aligned when the time comes.

Talk soon,

Rachel
"@
    }
    elseif ($fname -match 'expert-timeline') {
@"
Mike —

Quick question on the expert report timeline. I'm presenting at the Board meeting in two weeks and the timing of Dr. Patel's supplemental damages report came up. Can you confirm:

  1. When is Dr. Patel's supplemental damages report due to be served on Pinnacle's counsel?
  2. When will we have a final draft for Meridian's review?
  3. When is the deadline for Pinnacle to serve their rebuttal damages report?

I want to make sure the Board has accurate dates so they can plan the financial reserves discussion appropriately.

$summary

Also, has Dr. Patel had a chance to incorporate the customer-by-customer lost-sales analysis we discussed? Catherine (our CFO) wants to walk through that with him before the report is finalized — partly to make sure we're aligned with how she'll present the lost-revenue figures internally, and partly to flag any defensive issues she sees in our underlying customer data that he should be aware of.

Sarah
"@
    }
    elseif ($fname -match 'production-response') {
@"
Rachel —

In response to your November 14 letter regarding our production schedule:

We will produce documents responsive to RFP Nos. 13-15 by November 28, 2025. The production will include the financial information referenced in your letter, subject to the "Highly Confidential — Outside Attorneys' Eyes Only" designation under the Stipulated Protective Order. We do not anticipate any further delay on this category.

For RFP Nos. 22-27 (AutoForge engineering documents), the timeline is more difficult. The volume is substantial and our review is ongoing. We expect to make a substantial production by December 31, 2025, with completion by mid-January 2026. I understand that this slips later than the schedule contemplated in your November 11 meet-and-confer letter, but the volume is greater than initially projected. Please call me at your convenience and we can discuss whether there is a way to prioritize the most relevant subset for earlier production.

For the disputed objections you raised in your November 14 letter:

  - **Supplier and customer communications:** We will produce these subject to a more limited definition than your Request appears to call for. Specifically, we will produce communications regarding the AutoForge product but not communications regarding our other product lines, even if those communications happen to mention AutoForge in passing. We believe that your Request is overbroad, and we are willing to discuss the scope before producing.

  - **Independent development materials:** We agree to produce these and they are included in the scope of the RFP Nos. 22-27 production.

  - **Financial information for periods prior to commercial launch:** We do not believe these are responsive to your Request as written. If you believe otherwise, please let me know your basis and we will reconsider.

$summary

Please let me know if the schedule above works. I am available this week and next to meet and confer if you would prefer to discuss live.

David
"@
    }
    elseif ($fname -match 'deficiency-response') {
@"
Rachel —

In response to your January 9, 2026 deficiency letter:

We disagree with several of the deficiency points you raised, and I want to address them substantively before we have an unnecessary motion practice. Some of the items in your letter relate to documents we have already produced (and identified by Bates range in our supplemental productions) but that you may not have been aware of when you wrote your letter. I'll go through them in order:

$summary

**Item 1 — AutoForge process control source code.** We produced the relevant source code in our December 31, 2025 production at PIN-CONFIDENTIAL-021482 through PIN-CONFIDENTIAL-022138. The production is in source form, with a load file identifying file paths and last-modified dates. If you cannot locate it, our paralegal Patricia Foster can resend the load file directly.

**Item 2 — Customer purchase orders for AutoForge.** Produced at PIN-CONFIDENTIAL-022139 through PIN-CONFIDENTIAL-022871. These are designated HC-AEO under the Protective Order. If you require additional metadata or clarification, let me know.

**Item 3 — Communications with technology consultants.** This is the area where we have the most substantive disagreement. We do not believe communications with our independent technology consultants who were not involved in the AutoForge product's development are responsive to your RFPs as drafted, and producing them would impose substantial burden without commensurate benefit. If you believe otherwise, please identify with specificity which RFPs you contend cover these materials, and we can discuss further.

**Item 4 — Supplemental document hold materials.** I will provide a privileged log of the hold-related materials within the next ten days. As discussed in our last meet-and-confer, the hold notice itself was produced (with limited redactions for legal advice) in our December 22 production.

**Item 5 — AutoForge customer demonstrations.** We are not aware of any responsive recordings or video. If you have specific knowledge of any such material, we will investigate. We did produce slide decks used in customer demonstrations.

I would prefer to resolve any remaining disputes by phone rather than letters. Are you available for a call Wednesday afternoon? Otherwise, please let me know what days work for you next week.

David
"@
    }
    elseif ($fname -match 'depo-scheduling') {
@"
Dear Dr. Nakamura —

Thank you for your prior availability. We are now able to confirm the following deposition date for your testimony in the above-referenced matter:

  **Date:** February 24, 2026 (Tuesday)
  **Time:** 9:00 a.m. PST (anticipated to run through 5:00 p.m., with breaks)
  **Location:** Offices of Baker & Associates LLP, 555 Market Street, Suite 2400, San Francisco, California 94105
  **Topics:** Your Initial Expert Report dated December 18, 2025 and your Rebuttal Expert Report dated February 12, 2026, including all opinions, methodology, materials reviewed, and basis for your conclusions.

The Notice of Deposition will be served on opposing counsel today and a copy is attached for your records. We will work with you on logistics — please confirm whether you require any specific A/V setup, accessibility accommodations, or other arrangements.

$summary

A few additional housekeeping items:

  1. **Document review session.** I would like to schedule a working session with you on February 19 or 20 to walk through the materials we expect plaintiff's counsel to focus on. We will plan to spend approximately 4-5 hours together. Patricia Foster from our office will follow up to coordinate.

  2. **Materials for review.** Patricia will send you the final list of materials reviewed and the cited references on February 17. Please review and confirm the list is complete; if anything is missing, we'll add it before the deposition.

  3. **Travel and lodging.** If you will be coming in from out of town, please coordinate with Patricia. Our standard practice is to book the Hyatt Regency San Francisco (across the street from our office) — please let her know your preferred check-in and check-out dates.

  4. **Compensation.** As discussed, your deposition time will be billed at your full hourly rate. You'll receive a separate engagement letter addendum confirming this.

Please confirm receipt of this email and your availability on February 24. If for any reason that date no longer works, please let me know promptly so we can coordinate with opposing counsel.

David
"@
    }
    elseif ($fname -match 'supplemental-report') {
@"
Mike —

Attached please find my Supplemental Expert Report addressing damages opinions, dated January 15, 2026. As we discussed, the supplemental report is keyed off Pinnacle's December 22 financial production and provides quantitative damages opinions across the lost-profits and reasonable-royalty theories.

Brief highlights (full report attached for review):

  - Mid-range total damages: approximately \$67.5 million (lost profits + price erosion + reasonable royalty for non-Panduit sales + pre-judgment interest)
  - Lost profits range: \$24.8M - \$38.4M depending on the assumed proportion of Pinnacle's sales that satisfy the Panduit factors
  - Price erosion: \$6.2M - \$12.8M (mid-range \$9.4M)
  - Reasonable royalty bookend: \$18.3M - \$27.2M

$summary

A few points where I'd like your input before I finalize:

  1. **Apportionment.** I have applied 88% apportionment to the patented portion of AutoForge revenue, based on the product configuration analysis I performed. If you have any additional information about the relative importance of patented vs. non-patented features in customer purchase decisions, that could refine the analysis.

  2. **Pre-judgment interest rate.** I have used the prime rate compounded annually. Some courts use a different rate (e.g., the Treasury Bill rate, or a short-term commercial rate). Please advise whether you have a preference based on the assigned judge's typical practice.

  3. **Convoyed sales.** I have included an analysis but kept it modest. If we have evidence that Pinnacle bundled AutoForge with non-patented sales of other products in a way that prevented those non-patented sales from going to Meridian, we could potentially expand the convoyed-sales analysis. Let me know if this is worth pursuing.

  4. **Royalty rate sensitivity.** The 21% mid-range rate is based on the existing TLA rate of 15% adjusted upward for the hypothetical-negotiation factors. The Federal Circuit has been somewhat skeptical of large adjustments from comparable license rates; we may want to discuss whether to dial this back to (e.g.) 18% or to provide additional support.

I'm available to discuss any of the above or any other points before we serve. Please let me know whether you want to schedule a call this week or if I should just proceed with finalization.

Best,

Robert (Dr. Patel)
"@
    }
    else {
        # Generic fallback
@"
$toNm —

$summary

$tldr

Best,

$($fromNm.Split(' ')[0])
"@
    }

@"
From: $fromNm <$from>
To: $toNm <$to>
Date: $rfcDate
Subject: $subject
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 7bit
Message-ID: <$sid@example.com>
X-Sample-Data: SAMPLE DATA - FOR DEMO PURPOSES ONLY

$body
"@
}
