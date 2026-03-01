# EXPERT REPORT OF DR. ROBERT PATEL, Ph.D., P.E.

## Meridian Corporation v. Pinnacle Industries, Inc.
## Case No. 3:25-cv-04821-MLS (N.D. Cal.)

---

**Prepared for:** Baker & Associates LLP, counsel for Plaintiff Meridian Corporation
**Date:** January 10, 2026
**Report Version:** Final

---

## I. QUALIFICATIONS

1. My name is Dr. Robert Patel. I am a Professor of Mechanical Engineering and Materials Science at Stanford University, where I have been a faculty member since 2008. I hold a Ph.D. in Materials Science and Engineering from the Massachusetts Institute of Technology (2004), an M.S. in Mechanical Engineering from the University of Michigan (2000), and a B.S. in Mechanical Engineering from the University of California, Berkeley (1998).

2. I am a registered Professional Engineer (P.E.) in the State of California (License No. ME-78432). I am a Fellow of the American Society of Mechanical Engineers (ASME) and a member of the Society for the Advancement of Material and Process Engineering (SAMPE).

3. My research focuses on advanced composite material processing, with particular expertise in thermal compression molding, autoclave processing, and out-of-autoclave manufacturing techniques. I have published over 85 peer-reviewed journal articles and 40 conference papers in these areas. I have been awarded 6 U.S. patents related to composite processing technology.

4. I have served as an expert witness in 12 prior patent infringement cases involving manufacturing process patents, composite materials, and thermal processing technology. A complete list of my publications, patents, and prior testimony is provided in Exhibit 1 to this report.

5. I am being compensated at a rate of $650 per hour for my work on this case. My compensation is not contingent on the outcome of this litigation.

---

## II. SCOPE OF ENGAGEMENT AND MATERIALS REVIEWED

6. I have been retained by Baker & Associates LLP on behalf of Meridian Corporation to provide expert opinions on whether Pinnacle Industries' AutoForge Multi-Stage Compression Platform ("AutoForge System") infringes Claims 1 through 14 of U.S. Patent No. 9,876,543 ("the '543 Patent").

7. In forming my opinions, I have reviewed the following materials:

   a. U.S. Patent No. 9,876,543 and its complete prosecution history;
   b. The Technology License Agreement between Meridian and Pinnacle (TLA-2023-0032);
   c. The Technical Package delivered to Pinnacle under the TLA;
   d. Pinnacle's AutoForge Platform Architecture Specification v2.1 (PIN-00004521-4578);
   e. Pinnacle's AutoForge Operational Manual (PIN-00006234-6312);
   f. Pinnacle's AutoForge marketing materials and customer presentations (PIN-00001001-1089);
   g. Deposition transcripts of Dr. Thomas Brennan and Lisa Monroe;
   h. This Court's Claim Construction Order (Dkt. No. 89);
   i. Photographs and video recordings of the AutoForge System in operation at Pinnacle's Fremont facility;
   j. Relevant prior art references identified by both parties;
   k. Technical literature on thermal compression molding processes.

8. A complete list of materials reviewed is provided in Exhibit 2.

---

## III. SUMMARY OF OPINIONS

9. Based on my review and analysis, I have formed the following opinions to a reasonable degree of scientific certainty:

   **Opinion 1:** The AutoForge System literally infringes Claims 1 through 14 of the '543 Patent. Each element of each asserted claim is present in the AutoForge System.

   **Opinion 2:** The AutoForge System's thermal management subsystem creates and maintains a "thermal compression boundary layer" as that term is construed by this Court.

   **Opinion 3:** The AutoForge System's sequential compression process constitutes "multi-stage compression molding" as that term is construed by this Court.

   **Opinion 4:** The AutoForge System was designed using knowledge obtained from Meridian's Technical Package, as evidenced by the substantial technical overlap between the AutoForge architecture and the specifications in the Technical Package.

---

## IV. TECHNICAL BACKGROUND

### A. Thermal Compression Molding

10. Thermal compression molding is a manufacturing process used to shape composite materials — materials composed of a reinforcing fiber (such as carbon fiber or glass fiber) embedded in a polymer matrix (such as epoxy or thermoplastic resin). The process involves applying heat and pressure to a composite preform to consolidate the material into a desired shape.

11. In conventional thermal compression molding, the composite preform is placed in a heated mold, and a press applies compression force to the mold. Heat is typically applied uniformly across the mold surface, and the compression force is applied in a single stage. This approach has known limitations, including: (a) difficulty controlling resin flow in complex geometries; (b) potential for fiber misalignment during compression; (c) residual stress development due to non-uniform cooling; and (d) void formation due to trapped air or volatile gases.

### B. The '543 Patent Innovation

