---
name: define-work
description: Turns a request into a design document with no open question, delivered in a mergeable pull request, before any code is written. Use when the operator asks to build, add, change or design something whose intent, scope or constraints are not yet settled ("I want to add…", "what should we build", "help me think this through", "let's design this"), or asks to brainstorm, scope or spec a change.
---

# Define Work

This skill answers "what should we build". It ends with a design document
that has no open question, in a pull request that can merge. It does not
plan and it does not build.

## Who owns what

- **The operator defines the terms.** What the operator said, in this
  conversation or in a project file, is decided. Do not ask it again, do
  not ask the operator to confirm it, and do not redefine it. "Done" means
  what the operator or the project says it means. Without such a
  definition, done is: the design document is committed, pushed, and in a
  pull request that can merge, with its checks green and no conflict.
- **The author owns the work.** The author is the session that holds the
  conversation. When a subagent writes the text, its brief holds every
  decision, and the session that wrote the brief is still the author. A
  defect in the work is the author's failure. A review measures the
  author; it does not move the responsibility, and it is not run again in
  place of the author's own checks.
- **Mechanics are the author's.** Structure, order, internal names, how to
  test, and how to fix a finding are never questions for the operator.
- **No stop loses work.** Commit and push each artifact when it is first
  written and after each change, so that the session can end at any moment
  without loss.
- **No stop hands the work back.** Do not end a step by telling the
  operator what to type to get the next step. Do the steps the request
  includes, and stop at done.

## Adapt

An operator instruction, then the project's declared design workflow (its
template, location, review and approval steps), win over every default below.
A workflow applies only when it is written down or the operator states it.

## Procedure

1. **Size the request** and tell the operator the size; they can change it.

   | Size | Sign | Then |
   |---|---|---|
   | Clear task | Everything that matters is in the request. | Say so. Write the request as a one-line design document, which the request itself approves, and go to step 9. |
   | Small change | The intent is clear; a few choices are open. | Steps 2–6 with a short design document, then step 8. |
   | Project | Intent, scope or constraints are open, or several parts interact. | Steps 2–8, with a design document. |

   When the work outgrows its size, say so and step up. A request that holds
   several independent projects: order them by dependency and define one at
   a time. The order is the author's call.

2. **Recon.** Read the project instructions (CLAUDE.md,
   AGENTS.md, CONTRIBUTING and the documents they name), the code and docs the
   request touches, existing designs and specs, and any design or spec
   workflow the project declares. Find what the repo contains where the
   request lands, what the touched files declare, who uses the symbols the
   change touches, and, for a structural change, what else breaks if they
   change. Answer from the repo what the repo can answer; decide the rest
   by the test in step 3. A text match is not a binding: report each finding as what
   it is. Report the play-back of the system (what the code does where the
   request lands, and how the request relates to it) in the same message as
   the questions of step 3, or with the document when there are none. It is
   not a turn that waits for an answer.

3. **Decide.** Build the whole design from the request and the recon.
   Take every statement in the request as decided.

   A choice is a question for the operator only when all of these are true:

   1. The request, the conversation, the repo, a project rule and an approved
      spec do not answer it.
   2. The answer changes what the product does for its user.
   3. A wrong guess is expensive to reverse.

   Every other choice is the author's call: decide it and record it.
   Mechanics never pass this test. A design does not ask for an exception to
   a project rule; it complies.

   Send the questions that pass in one message, each with your recommendation,
   so that one word answers it. If none pass, ask none. While a question is
   open, continue all work that does not depend on it, on your recommendation.

   Ask before the document is written, not after. A question that
   appears after the document is written is a defect in the document,
   and the author closes it.

   When the recon contradicts the request, say so once, with the
   evidence and the resolution you chose. It is a question only when it
   passes the test.

4. **Keep the design the size of the request.** The design is the
   simplest one that meets the stated purpose. Each mechanism the
   request did not ask for names the failure it prevents and what it
   costs. Drop it when the simplest safe behavior (refuse, report, do
   nothing) is enough. Do not remove a behavior the operator asked for
   to make the design smaller.

