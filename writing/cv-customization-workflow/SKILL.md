---
name: cv-customization-workflow
description: "Operational workflow for producing role-specific CV variants and cover letters from a generic base. Covers requirements mapping, honest gap analysis, adversarial review, de-AI voice pass, and two-agent cover letter quality gates. Trigger keywords: CV, resume, cover letter, customize, job posting, tailor, skills match, red-team CV, gap bridging, scale numbers, quantify experience."
metadata:
  version: 1.0.0
---

# CV Customization Workflow

Repeatable workflow for producing role-specific CV variants and cover letters from a generic base.

## Steps

### Step 1: Skills Match Assessment
Read generic base CV and posting. Search work logs for unsurfaced experience.

| Requirement | Match Level | Evidence |
|---|---|---|
| [Requirement] | Strong / Growth / Gap | [Specific experience] |

**Scoring**: (Strong + 0.5 x Growth) / Total requirements.

### Step 2: Create Role-Specific CV
**File**: `YYYYMMDD <Name> CV - [Company] [Role].md`

- Reframe through role's lens — same experience, different emphasis. Use posting's language where honest.
- Restructure for signal — reorder skills categories, split subsections, trim noise for this role.
- Surface hidden experience — search work logs, journals, project docs. Ask user about undocumented experience.
- Never fabricate tools/platforms not used, upgrade Growth to Strong, list adjacent skills as primary, or change job titles.

After writing: red-team via reality-checker agent (hiring manager perspective), then de-AI voice pass via de-ai-voice-editing skill. Fix issues directly.

### Step 3: Cover Letter (when gaps can't be closed by reframing)
**File**: `YYYYMMDD <Name> Cover Letter - [Company] [Role].md`

**Structure (3-4 paragraphs, under 400 words)**:
1. **Opening**: Mirror one key phrase, pivot to value proposition. No throat-clearing.
2. **Strongest match**: Single most relevant experience, verifiable against CV.
3. **Gap acknowledgment**: Name gaps explicitly. Bridge with protocol-level parallels, not "transferable skills." Meta-reframe: "Every system I described, I built without prior experience in the specific tools."
4. **Closing**: Forward hook naming specific work you'd tackle. No boilerplate.

**Two-Agent Quality Gate**: (1) De-AI voice agent, (2) Red-team agent as hiring manager screening 50 applications. Must contain at least one company-specific sentence.