12. The '543 Patent addresses these limitations through two key innovations: (1) a multi-stage compression approach that applies compression in discrete, independently controllable stages; and (2) thermal compression boundary layer management, which precisely controls the thermal conditions at the tooling-workpiece interface during each compression stage.

13. The thermal compression boundary layer, as I understand the Court's construction, is "the thermally managed zone at the interface between the compression tooling and the composite workpiece, where controlled heat transfer and pressure distribution occur during compression." This is a process zone — a region where thermal and mechanical conditions are actively managed to optimize material behavior during compression.

14. The multi-stage approach, as construed by the Court, is "a compression process comprising two or more discrete compression stages applied sequentially to the workpiece, each stage having independently controllable parameters." This allows different thermal and mechanical conditions to be applied at different points in the compression cycle, optimizing the material consolidation process.

---

## V. ANALYSIS OF THE AUTOFORGE SYSTEM

### A. System Architecture Overview

15. Based on my review of the AutoForge Platform Architecture Specification v2.1 and operational documentation, the AutoForge System comprises the following major subsystems:

   a. **Multi-Stage Press Assembly:** A hydraulic compression press with independently controlled upper and lower platens, capable of applying sequential compression forces through programmable stage profiles.

   b. **Thermal Zone Management Module (TZMM):** An integrated heating and cooling system that establishes and maintains controlled thermal zones at the tooling-workpiece interface. The TZMM includes embedded heating elements, cooling channels, and thermal interface materials.

   c. **Integrated Process Control Unit (IPCU):** A computerized control system that independently regulates temperature profiles, compression forces, compression velocities, and dwell times for each compression stage.

   d. **Integrated Sensor Network (ISN):** An array of thermocouples, pressure transducers, and capacitive proximity sensors distributed across the tooling-workpiece interface that provides real-time monitoring and feedback to the IPCU.

   e. **Material Flow Optimization Engine (MFOE):** A software module within the IPCU that dynamically adjusts boundary zone parameters during stage transitions to optimize resin flow and fiber consolidation.

### B. Element-by-Element Comparison: Claim 1

16. Claim 1 of the '543 Patent recites:

> "A thermal compression molding system for processing composite materials, comprising:
> a multi-stage compression assembly configured to apply sequential compression forces to a composite material workpiece;
> a thermal management subsystem configured to establish and maintain a thermal compression boundary layer at the interface between the compression assembly and the workpiece during each compression stage;
> a control system configured to independently regulate the temperature profile and compression force during each stage of the multi-stage compression process;
> wherein the thermal compression boundary layer is dynamically adjusted during transitions between compression stages to optimize material flow and consolidation."

17. I address each element below.

#### Element 1(a): Multi-stage compression assembly

18. The AutoForge System includes a Multi-Stage Press Assembly that applies compression forces sequentially through programmable stage profiles. The Architecture Specification states: "The press assembly executes sequential multi-stage compression cycles with independently controlled stage parameters." (PIN-00004535, Section 3.2.)

19. Dr. Brennan confirmed at deposition that the AutoForge System applies "compression in multiple sequential stages" and that "each stage can be independently programmed with different force levels, rates, and durations." (Brennan Dep. 87:14-88:3.)

20. The AutoForge operational manual describes a standard three-stage compression profile: Stage 1 (initial consolidation), Stage 2 (primary compression), and Stage 3 (finishing/cooling). (PIN-00006258, Section 5.1.)

21. This element is satisfied.

#### Element 1(b): Thermal management subsystem / thermal compression boundary layer

22. The AutoForge System's Thermal Zone Management Module (TZMM) establishes and maintains controlled thermal zones at the tooling-workpiece interface during each compression stage.

23. The Architecture Specification describes the TZMM as follows: "The TZMM creates and maintains controlled thermal zones at the tooling-workpiece interface through a combination of embedded resistive heating elements, conformal cooling channels, and thermal interface materials." (PIN-00004541, Section 3.4.)

24. The specification further describes the TZMM's function: "During each compression stage, the TZMM maintains precise temperature gradients within the boundary zone, enabling controlled heat transfer from the tooling to the workpiece surface. The boundary zone is the region where active thermal management occurs — typically extending 2-5mm from the tooling surface into the workpiece." (PIN-00004543, Section 3.4.2.)

25. This description maps directly onto the Court's construction of "thermal compression boundary layer" — it describes a thermally managed zone at the interface where controlled heat transfer and pressure distribution occur during compression.

26. Dr. Brennan testified that the TZMM "creates a thermally managed zone at the interface" and that "we actively control the thermal conditions in that zone during each compression stage." (Brennan Dep. 94:7-15.)

27. This element is satisfied.

#### Element 1(c): Control system for independent stage regulation

28. The AutoForge System's Integrated Process Control Unit (IPCU) independently regulates temperature profiles and compression forces during each stage.