5. **Alternatives.** Weigh the approaches and drop any that conflicts with
   the stated purpose. Keep each dropped or rejected approach with its
   reason for the document (step 6). Show two or three, with your
   recommendation, only when the choice passes the test in step 3.

6. **Design document.** Write it where the project keeps designs, else at
   `docs/specs/YYYY-MM-DD-<topic>-design.md`. The project's template wins;
   otherwise cover:
   - intent: the problem, and why it matters now
   - goals and non-goals
   - constraints
   - the decided parts of the approach, each marked as the operator's or the
     author's call, with a text diagram where several parts interact
   - alternatives considered and rejected, each with its reason, so that a
     later session does not propose them again
   - the files the change is expected to create or change, from the recon,
     with one line each on why
   - what is left to the builder
   - acceptance: what "done" means, as checks a test or a command can decide

   A small change's document is short: intent, the description, and
   acceptance. Cite the recon evidence (file:line) for each claim about
   existing code. Match the length to the substance; no filler sections.

   The document states behavior, interfaces, state and acceptance. It
   leaves to the builder what a builder can decide.

   Before the document is finished, the author does all of these, and
   does not leave them to a reviewer:
   - opens every file and symbol the document cites and confirms each
     claim;
   - walks each flow from start to end: the normal path, a failure
     partway, two actors at the same time, and every other entry point to
     the same behavior;
   - names the one owner of each piece of state and checks that every
     reader agrees;
   - checks hostile, malformed and large input at each boundary the
     design adds;
   - checks the design against the project's rules and approved specs,
     and complies;
   - reads the document as a builder who cannot ask: each place where the
     builder must guess is a gap, and the author closes it.

   The finished document has no open question and no "not resolved" list.
   Commit and push it on a work branch when it is first written and after
   each change.

7. **One audit.** For a project, one fresh reviewer that has not seen
   this conversation, on a capable model, reads the document at
   `<path>` and the files it cites, one time. Brief: you must plan and
   build from this document and cannot ask its author; report where
   the design fails and where a builder would guess wrong, each with
   its evidence from the code, most important first; skip what a
   builder can decide; if nothing important is left, say so.
   - Verify each finding against the repo and the conversation. Fix a
     confirmed finding. Record a refuted finding with its reason and
     drop it.
   - A fix follows step 4: it adds no mechanism when a simpler behavior
     closes the finding, and it removes no behavior the operator asked
     for.
   - A finding goes to the operator only when it passes the test in
     step 3.
   - A critical finding, or several findings of one kind, shows which
     duty of step 6 the author skipped. Do that duty again over the
     whole document.

   The audit does not run a second time.

8. **Deliver.** Record `**Status:** proposed <YYYY-MM-DD>` in the
   document header. Open a pull request for the work branch and make
   it mergeable: checks green, no conflict. Fix a failed check
   yourself. Give the operator the pull request link and the author's
   calls that change what the operator gets; for a small change, also
   show its text in chat.

   Nothing is built before the operator approves the design. Building
   is product code, scaffolding, dependency installs or project
   creation; reading and recon are not. The operator's word, or their
   merge of the pull request, is the approval, and it covers only the
   text the operator saw. An explicit instruction to build without
   review ("just build it", "no need to approve") is the approval.
   Record it in the header: `**Status:** approved by <who>
   <YYYY-MM-DD>`. A spike the operator agrees to is labeled throwaway;
   keeping any of it needs a new approval.

9. **Hand over.** The approved document is the authority spec for
   planning. Planning follows the operator's instruction, else the
   project's planning workflow. When the request includes planning or
   building, go on without asking.

## Report

The design document is the report. Each claim about existing code cites its
evidence. Each check that did not run is named in the document as not run,
with its reason. The report gives the pull request link and the state of
its checks.