29. The Architecture Specification states: "The IPCU provides independent parametric control of temperature ramp rates, dwell temperatures, compression force magnitude, and compression velocity for each compression stage. Each stage is defined by a discrete parameter set that is independently configurable." (PIN-00004548, Section 3.6.)

30. This element is satisfied.

#### Element 1(d): Dynamic boundary layer adjustment during stage transitions

31. The AutoForge System dynamically adjusts the thermal compression boundary layer during transitions between compression stages through its Material Flow Optimization Engine (MFOE).

32. The Architecture Specification states: "During stage transitions, boundary zone parameters are continuously adjusted by the MFOE to ensure optimal resin flow and fiber consolidation. The MFOE adjusts temperature gradient profiles, heating element power distribution, and cooling channel flow rates in real time during transitions." (PIN-00004552, Section 3.8.)

33. This directly satisfies the claim requirement that "the thermal compression boundary layer is dynamically adjusted during transitions between compression stages to optimize material flow and consolidation."

34. This element is satisfied.

35. **Conclusion on Claim 1:** The AutoForge System literally satisfies each and every element of Claim 1 of the '543 Patent.

### C. Claim 3 Analysis

36. Claim 3 depends from Claim 1 and adds: "a sensor array configured to monitor thermal compression boundary layer characteristics in real time and provide feedback to the control system for dynamic adjustment."

37. The AutoForge System's Integrated Sensor Network (ISN) includes thermocouple arrays, pressure transducers, and capacitive proximity sensors that monitor boundary zone characteristics in real time and provide feedback to the IPCU. (PIN-00004555, Section 4.2.)

38. This additional element is satisfied. The AutoForge System literally infringes Claim 3.

### D. Claim 7 Analysis

39. Claim 7 is an independent method claim reciting a three-step process. The AutoForge System's standard operating procedure (PIN-00006258, Section 5) describes executing each of these steps:

40. **Step 1** (establishing boundary layer at first temperature and force): The AutoForge Stage 1 Initialization procedure establishes thermal zones at target temperature T1 and applies compression force F1.

41. **Step 2** (transitioning to second stage by adjusting boundary layer): The AutoForge Stage Transition procedure adjusts thermal zone parameters to Stage 2 targets with controlled ramp rates.

42. **Step 3** (controlling transition rate for continuous material flow): The AutoForge Transition Rate Control module manages transition rates to ensure continuous and uniform material flow.

43. **Conclusion on Claim 7:** The AutoForge System literally practices each step of Claim 7.

### E. Claims 2, 4-6, 8-14

44. I have performed the same element-by-element analysis for Claims 2, 4-6, and 8-14. The detailed analysis is provided in Exhibit 3 (Claim Charts). In summary, each dependent and independent claim is literally satisfied by the AutoForge System.

---

## VI. COMPARISON TO MERIDIAN TECHNICAL PACKAGE

45. I compared the AutoForge Architecture Specification to the Technical Package that Meridian delivered to Pinnacle under the TLA. The architectural similarities are striking:

46. The AutoForge TZMM closely mirrors the thermal management system described in Meridian's Process Specification Document PS-TCM-2023-001. Both use embedded resistive heating elements with conformal cooling channels and thermal interface materials in nearly identical configurations.

47. The AutoForge IPCU control architecture shares significant structural similarity with the control system described in Meridian's Equipment Configuration Guide ECG-TCM-2023-001, including similar parameter hierarchies, stage definition formats, and feedback loop architectures.

48. The AutoForge MFOE's optimization algorithms for stage transitions appear to implement the same mathematical models described in Meridian's Quality Control Protocol QCP-TCM-2023-001, adapted for the AutoForge hardware platform.

49. These similarities are consistent with the AutoForge System having been developed using knowledge obtained from Meridian's Technical Package.

---

## VII. CONCLUSIONS

50. Based on my analysis, I conclude to a reasonable degree of scientific certainty that:

   a. Pinnacle's AutoForge Multi-Stage Compression Platform literally infringes Claims 1 through 14 of U.S. Patent No. 9,876,543.

   b. The AutoForge System's Thermal Zone Management Module creates and maintains a thermal compression boundary layer as that term has been construed by this Court.

   c. The AutoForge System practices multi-stage compression molding as that term has been construed by this Court.

   d. The architectural similarities between the AutoForge System and Meridian's Technical Package are consistent with the AutoForge System having been developed using knowledge obtained from the Technical Package.

51. I reserve the right to supplement this report as additional discovery materials become available, including any supplemental technical documents produced by Pinnacle.

---

Respectfully submitted,

Dr. Robert Patel, Ph.D., P.E.
Professor of Mechanical Engineering and Materials Science
Stanford University

Date: January 10, 2026

---

*Exhibits referenced herein (Curriculum Vitae, Materials Reviewed, Claim Charts) are provided under separate cover.*
